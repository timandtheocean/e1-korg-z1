-- Automated Functional Tests for Korg Z1 OSC Common (OSC1 & OSC2 Pitch/Slope/Mod, Model Display & Page Jump)

local function assertZ1(msg, pl, pm, vl, vm)
    local exp = { 0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, pl, pm, vl, vm, 0xF7 }
    test.eq(msg.type, SYSEX)
    test.count(msg.data, 11)
    for i = 1, 11 do
        test.eq(msg.data[i], exp[i], "byte " .. i)
    end
end

test.case("Jump OSC 1 (Control 1), Jump OSC 2 (Control 7) and OSC Common (336/636) navigate between pages", function()
    test.clear()
    test.turn(1, 1)
    test.eq(lastJumpedPage, OSC1_PAGE_ID)

    test.turn(336, 1)
    test.eq(lastJumpedPage, OSC_COMMON_PAGE_ID)

    test.turn(7, 1)
    test.eq(lastJumpedPage, OSC2_PAGE_ID)

    test.turn(636, 1)
    test.eq(lastJumpedPage, OSC_COMMON_PAGE_ID)
    test.none(test.sent(), "page jump buttons do not send SysEx")
end)

test.case("OSC1 Model (Control 2, ID 174) and OSC2 Model (Control 8, ID 188) update displayed model and send SysEx", function()
    test.clear()

    -- Select OSC1 Model 9 (Brass Model) -> ID 174 (pl=0x2E, pm=0x01)
    test.turn(2, 9)
    test.eq(getOsc1ModelName(), "Brass Model")

    -- Select OSC2 Model 2 (VPM OSC) -> ID 188 (pl=0x3C, pm=0x01)
    test.turn(8, 2)
    test.eq(getOsc2ModelName(), "VPM OSC")

    local sent = test.sent()
    test.count(sent, 2)
    assertZ1(sent[1], 0x2E, 0x01, 0x09, 0x00)
    assertZ1(sent[2], 0x3C, 0x01, 0x02, 0x00)

    -- Verify setOscModelsFromDump updates displayed models without echoing SysEx
    test.clear()
    setOscModelsFromDump(12, 7)
    test.eq(getOsc1ModelName(), "Bowed String")
    test.eq(getOsc2ModelName(), "Organ Model")
    test.none(test.sent())
end)

test.case("OSC 1 Pitch, Slope & Pitch Modulation controls send IDs 175..187 (ExID 0)", function()
    test.clear()

    -- Control 3: OSC1 Octave (175 -> pl=0x2F, pm=0x01) = 3 (4')
    test.turn(3, 3)
    -- Control 4: OSC1 Semi (176 -> pl=0x30, pm=0x01) = -5 (0x3FFB -> vl=0x7B, vm=0x7F)
    test.turn(4, -5)
    -- Control 13: OSC1 CtrKey (179 -> pl=0x33, pm=0x01) = 64 (E4)
    test.turn(13, 64)
    -- Control 25: OSC1 Mod1Src (182 -> pl=0x36, pm=0x01) = 6 (LFO1)
    test.turn(25, 6)
    -- Control 26: OSC1 Mod1Int (183 -> pl=0x37, pm=0x01) = 50
    test.turn(26, 50)

    local sent = test.sent()
    test.count(sent, 5)
    assertZ1(sent[1], 0x2F, 0x01, 0x03, 0x00)
    assertZ1(sent[2], 0x30, 0x01, 0x7B, 0x7F)
    assertZ1(sent[3], 0x33, 0x01, 0x40, 0x00)
    assertZ1(sent[4], 0x36, 0x01, 0x06, 0x00)
    assertZ1(sent[5], 0x37, 0x01, 0x32, 0x00)
end)

test.case("OSC 2 Pitch, Slope & Pitch Modulation controls send IDs 189..201 (ExID 0)", function()
    test.clear()

    -- Control 9: OSC2 Octave (189 -> pl=0x3D, pm=0x01) = 1 (16')
    test.turn(9, 1)
    -- Control 10: OSC2 Semi (190 -> pl=0x3E, pm=0x01) = -7 (0x3FF9 -> vl=0x79, vm=0x7F)
    test.turn(10, -7)
    -- Control 22: OSC2 Mod2Src (200 -> pl=0x48, pm=0x01) = 20 (Mod Wheel)
    test.turn(22, 20)
    -- Control 23: OSC2 Mod2Int (201 -> pl=0x49, pm=0x01) = 45 (0x2D)
    test.turn(23, 45)

    local sent = test.sent()
    test.count(sent, 4)
    assertZ1(sent[1], 0x3D, 0x01, 0x01, 0x00)
    assertZ1(sent[2], 0x3E, 0x01, 0x79, 0x7F)
    assertZ1(sent[3], 0x48, 0x01, 0x14, 0x00)
    assertZ1(sent[4], 0x49, 0x01, 0x2D, 0x00)
end)
