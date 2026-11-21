-- Automated Functional Tests for Korg Z1 Base:
-- Handshake, Current Program Dump Request, Program Name Parsing, Patch Backup/Recovery & Snapshot Undo/Redo

local function assertBytes(msg, expected)
    test.eq(msg.type, SYSEX, "expected SysEx message")
    test.count(msg.data, #expected, "SysEx byte length")
    for i = 1, #expected do
        test.eq(msg.data[i], expected[i], string.format("byte %d", i))
    end
end

test.case("Handshake is sent automatically on load, retries every 5s while disconnected, and parses Z1 Identity Reply", function()
    -- 1. Before connection, timer retries Device Inquiry every 5 seconds (not on ticks 1..4)
    z1Status.connected = false
    handshakeRetrySeconds = 0
    test.clear()
    for _ = 1, 4 do
        timer.onTick()
    end
    test.none(test.sent(), "no retry before 5 seconds")
    timer.onTick() -- 5th second -> sends automatic retry
    test.count(test.sent(), 1)
    assertBytes(test.sent()[1], { 0xF0, 0x7E, 0x00, 0x06, 0x01, 0xF7 })

    -- 2. Manual Handshake button also sends Universal Device Inquiry
    test.clear()
    test.turn(1, 1)

    local sent = test.sent()
    test.count(sent, 1)
    assertBytes(sent[1], { 0xF0, 0x7E, 0x00, 0x06, 0x01, 0xF7 })

    -- Simulate hardware Z1 Device Inquiry reply on Global Channel 3 (0g = 0x02) -> subsequent edits use 0x32
    parseSysexMessage({
        0xF0, 0x7E, 0x02, 0x06, 0x02,
        0x42, 0x46, 0x00, 0x01, 0x00,
        0x02, 0x00, 0x01, 0x00, 0xF7,
    })
    test.eq(z1Status.connected, true)
    test.eq(z1Status.channel, 3)

    -- 3. Once connected, 5 seconds of timer ticks do NOT send any further handshake retries
    test.clear()
    for _ = 1, 10 do
        timer.onTick()
    end
    test.none(test.sent(), "connected Z1 must stop 5s handshake retries")

    test.clear()
    test.turn(2, 1)
    assertBytes(test.sent()[1], { 0xF0, 0x42, 0x32, 0x46, 0x10, 0x00, 0xF7 })

    -- Restore Global Channel 1 (0g = 0x00) for remaining tests
    local ok, kind = parseSysexMessage({
        0xF0, 0x7E, 0x00, 0x06, 0x02,
        0x42, 0x46, 0x00, 0x01, 0x00,
        0x02, 0x00, 0x01, 0x00, 0xF7,
    })
    test.eq(ok, true)
    test.eq(kind, "inquiry")
    test.eq(z1Status.connected, true)
    test.eq(z1Status.channel, 1)
    test.eq(z1Status.familyId, 0x46)
    test.eq(z1Status.version, "v1.02")
end)

test.case("Patch Request button & optional automatic Patch Request on MIDI Program Change (10H)", function()
    test.clear()
    test.turn(2, 1)

    local sent = test.sent()
    test.count(sent, 1)
    assertBytes(sent[1], { 0xF0, 0x42, 0x30, 0x46, 0x10, 0x00, 0xF7 })
    test.eq(type(patchBackup), "table", "patchBackup created before request")

    -- When PC Patch Req (Control 27) is ON (default), incoming Program Change requests 40H dump
    test.clear()
    midi.onProgramChange(nil, 1, 5)
    test.count(test.sent(), 1)
    assertBytes(test.sent()[1], { 0xF0, 0x42, 0x30, 0x46, 0x10, 0x00, 0xF7 })

    -- When PC Patch Req (Control 27) is toggled OFF, incoming Program Change does not request 40H dump
    test.turn(27, 0)
    test.eq(autoPatchReqOnPc, false)
    test.clear()
    midi.onProgramChange(nil, 1, 6)
    test.none(test.sent(), "PC Patch Req OFF must suppress automatic 10H dump request")

    -- Re-enable PC Patch Req
    test.turn(27, 1)
    test.eq(autoPatchReqOnPc, true)
end)

test.case("Parses 16-byte Program Name directly after 40H header AND from Korg 7-to-8-bit packed 40H dump", function()
    test.clear()

    -- 1. Test raw 16 ASCII bytes immediately after F0 42 30 46 40 01 header ("Z1 Raw16 Test   ")
    local rawDump = {
        0xF0, 0x42, 0x30, 0x46, 0x40, 0x01,
        0x5A, 0x31, 0x20, 0x52, 0x61, 0x77, 0x31, 0x36,
        0x20, 0x54, 0x65, 0x73, 0x74, 0x20, 0x20, 0x20,
        0xF7,
    }
    local okRaw, kindRaw = parseSysexMessage(rawDump)
    test.eq(okRaw, true)
    test.eq(kindRaw, "program_dump")
    test.eq(getProgramNameString(), "Z1 Raw16 Test   ")
    test.none(test.sent(), "parsing dump must not echo SysEx back to Z1")

    -- 2. Test Korg 7-to-8-bit packed 40H dump ("MOSS Brass Lead ")
    local packedDump = {
        0xF0, 0x42, 0x30, 0x46, 0x40, 0x01,
        0x00, 0x4D, 0x4F, 0x53, 0x53, 0x20, 0x42, 0x72,
        0x00, 0x61, 0x73, 0x73, 0x20, 0x4C, 0x65, 0x61,
        0x00, 0x64, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00,
        0xF7,
    }
    local okPacked, kindPacked = parseSysexMessage(packedDump)
    test.eq(okPacked, true)
    test.eq(kindPacked, "program_dump")
    test.eq(getProgramNameString(), "MOSS Brass Lead ")
    test.none(test.sent())
end)

test.case("Recover Backup button restores patch wiped out by a 40H dump and transmits it back to Z1", function()
    -- Start with a full 576-byte unpacked patch ("My Custom Patch ")
    local fullUnpacked = {}
    local customName = "My Custom Patch "
    for i = 1, 576 do
        if i <= 16 then
            fullUnpacked[i] = string.byte(customName, i)
        else
            fullUnpacked[i] = (i * 3) & 0xFF
        end
    end
    local customDumpBody = buildCurrentProgramDumpBody(fullUnpacked, 0)
    local customSysex = { 0xF0 }
    for i = 1, #customDumpBody do
        customSysex[#customSysex + 1] = customDumpBody[i]
    end
    customSysex[#customSysex + 1] = 0xF7
    test.eq(#customSysex, 666, "full 40H dump is 666 bytes")

    parseSysexMessage(customSysex)
    test.eq(getProgramNameString(), "My Custom Patch ")

    -- Now request a patch dump (Control 2) and simulate an incoming 40H dump that wipes out our patch
    test.turn(2, 1)
    local wipeDump = {
        0xF0, 0x42, 0x30, 0x46, 0x40, 0x01,
        0x57, 0x69, 0x70, 0x65, 0x64, 0x20, 0x50, 0x61,
        0x74, 0x63, 0x68, 0x21, 0x20, 0x20, 0x20, 0x20,
        0xF7,
    }
    parseSysexMessage(wipeDump)
    test.eq(getProgramNameString(), "Wiped Patch!    ")

    -- Press Recover Backup (Control 4) -> restores "My Custom Patch " and sends the 666-byte 40H dump back to Z1
    test.clear()
    test.turn(4, 1)
    test.eq(getProgramNameString(), "My Custom Patch ")
    local sent = test.sent()
    test.count(sent, 1)
    assertBytes(sent[1], customSysex)
end)

test.case("Patch Name edits do not push to Undo, while synth parameter changes support Undo and Redo", function()
    -- Reset undo stack with current patch ("My Custom Patch ")
    undoStack = {}
    undoCursor = 0
    paramValues = {}
    currentUnpackedProgram = nil
    pushUndoState("Base")
    test.eq(getProgramNameString(), "My Custom Patch ")
    test.eq(#undoStack, 1)

    -- 1. Edit Patch Name Pos 1 -> 'A' (65): sends 41H for ID 1, but does NOT push to undoStack
    test.turn(33, 1)
    test.clear()
    test.turn(34, 65)
    test.eq(getProgramNameString(), "Ay Custom Patch ")
    local sentName = test.sent()
    test.count(sentName, 1)
    assertBytes(sentName[1], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x01, 0x00, 0x41, 0x00, 0xF7 })
    test.eq(#undoStack, 1, "patch name edits must not push to undoStack")

    -- 2. User changes Filter 1 Cutoff (ExID 0, ID 263 = 0x0107) through 50 -> 60 -> 80 (coalesced)
    paramValues[263] = 40
    sendParamChange(0, 263, 50)
    for _ = 1, 14 do
        timer.onTick()
    end
    test.eq(undoPendingSnapshot, true, "still pending before 15s idle timeout")
    test.eq(undoStack[undoCursor].sealed, false)

    -- Turning ID 263 again before 15s resets the 15s idle timer and coalesces into the same Undo step
    sendParamChange(0, 263, 60)
    test.eq(undoIdleSeconds, 0, "activity resets idle timer to 0s")
    test.clear()
    sendParamChange(0, 263, 80)
    test.eq(#undoStack, 2, "consecutive turns of ID 263 coalesce into 1 Undo step")
    test.eq(paramValues[263], 80)

    -- Simulate 15 seconds of no user activity -> seals the Undo step & flushes snapshot
    for _ = 1, 15 do
        timer.onTick()
    end
    test.eq(undoPendingSnapshot, false, "flushed after 15s idle timeout")
    test.eq(undoStack[undoCursor].sealed, true, "Undo step sealed after 15s idle")

    -- 3. User changes Filter 1 Resonance (ExID 0, ID 274 = 0x0112) from 10 -> 75
    paramValues[274] = 10
    sendParamChange(0, 274, 75)
    test.eq(#undoStack, 3)
    test.eq(paramValues[274], 75)

    -- 4. Press Undo (Control 5) -> reverts Filter 1 Resonance (ID 274) back to 10
    test.clear()
    test.turn(5, 1)
    test.eq(paramValues[274], 10)
    local sentUndo1 = test.sent()
    test.count(sentUndo1, 1)
    assertBytes(sentUndo1[1], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x12, 0x02, 10, 0x00, 0xF7 })

    -- 5. Press Undo (Control 5) again -> reverts Filter 1 Cutoff (ID 263) back to 40
    test.clear()
    test.turn(5, 1)
    test.eq(paramValues[263], 40)
    local sentUndo2 = test.sent()
    test.count(sentUndo2, 1)
    assertBytes(sentUndo2[1], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x07, 0x02, 40, 0x00, 0xF7 })

    -- 6. Press Redo (Control 6) -> advances Filter 1 Cutoff (ID 263) to 80
    test.clear()
    test.turn(6, 1)
    test.eq(paramValues[263], 80)
    local sentRedo1 = test.sent()
    test.count(sentRedo1, 1)
    assertBytes(sentRedo1[1], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x07, 0x02, 80, 0x00, 0xF7 })

    -- 7. Press Redo (Control 6) again -> advances Filter 1 Resonance (ID 274) to 75
    test.clear()
    test.turn(6, 1)
    test.eq(paramValues[274], 75)
    local sentRedo2 = test.sent()
    test.count(sentRedo2, 1)
    assertBytes(sentRedo2[1], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x12, 0x02, 75, 0x00, 0xF7 })
end)

test.case("Tuning Keyboard, Global Tuning Request/Send (0EH/51H/41H Group 00) & Named Tuning Presets", function()
    currentUnpackedGlobal = nil
    test.turn(10, 0) -- User Scale 1 (12-Note)
    test.turn(19, 1) -- Reset Scale
    test.clear()

    -- 1. Request Global Tuning Dump (Control 8 -> F0 42 30 46 0E 00 F7)
    test.turn(8, 1)
    test.count(test.sent(), 1)
    assertBytes(test.sent()[1], { 0xF0, 0x42, 0x30, 0x46, 0x0E, 0x00, 0xF7 })

    -- 2. Select Key C# (index 1, Control 12) and tune to -15 cents (Control 13)
    -- User Scale 1 C# = Global Param ID 277 (277 = 2*128 + 21 -> pl=0x15, pm=0x02), -15 = 0x3FF1 -> vl=0x71, vm=0x7F
    test.clear()
    test.turn(12, 1)
    test.turn(13, -15)
    test.eq(userScale1[1], -15)
    test.count(test.sent(), 1)
    assertBytes(test.sent()[1], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x00, 0x15, 0x02, 0x71, 0x7F, 0xF7 })

    -- 3. Open Tune Preset submenu (Control 14), select Slot 2 (Control 25), name, Save (Control 16),
    --    Rename (Control 22), Reset (Control 19), Load (Control 15), and 2-press Delete (Control 23)
    test.eq(controls.get(11):isVisible(), false, "Scale Octave hidden for User Scale 1 (1-octave repeated)")
    test.turn(10, 1)
    test.eq(controls.get(11):isVisible(), true, "Scale Octave shown for User Scale 2 (128-key)")
    test.turn(10, 0)

    test.turn(14, 1)  -- Open Tune Preset submenu
    test.eq(tunePresetView, true)
    test.eq(controls.get(20):isVisible(), false, "Tuning Keyboard hidden while submenu is open")
    test.eq(controls.get(21):isVisible(), true, "Preset List visible in submenu")

    test.turn(25, 2)  -- Slot 2
    test.turn(17, 1)  -- Name Pos 1
    test.turn(18, 74) -- 'J'
    test.turn(16, 1)  -- Save Tuning Preset 2
    test.eq(z1PersistLib.tuning["s2"].name, "Juning 02")

    test.turn(17, 2)  -- Name Pos 2
    test.turn(18, 73) -- 'I'
    test.turn(22, 1)  -- Rename Tuning Preset 2
    test.eq(z1PersistLib.tuning["s2"].name, "JIning 02")

    test.turn(19, 1)  -- Reset User Scale 1 to 0 cents
    test.eq(userScale1[1], 0)

    test.clear()
    test.turn(15, 1)  -- Load Tuning Preset 2 -> restores userScale1[1] = -15 and sends 12 notes of User Scale 1
    test.eq(userScale1[1], -15)
    test.count(test.sent(), 12)
    assertBytes(test.sent()[2], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x00, 0x15, 0x02, 0x71, 0x7F, 0xF7 })

    -- Two-press Delete on Slot 2
    test.turn(23, 1)
    test.eq(type(z1PersistLib.tuning["s2"]), "table", "first Delete press only arms confirmation")
    test.turn(23, 1)
    test.eq(z1PersistLib.tuning["s2"], nil, "second Delete press clears slot 2")

    test.turn(14, 0)  -- Close Tune Preset submenu
    test.eq(tunePresetView, false)
    test.eq(controls.get(20):isVisible(), true, "Tuning Keyboard visible again")

    -- 4. Incoming 416-byte 51H Global Dump populates User Scale 1 (bytes 266..277) & User Scale 2 (bytes 278..405)
    local rawGlobal = {}
    for i = 1, 416 do rawGlobal[i] = 0 end
    rawGlobal[266 + 0] = 12             -- User Scale 1 C = +12 cents
    rawGlobal[278 + 60] = (-25) & 0xFF  -- User Scale 2 C4 (MIDI 60) = -25 cents
    local dumpBody = buildGlobalDataDumpBody(rawGlobal, 0)
    local dumpSysex = { 0xF0 }
    for i = 1, #dumpBody do dumpSysex[#dumpSysex + 1] = dumpBody[i] end
    dumpSysex[#dumpSysex + 1] = 0xF7

    test.clear()
    local okG, kindG = parseSysexMessage(dumpSysex)
    test.eq(okG, true)
    test.eq(kindG, "global_dump")
    test.eq(userScale1[0], 12)
    test.eq(userScale2[60], -25)
    test.none(test.sent())

    -- 5. Pressing Send Tuning (Control 9) when a 416-byte Global Dump is present transmits the 51H Global Dump
    test.turn(9, 1)
    test.count(test.sent(), 1)
    assertBytes(test.sent()[1], dumpSysex)
end)
