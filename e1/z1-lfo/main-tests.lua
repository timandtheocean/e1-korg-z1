-- Korg Z1 LFO 1..4 Preset Tests (Electra One firmware 5.0+)

local function assertSysex(msg, expected)
    test.eq(msg.type, SYSEX, "expected a SysEx message")
    test.count(msg.data, #expected, "SysEx byte length")
    for i = 1, #expected do
        test.eq(msg.data[i], expected[i], string.format("byte %d", i))
    end
end

test.case("LFO 1..4 core controls send Wave, KeySync, Freq, FadeIn, Offset and update custom graph state", function()
    -- Control 1 = LFO1 Wave (ID 107 = 0x6B), index 8 = Square
    test.turn(1, 8)
    -- Control 3 = LFO1 Freq (ID 109 = 0x6D), value 150 (0x0096 -> vl=16, vm=01)
    test.turn(3, 150)
    -- Control 9 = LFO1 Offset (ID 117 = 0x75), value -25 (0x3FE7 -> vl=67, vm=7F)
    test.turn(9, -25)
    -- Control 16 = LFO4 Wave (ID 149 = 0x0095 -> pl=15, pm=01), index 15 = Exp Triangle
    test.turn(16, 15)

    local sent = test.sent()
    test.count(sent, 4)
    assertSysex(sent[1], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x6B, 0x00, 0x08, 0x00, 0xF7 })
    assertSysex(sent[2], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x6D, 0x00, 0x16, 0x01, 0xF7 })
    assertSysex(sent[3], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x75, 0x00, 0x67, 0x7F, 0xF7 })
    assertSysex(sent[4], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x15, 0x01, 0x0F, 0x00, 0xF7 })

    test.eq(lfoState[1].wave, 8)
    test.eq(lfoState[1].freq, 150)
    test.eq(lfoState[1].offset, -25)
    test.eq(lfoState[4].wave, 15)
end)

test.case("LFO SELECT switches MIDI Sync & Modulation between LFO 1..4 and saves per-LFO values", function()
    test.turn(25, 0) -- LFO 1
    test.clear()

    -- Set LFO1 Freq Mod1 Int (control 30, ID 111 = 0x6F) to +33 (0x21)
    test.turn(30, 33)
    -- Set LFO1 Sync Time (control 28, ID 120 = 0x78) to 7 (displays "8")
    test.turn(28, 7)
    test.eq(fmtPlus1(nil, 7), "8")
    test.count(test.sent(), 2)
    assertSysex(test.sent()[1], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x6F, 0x00, 0x21, 0x00, 0xF7 })
    assertSysex(test.sent()[2], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x78, 0x00, 0x07, 0x00, 0xF7 })
    test.clear()

    -- Switch to LFO 3 (index 2 on control 25) -> must not transmit, restores LFO 3 defaults (0)
    test.turn(25, 2)
    test.none(test.sent(), "switching LFO SELECT must not transmit")
    test.eq(controls.get(30):getName(), "LFO3 FrqInt 1")
    test.eq(controls.get(30):getValue("value"):getValue(), 0)

    -- Set LFO3 Freq Mod1 Int (control 30, ID 139 = 0x008B -> pl=0B, pm=01) to -45 (0x3FD3 -> vl=53, vm=7F)
    test.turn(30, -45)
    test.count(test.sent(), 1)
    assertSysex(test.sent()[1], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x0B, 0x01, 0x53, 0x7F, 0xF7 })
    test.clear()

    -- Switch back to LFO 1 (index 0) -> restores +33 and 7 without sending
    test.turn(25, 0)
    test.none(test.sent())
    test.eq(controls.get(30):getValue("value"):getValue(), 33)
    test.eq(controls.get(28):getValue("value"):getValue(), 7)
end)

test.case("Custom LFO waveform evaluator covers all 18 Z1 wave shapes (0..17) within [-1, 1]", function()
    for w = 0, 17 do
        for step = 0, 10 do
            local y = evalZ1Wave(w, step / 10)
            test.ok(y >= -1.001 and y <= 1.001, "wave " .. w .. " in bounds")
        end
    end
end)
