-- Korg Z1 Sub Oscillator, Noise Generator & OSC Common Preset Tests (Electra One firmware 5.0+)

local function assertZ1(msg, pl, pm, vl, vm)
    local exp = { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, pl, pm, vl, vm, 0xF7 }
    test.eq(msg.type, SYSEX)
    test.count(msg.data, 11)
    for i = 1, 11 do
        test.eq(msg.data[i], exp[i], "byte " .. i)
    end
end

test.case("Sub Oscillator controls send Wave (215), Octave (202), Semi (203), and Pitch Mod (209..214)", function()
    test.turn(1, 0)
    test.turn(2, 0)
    test.turn(3, 0)
    test.turn(13, 0)
    test.turn(14, 0)
    test.clear()

    test.turn(1, 2)    -- Sub Wave (215 -> pl=57, pm=01) = TRI (2)
    test.turn(2, 1)    -- Sub Octave (202 -> pl=4A, pm=01) = 16' (1)
    test.turn(3, -12)  -- Sub Semi (203 -> pl=4B, pm=01) = -12 (vl=74, vm=7F)
    test.turn(13, 6)   -- Sub Mod2 Src (213 -> pl=55, pm=01) = LFO1 (6)
    test.turn(14, 50)  -- Sub Mod2 Int (214 -> pl=56, pm=01) = +50

    local sent = test.sent()
    test.count(sent, 5)
    assertZ1(sent[1], 0x57, 0x01, 0x02, 0x00)
    assertZ1(sent[2], 0x4A, 0x01, 0x01, 0x00)
    assertZ1(sent[3], 0x4B, 0x01, 0x74, 0x7F)
    assertZ1(sent[4], 0x55, 0x01, 0x06, 0x00)
    assertZ1(sent[5], 0x56, 0x01, 0x32, 0x00)
end)

test.case("Noise Generator controls send Filter Type (216), Cutoff (218), Reso (223), and Cutoff Mod (219..222)", function()
    test.turn(15, 0)
    test.turn(17, 0)
    test.turn(18, 0)
    test.turn(19, 0)
    test.turn(20, 0)
    test.clear()

    test.turn(15, 3)   -- Noise Filter Type (216 -> pl=58, pm=01) = BPF (3)
    test.turn(17, 75)  -- Noise Cutoff (218 -> pl=5A, pm=01) = 75
    test.turn(18, 60)  -- Noise Reso (223 -> pl=5F, pm=01) = 60
    test.turn(19, 3)   -- Noise Cut Mod1 Src (219 -> pl=5B, pm=01) = EG3 (3)
    test.turn(20, -30) -- Noise Cut Mod1 Int (220 -> pl=5C, pm=01) = -30 (vl=62, vm=7F)

    local sent = test.sent()
    test.count(sent, 5)
    assertZ1(sent[1], 0x58, 0x01, 0x03, 0x00)
    assertZ1(sent[2], 0x5A, 0x01, 0x4B, 0x00)
    assertZ1(sent[3], 0x5F, 0x01, 0x3C, 0x00)
    assertZ1(sent[4], 0x5B, 0x01, 0x03, 0x00)
    assertZ1(sent[5], 0x5C, 0x01, 0x62, 0x7F)
end)

test.case("OSC Common controls send Pitch Bend (163..166), Common Mod (167..168), and Portamento (169..173)", function()
    test.turn(25, 0)
    test.turn(26, 0)
    test.turn(31, 0)
    test.turn(32, 0)
    test.turn(33, 0)
    test.clear()

    test.turn(25, 12)  -- PBend Int+ (163 -> pl=23, pm=01) = +12
    test.turn(26, -24) -- PBend Int- (164 -> pl=24, pm=01) = -24 (vl=68, vm=7F)
    test.turn(31, 1)   -- Porta SW (169 -> pl=29, pm=01) = ON (1)
    test.turn(32, 1)   -- Porta Mode (170 -> pl=2A, pm=01) = FINGERED (1)
    test.turn(33, 44)  -- Porta Time (171 -> pl=2B, pm=01) = 44

    local sent = test.sent()
    test.count(sent, 5)
    assertZ1(sent[1], 0x23, 0x01, 0x0C, 0x00)
    assertZ1(sent[2], 0x24, 0x01, 0x68, 0x7F)
    assertZ1(sent[3], 0x29, 0x01, 0x01, 0x00)
    assertZ1(sent[4], 0x2A, 0x01, 0x01, 0x00)
    assertZ1(sent[5], 0x2B, 0x01, 0x2C, 0x00)
end)

test.case("All 33 Sub/Noise/Common controls map to distinct Z1 parameter IDs and formatters work", function()
    local seen, count = {}, 0
    for _, spec in pairs(SUB_NOISE_MAP) do
        test.eq(seen[spec.id], nil)
        seen[spec.id] = true
        count = count + 1
    end
    test.eq(count, 33)
    test.eq(fmtHz10(nil, 35), "+3.5 Hz")
    test.eq(fmtSlope(nil, -25), "-0.50")
    test.eq(fmtNote(nil, 60), "C4")
end)
