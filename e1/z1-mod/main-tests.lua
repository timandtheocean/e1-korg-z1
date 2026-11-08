-- Korg Z1 Amp 1 & 2, Output/Pan, OSC1 Pitch/Mod & PE Knobs 1..5 Preset Tests (Electra One firmware 5.0+)

local function assertZ1(msg, pl, pm, vl, vm)
    local exp = { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, pl, pm, vl, vm, 0xF7 }
    test.eq(msg.type, SYSEX)
    test.count(msg.data, 11)
    for i = 1, 11 do
        test.eq(msg.data[i], exp[i], "byte " .. i)
    end
end

test.case("Amp 1 (315..323), Amp 2 (324..332), and Output/Pan (352, 353, 355) send Parameter Changes", function()
    test.turn(1, 0)
    test.turn(2, 0)
    test.turn(5, 0)
    test.turn(6, 0)
    test.turn(7, 0)
    test.clear()

    test.turn(1, 90)  -- Amp1 Level (315 -> pl=3B, pm=02) = 90
    test.turn(2, 4)   -- Amp1 ModEG (320 -> pl=40, pm=02): index 4 -> value 5 (Amp EG)
    test.turn(5, 64)  -- Out Pan (352 -> pl=60, pm=02) = 64
    test.turn(6, 110) -- Out Level (355 -> pl=63, pm=02) = 110
    test.turn(7, 75)  -- Amp2 Level (324 -> pl=44, pm=02) = 75

    local sent = test.sent()
    test.count(sent, 5)
    assertZ1(sent[1], 0x3B, 0x02, 0x5A, 0x00)
    assertZ1(sent[2], 0x40, 0x02, 0x05, 0x00)
    assertZ1(sent[3], 0x60, 0x02, 0x40, 0x00)
    assertZ1(sent[4], 0x63, 0x02, 0x6E, 0x00)
    assertZ1(sent[5], 0x44, 0x02, 0x4B, 0x00)
end)

test.case("MOD SELECT 0 (OSC1 Pitch/Mod & Pan ModInt) sends IDs 175..187 and 354", function()
    test.turn(12, 0)
    test.turn(201, 0)
    test.turn(102, 0)
    test.turn(114, 0)
    test.clear()

    test.turn(201, 1)  -- O1 Octave (175 -> pl=2F, pm=01) = 16' (1)
    test.turn(102, -5) -- O1 Semi (176 -> pl=30, pm=01) = -5 (vl=7B, vm=7F)
    test.turn(114, 40) -- Pan ModInt (354 -> pl=62, pm=02) = +40

    local sent = test.sent()
    test.count(sent, 3)
    assertZ1(sent[1], 0x2F, 0x01, 0x01, 0x00)
    assertZ1(sent[2], 0x30, 0x01, 0x7B, 0x7F)
    assertZ1(sent[3], 0x62, 0x02, 0x28, 0x00)
    test.eq(controls.get(115):isVisible(), false)
end)

test.case("MOD SELECT 1..5 switches PE Knobs 1..5 (384..463) and preserves values per section", function()
    test.turn(12, 1) -- PE Knob 1 (base 384 -> pl=00, pm=03)
    test.turn(101, 0)
    test.turn(204, 0)
    test.clear()

    test.turn(101, 145) -- K1 T1 Prm (384 -> pl=00, pm=03) = 145 (vl=11, vm=01)
    test.turn(204, 2)   -- K1 T1 Curve (387 -> pl=03, pm=03) = LOG (2)

    local sent = test.sent()
    test.count(sent, 2)
    assertZ1(sent[1], 0x00, 0x03, 0x11, 0x01)
    assertZ1(sent[2], 0x03, 0x03, 0x02, 0x00)
    test.clear()

    test.turn(12, 5)    -- PE Knob 5 (448..463)
    test.none(test.sent())
    test.turn(216, 3)   -- K5 T4 Curve (463 -> pl=4F, pm=03) = SWITCH (3)
    test.count(test.sent(), 1)
    assertZ1(test.sent()[1], 0x4F, 0x03, 0x03, 0x00)
    test.clear()

    test.turn(12, 1)    -- Restore PE Knob 1 without sending
    test.none(test.sent())
    test.eq(controls.get(101):getValue("value"):getValue(), 145)
end)

test.case("Formatters format Panpot (L64..CNT..R63) and Note names", function()
    test.eq(fmtPan(nil, 64), "CNT")
    test.eq(fmtPan(nil, 0), "L64")
    test.eq(fmtPan(nil, 127), "R63")
    test.eq(fmtNote(nil, 60), "C4")
end)
