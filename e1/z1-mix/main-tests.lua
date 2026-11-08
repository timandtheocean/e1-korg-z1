-- Korg Z1 Mixer & Mix Modulation Preset Tests (Electra One firmware 5.0+)

local function assertZ1(msg, pl, pm, vl, vm)
    local exp = { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, pl, pm, vl, vm, 0xF7 }
    test.eq(msg.type, SYSEX)
    test.count(msg.data, 11)
    for i = 1, 11 do
        test.eq(msg.data[i], exp[i], "byte " .. i)
    end
end

test.case("Out 1 & Out 2 Level faders send Mixer Level Parameter Changes (224..251) and update mixState", function()
    test.turn(1, 0)
    test.turn(8, 0)
    test.turn(3, 0)
    test.turn(11, 0)
    test.clear()

    test.turn(1, 85)
    test.turn(8, 64)
    test.turn(3, 72)
    test.turn(11, 40)

    local sent = test.sent()
    test.count(sent, 4)
    assertZ1(sent[1], 0x60, 0x01, 0x55, 0x00)
    assertZ1(sent[2], 0x69, 0x01, 0x40, 0x00)
    assertZ1(sent[3], 0x6C, 0x01, 0x48, 0x00)
    assertZ1(sent[4], 0x7B, 0x01, 0x28, 0x00)

    test.eq(mixState[1].out1Lvl, 85)
    test.eq(mixState[2].out2Lvl, 64)
    test.eq(mixState[3].out1Lvl, 72)
    test.eq(mixState[5].out2Lvl, 40)
end)

test.case("Out 1 & Out 2 Level Mod Source (List 1) and signed Mod Int (-99..+99) send 14-bit two's complement", function()
    test.turn(13, 0)
    test.turn(19, 0)
    test.turn(28, 0)
    test.turn(34, 0)
    test.clear()

    test.turn(13, 6)
    test.turn(19, -45)
    test.turn(28, 20)
    test.turn(34, 60)

    local sent = test.sent()
    test.count(sent, 4)
    assertZ1(sent[1], 0x61, 0x01, 0x06, 0x00)
    assertZ1(sent[2], 0x62, 0x01, 0x53, 0x7F)
    assertZ1(sent[3], 0x76, 0x01, 0x14, 0x00)
    assertZ1(sent[4], 0x77, 0x01, 0x3C, 0x00)
end)

test.case("Mixer Output Switches (254..257) cross 7-bit parameter ID boundary (255 -> 256) and gate evalMixBusLevel", function()
    test.turn(1, 99)
    test.turn(6, 1)
    test.turn(12, 1)
    test.turn(18, 0)
    test.turn(24, 0)
    test.clear()

    test.turn(6, 0)
    test.eq(evalMixBusLevel(1, 1), 0.0)
    test.turn(12, 0)
    test.turn(18, 1)
    test.turn(24, 1)

    local sent = test.sent()
    test.count(sent, 4)
    assertZ1(sent[1], 0x7E, 0x01, 0x00, 0x00)
    assertZ1(sent[2], 0x7F, 0x01, 0x00, 0x00)
    assertZ1(sent[3], 0x00, 0x02, 0x01, 0x00)
    assertZ1(sent[4], 0x01, 0x02, 0x01, 0x00)

    test.turn(6, 1)
    test.eq(evalMixBusLevel(1, 1), 1.0)
end)

test.case("Feedback channel (IDs 248..253) sends Out1/Out2 Level, Mod Source, and Mod Int", function()
    test.turn(5, 0)
    test.turn(17, 0)
    test.turn(23, 0)
    test.turn(29, 0)
    test.turn(35, 0)
    test.clear()

    test.turn(5, 50)
    test.turn(17, 19)
    test.turn(23, 99)
    test.turn(29, 48)
    test.turn(35, -99)

    local sent = test.sent()
    test.count(sent, 5)
    assertZ1(sent[1], 0x78, 0x01, 0x32, 0x00)
    assertZ1(sent[2], 0x79, 0x01, 0x13, 0x00)
    assertZ1(sent[3], 0x7A, 0x01, 0x63, 0x00)
    assertZ1(sent[4], 0x7C, 0x01, 0x30, 0x00)
    assertZ1(sent[5], 0x7D, 0x01, 0x1D, 0x7F)
end)

test.case("All 34 Mixer controls map to distinct Z1 parameter IDs 224..257", function()
    local seen, count = {}, 0
    for _, spec in pairs(MIX_CTRL_MAP) do
        test.ok(spec.id >= 224 and spec.id <= 257)
        test.eq(seen[spec.id], nil)
        seen[spec.id] = true
        count = count + 1
    end
    test.eq(count, 34)
end)
