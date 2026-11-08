-- Korg Z1 Envelopes (EG1..4 & Amp EG) Preset Tests (Electra One firmware 5.0+)

local function assertSysex(msg, expected)
    test.eq(msg.type, SYSEX, "expected a SysEx message")
    test.count(msg.data, #expected, "SysEx byte length")
    for i = 1, #expected do
        test.eq(msg.data[i], expected[i], string.format("byte %d", i))
    end
end

test.case("EG1 dx7envelope handles send Attack Time (32), Attack Level (33, negative), Release Level (39)", function()
    -- Control 1 is EG1 dx7envelope: r1 = 32 (0x20), l1 = 33 (0x21), l4 = 39 (0x27)
    test.turn(1, 75, "r1")
    test.turn(1, -40, "l1") -- -40 = 0x3FD8 -> vl=58, vm=7F
    test.turn(1, 50, "l4")

    local sent = test.sent()
    test.count(sent, 3)
    assertSysex(sent[1], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x20, 0x00, 0x4B, 0x00, 0xF7 })
    assertSysex(sent[2], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x21, 0x00, 0x58, 0x7F, 0xF7 })
    assertSysex(sent[3], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x27, 0x00, 0x32, 0x00, 0xF7 })
end)

test.case("EG1..EG4 Start Level faders send params 31, 50, 69, 88", function()
    test.turn(11, -25) -- EG1 Start Level (31 = 0x1F), -25 = 0x3FE7 -> vl=67, vm=7F
    test.turn(14, 80)  -- EG4 Start Level (88 = 0x58)

    local sent = test.sent()
    test.count(sent, 2)
    assertSysex(sent[1], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x1F, 0x00, 0x67, 0x7F, 0xF7 })
    assertSysex(sent[2], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x58, 0x00, 0x50, 0x00, 0xF7 })
end)

test.case("Amp EG dx7envelope sends Attack Time (334) and ignores reserved l4 (341)", function()
    -- Control 5 is Amp EG: r1 = 334 (0x014E -> pl=4E, pm=02), l4 = nil (reserved)
    test.turn(5, 60, "r1")
    test.turn(5, 20, "l4")

    local sent = test.sent()
    test.count(sent, 1, "l4 on Amp EG is reserved and must not transmit")
    assertSysex(sent[1], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x4E, 0x02, 0x3C, 0x00, 0xF7 })
end)

test.case("Middle row dedicated Amp EG Modulations (21..30) send IDs 342..351", function()
    test.eq(controls.get(21):isVisible(), true)
    test.eq(controls.get(21):getName(), "Amp Lvl Src")

    -- Control 21 = Amp EG Level Mod Source (342 = 0x0156 -> pl=56, pm=02), value 19 (After Touch)
    test.turn(21, 19)
    -- Control 30 = Amp EG Release Time Mod Int (351 = 0x015F -> pl=5F, pm=02), value -15 (0x3FF1 -> vl=71, vm=7F)
    test.turn(30, -15)

    local sent = test.sent()
    test.count(sent, 2)
    assertSysex(sent[1], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x56, 0x02, 0x13, 0x00, 0xF7 })
    assertSysex(sent[2], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x5F, 0x02, 0x71, 0x7F, 0xF7 })
end)

test.case("Bottom row EG 1..4 Modulations save & restore per-EG values on target switch without echoing", function()
    -- Start on EG1 (index 0 on control 20)
    test.turn(20, 0)
    test.clear()

    -- Set EG1 Lvl Int (control 32, ID 41 = 0x29) to +21
    test.turn(32, 21)
    test.eq(controls.get(32):getValue("value"):getValue(), 21)
    test.count(test.sent(), 1)
    assertSysex(test.sent()[1], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x29, 0x00, 0x15, 0x00, 0xF7 })
    test.clear()

    -- Switch to EG2 (index 1 on control 20) -> control 32 must reset to 0 (EG2's saved value) and send nothing
    test.turn(20, 1)
    test.none(test.sent(), "switching EG target must not transmit saved values")
    test.eq(controls.get(32):getName(), "EG2 Lvl Int")
    test.eq(controls.get(32):getValue("value"):getValue(), 0, "EG2 Lvl Int is 0")

    -- Set EG2 Lvl Int (control 32, ID 60 = 0x3C) to -35 (0x3FDD -> vl=5D, vm=7F)
    test.turn(32, -35)
    test.count(test.sent(), 1)
    assertSysex(test.sent()[1], { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x3C, 0x00, 0x5D, 0x7F, 0xF7 })
    test.clear()

    -- Switch back to EG1 (index 0) -> control 32 restores +21 without sending
    test.turn(20, 0)
    test.none(test.sent(), "switching back to EG1 must not transmit")
    test.eq(controls.get(32):getName(), "EG1 Lvl Int")
    test.eq(controls.get(32):getValue("value"):getValue(), 21, "EG1 Lvl Int restored to +21")
end)
