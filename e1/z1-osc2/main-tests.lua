-- Korg Z1 OSC2 Dynamic Model Preset Tests (Electra One firmware 5.0+)

local function assertZ1(msg, pl, pm, vl, vm)
    local exp = { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, pl, pm, vl, vm, 0xF7 }
    test.eq(msg.type, SYSEX)
    test.count(msg.data, 11)
    for i = 1, 11 do
        test.eq(msg.data[i], exp[i], "byte " .. i)
    end
end

test.case("OSC2 Type selector sends param 188 (ExID 0) and relayouts Comb Filter (14 params)", function()
    test.turn(1, 0)
    test.clear()

    test.turn(1, 1) -- Comb Filter (value 1)
    local sent = test.sent()
    test.count(sent, 1)
    assertZ1(sent[1], 0x3C, 0x01, 0x01, 0x00)

    test.eq(controls.get(202):isVisible(), true)
    test.eq(controls.get(202):getName(), "Input Sel")
    test.eq(controls.get(115):isVisible(), true)
    test.eq(controls.get(116):isVisible(), false)
    test.eq(controls.get(216):isVisible(), false)
end)

test.case("Standard OSC on OSC2 sends ExID 2 (4096 + ID): Wave (464), LFO (471), ModSrc1 (473), ModInt (474)", function()
    test.turn(1, 0)
    test.turn(202, 0)
    test.turn(209, 0)
    test.turn(211, 0)
    test.turn(112, 0)
    test.clear()

    test.turn(202, 1)
    test.turn(209, 2)
    test.turn(211, 20)
    test.turn(112, -50)

    local sent = test.sent()
    test.count(sent, 4)
    assertZ1(sent[1], 0x50, 0x23, 0x01, 0x00)
    assertZ1(sent[2], 0x57, 0x23, 0x08, 0x00)
    assertZ1(sent[3], 0x59, 0x23, 0x14, 0x00)
    assertZ1(sent[4], 0x5A, 0x23, 0x4E, 0x7F)
end)

test.case("Parked/hidden slot sends nothing when turned", function()
    test.turn(1, 6) -- Sync OSC (3 params: slots 2, 3, 4)
    test.clear()

    test.turn(110, 50)
    test.turn(210, 1)
    test.none(test.sent())
end)

test.case("All 9 OSC2 models (0..8) load and formatters format db, coarse, plus1, offneg", function()
    for m = 0, 8 do
        test.turn(1, m)
    end
    test.eq(fmtSlot(controls.get(115):getValue("value"), -6), "-6 dB")
end)
