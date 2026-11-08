-- Automated Functional Tests for Korg Z1 Common, Controllers, Arp & Name Preset (Electra One firmware 5.0+)

local function assertZ1(msg, pl, pm, vl, vm)
    local exp = { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, pl, pm, vl, vm, 0xF7 }
    test.eq(msg.type, SYSEX)
    test.count(msg.data, 11)
    for i = 1, 11 do
        test.eq(msg.data[i], exp[i], "byte " .. i)
    end
end

test.case("Program Common & Retrigger MODSRC2", function()
    test.turn(1, 0)
    test.turn(6, 0)
    test.turn(11, 0)
    test.clear()

    test.turn(1, 9)   -- Category (17) = 9 ("Strings")
    test.turn(6, 10)  -- Retrigger Src (22, MODSRC2): index 10 -> value 20
    test.turn(11, 35) -- Unison Detune (27) = 35 cents

    local sent = test.sent()
    test.count(sent, 3)
    assertZ1(sent[1], 17, 0, 9, 0)
    assertZ1(sent[2], 22, 0, 20, 0)
    assertZ1(sent[3], 27, 0, 35, 0)
end)

test.case("Scale & Link Arpeggiator (14-bit Speed & Negative VelCtrl)", function()
    test.turn(13, 0)
    test.turn(15, 0)
    test.turn(16, 0)
    test.turn(23, 0)
    test.clear()

    test.turn(13, 3)    -- Scale Type (29) = 3 ("Arabic")
    test.turn(15, 4)    -- Arp Pattern (374 -> pl=118, pm=2) = 4 ("RANDOM")
    test.turn(16, 200)  -- Arp Speed (383 -> pl=127, pm=2) = 200 -> vl=72, vm=1
    test.turn(23, -100) -- Arp VelCtrl (380 -> pl=124, pm=2) = -100 -> vl=28, vm=127

    local sent = test.sent()
    test.count(sent, 4)
    assertZ1(sent[1], 29, 0, 3, 0)
    assertZ1(sent[2], 118, 2, 4, 0)
    assertZ1(sent[3], 127, 2, 72, 1)
    assertZ1(sent[4], 124, 2, 28, 127)
end)

test.case("Assignable Controllers (SW1, FootSW, Pedal, Pad Hold)", function()
    test.turn(25, 0)
    test.turn(29, 0)
    test.turn(31, 0)
    test.turn(32, 0)
    test.clear()

    test.turn(25, 7)  -- SW1 Func (366 -> pl=110, pm=2) = 7 ("Unison")
    test.turn(29, 11) -- FootSW Func (370 -> pl=114, pm=2) = 11 ("Arpeggio SW")
    test.turn(31, 5)  -- Pedal Func (372 -> pl=116, pm=2) = 5 ("Expr(CC#11)")
    test.turn(32, 1)  -- Pad Hold (373 -> pl=117, pm=2) = 1 ("ON")

    local sent = test.sent()
    test.count(sent, 4)
    assertZ1(sent[1], 110, 2, 7, 0)
    assertZ1(sent[2], 114, 2, 11, 0)
    assertZ1(sent[3], 116, 2, 5, 0)
    assertZ1(sent[4], 117, 2, 1, 0)
end)

test.case("Program Name Editing & Dump Sync", function()
    test.turn(33, 1)
    test.turn(34, 65)
    test.clear()

    test.turn(33, 2)  -- Select Pos 2 -> no MIDI sent
    test.count(test.sent(), 0)

    test.turn(34, 90) -- Set Char 2 (ID 2) to 'Z' (90)
    test.turn(33, 3)  -- Select Pos 3
    test.turn(34, 49) -- Set Char 3 (ID 3) to '1' (49)

    local sent = test.sent()
    test.count(sent, 2)
    assertZ1(sent[1], 2, 0, 90, 0)
    assertZ1(sent[2], 3, 0, 49, 0)

    test.clear()
    setProgramNameFromDump({ 0x4D, 0x4F, 0x53, 0x53, 0x20, 0x4C, 0x65, 0x61, 0x64 })
    test.count(test.sent(), 0)
    test.eq(getProgramNameString(), "MOSS Lead       ")
end)
