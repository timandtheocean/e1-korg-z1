-- Korg Z1 OSC1 Preset Tests (Electra One firmware 5.0+)

local function assertSysex(msg, expected)
    test.eq(msg.type, SYSEX, "expected a SysEx message")
    test.count(msg.data, #expected, "SysEx byte length")
    for i = 1, #expected do
        test.eq(msg.data[i], expected[i], string.format("byte %d", i))
    end
end

test.case("OSC1 Type selector sends param 174 (ExID 0) and relayouts Comb Filter", function()
    test.turn(1, 1) -- Comb Filter (value 1)

    local sent = test.sent()
    test.count(sent, 1)
    assertSysex(sent[1], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x2E, 0x01, 0x01, 0x00, 0xF7 })

    -- Comb Filter has 14 params (slots 2..15 active, slots 16..36 parked)
    test.eq(controls.get(202):isVisible(), true, "slot 2 (Input Sel list) visible")
    test.eq(controls.get(202):getName(), "Input Sel")
    test.eq(controls.get(115):isVisible(), true, "slot 15 (HiDamp Int fader) visible")
    test.eq(controls.get(116):isVisible(), false, "slot 16 fader hidden")
    test.eq(controls.get(216):isVisible(), false, "slot 16 list hidden")
end)

test.case("Standard OSC Wave (464), LFO enum (471), ModSrc1 (473) and negative ModInt (474)", function()
    test.turn(1, 0) -- Standard OSC
    test.clear()

    -- Slot 2 = 464 Wave (list 202): index 1 = PULSE (value 1)
    test.turn(202, 1)
    -- Slot 9 = 471 WF Mod LFO (list 209): index 2 = LFO3 (Z1 value 8, non-zero-based!)
    test.turn(209, 2)
    -- Slot 11 = 473 WF Mod Src (list 211): index 20 = Mod Wheel(CC#1) (value 20)
    test.turn(211, 20)
    -- Slot 12 = 474 WF Mod Int (fader 112): display -50 -> 14-bit two's complement 0x3FCE (4E 7F)
    test.turn(112, -50)

    local sent = test.sent()
    test.count(sent, 4)
    assertSysex(sent[1], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x50, 0x13, 0x01, 0x00, 0xF7 })
    assertSysex(sent[2], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x57, 0x13, 0x08, 0x00, 0xF7 })
    assertSysex(sent[3], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x59, 0x13, 0x14, 0x00, 0xF7 })
    assertSysex(sent[4], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x5A, 0x13, 0x4E, 0x7F, 0xF7 })
end)

test.case("Parked/hidden slot sends nothing when turned", function()
    test.turn(1, 6) -- Sync OSC (only 3 params: slots 2, 3, 4)
    test.clear()

    test.turn(110, 50) -- Slot 10 fader is parked
    test.turn(210, 1)  -- Slot 10 list is parked
    test.none(test.sent(), "parked controls must not transmit")
end)

test.case("MODSRC1 (49 items) and MODSRC2 (36 items, non-contiguous) overlays map index to Z1 value", function()
    local ov1 = overlays.get(2)
    local ov2 = overlays.get(3)
    test.eq(ov1:getNumItems(), 49, "MODSRC1 count")
    test.eq(ov1:getValueByIndex(0), 0)
    test.eq(ov1:getValueByIndex(20), 20)
    test.eq(ov1:getValueByIndex(48), 48)

    test.eq(ov2:getNumItems(), 36, "MODSRC2 count")
    test.eq(ov2:getValueByIndex(0), 0, "MODSRC2 index 0 = Off (0)")
    test.eq(ov2:getValueByIndex(1), 11, "MODSRC2 index 1 = Note[Linear] (11)")
    test.eq(ov2:getValueByIndex(35), 45, "MODSRC2 index 35 = Porta SW (45)")
end)

test.case("All 13 OSC1 models load and formatters format special ranges", function()
    for m = 0, 12 do
        test.turn(1, m)
    end
    -- Currently on model 12 (Bowed String): slot 18 is 741 Damp TrkKey (note formatter)
    test.eq(fmtSlot(controls.get(118):getValue("value"), 60), "C4")
end)
