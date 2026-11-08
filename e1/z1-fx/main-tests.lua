-- Automated Functional Tests for Korg Z1 Effects & EQ Preset (Electra One firmware 5.0+)

local function assertZ1(msg, pl, pm, vl, vm)
    local exp = { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, pl, pm, vl, vm, 0xF7 }
    test.eq(msg.type, SYSEX)
    test.count(msg.data, 11)
    for i = 1, 11 do
        test.eq(msg.data[i], exp[i], "byte " .. i)
    end
end

-- Case 1: Top FX Selects, Send & 2-Band EQ (IDs 356..365, ExID = 0)
test.case("FX Top Controls & 2-Band EQ", function()
    test.turn(4, 10)
    test.turn(8, 0)
    test.clear()

    -- FX Send (ID 356 -> pl=100, pm=2) = 80
    test.turn(4, 80)
    -- EQ LoGain (ID 363 -> pl=107, pm=2) = -12 -> 0x3FF4 -> vl=116, vm=127
    test.turn(8, -12)

    local sent = test.sent()
    test.count(sent, 2)
    assertZ1(sent[1], 100, 2, 80, 0)
    assertZ1(sent[2], 107, 2, 116, 127)
end)

-- Case 2: FX1 Rotary Speaker (Alg 14, ExID = 3) & Non-Contiguous MODSRC2
test.case("FX1 Rotary Speaker & MODSRC2", function()
    test.turn(11, 0) -- Edit FX1
    test.turn(1, 0)  -- FX1 = Overdrive
    test.clear()

    -- Switch FX1 to Rotary Speaker (14); ID 359 -> pl=103, pm=2
    test.turn(1, 14)
    test.eq(controls.get(105):isVisible(), true) -- Slot 5: Rotor Accel (994)
    test.eq(controls.get(213):isVisible(), true) -- Slot 13: Bal ModSrc (1002, MODSRC2)
    test.eq(controls.get(115):isVisible(), false) -- Only 14 params

    -- Slot 5 (Rotor Accel, ID 994, ExID=3 -> id14=7138 -> pl=98, pm=55) = 65
    test.turn(105, 65)
    -- Slot 13 (Bal ModSrc, ID 1002, ExID=3 -> id14=7146 -> pl=106, pm=55)
    -- MODSRC2 index 1 -> Z1 value 11 ("Note[Linear]")
    test.turn(213, 1)

    local sent = test.sent()
    test.count(sent, 3)
    assertZ1(sent[1], 103, 2, 14, 0)
    assertZ1(sent[2], 98, 55, 65, 0)
    assertZ1(sent[3], 106, 55, 11, 0)
end)

-- Case 3: FX2 Chorus (Alg 6, ExID = 4)
test.case("FX2 Chorus ExID=4", function()
    test.turn(11, 1) -- Edit FX2
    test.turn(2, 0)
    test.clear()

    -- FX2 Select = Chorus (6); ID 360 -> pl=104, pm=2
    test.turn(2, 6)
    -- Slot 1 (Delay Time, ID 882, ExID=4 -> id14=9074 -> pl=114, pm=70) = 55
    test.turn(101, 55)

    local sent = test.sent()
    test.count(sent, 2)
    assertZ1(sent[1], 104, 2, 6, 0)
    assertZ1(sent[2], 114, 70, 55, 0)
end)

-- Case 4: Master FX Reverb-Hall (Alg 1, ExID = 5) & Unit Preset Save/Recall
test.case("Master FX ExID=5 & Preset Save/Recall", function()
    test.turn(11, 2) -- Edit Master FX
    test.turn(3, 0)  -- MFX = Stereo Delay
    test.turn(12, 0)
    test.clear()

    -- MFX Select = Reverb-Hall (1); ID 361 -> pl=105, pm=2
    test.turn(3, 1)
    -- Slot 1 (Reverb Time, ID 1018, ExID=5 -> id14=11258 -> pl=122, pm=87) = 42
    test.turn(101, 42)
    -- Save Unit Preset 1 (act = 3)
    test.turn(12, 3)

    -- Change Reverb Time to 10, then Recall Unit Preset 1 (act = 1)
    test.turn(101, 10)
    test.clear()
    test.turn(12, 1)

    local sent = test.sent()
    -- Recall sends MFX Select (361 = 1) + all 10 Reverb-Hall params (first is 1018 = 42)
    test.count(sent, 11)
    assertZ1(sent[1], 105, 2, 1, 0)
    assertZ1(sent[2], 122, 87, 42, 0)
end)
