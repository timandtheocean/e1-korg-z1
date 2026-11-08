-- Korg Z1 - Sub Oscillator, Noise Generator & OSC Common Page for Electra One mk2
-- Covers all 33 Program Parameters across:
--   [SUB OSC]         (IDs 202..215, 14 params, ExID = 0)
--   [Noise Generator] (IDs 216..223, 8 params,  ExID = 0)
--   [OSC Common]      (IDs 163..173, 11 params, ExID = 0)
--
-- Layout (35 slots across 3 Control Sets):
--   Control Set 1 (Rows 1-2, Slots 1..12):
--     [1]  Sub Wave (215),   [2]  Sub Octave (202), [3]  Sub Semi (203),   [4]  Sub Fine (204),
--     [5]  Sub Offset (205), [6]  Sub CtrKey (206), [7]  Sub LoSlp (207),  [8]  Sub HiSlp (208),
--     [9]  Sub Mod1Src (209),[10] Sub Mod1Int (210),[11] Sub M1Ctrl (211), [12] Sub M1CInt (212)
--   Control Set 2 (Rows 3-4, Slots 13..22):
--     [13] Sub Mod2Src (213),[14] Sub Mod2Int (214),[15] Noise Flt (216),  [16] Noise Trim (217),
--     [17] Noise Cut (218),  [18] Noise Reso (223), [19] Ns CutSrc1 (219), [20] Ns CutInt1 (220),
--     [21] Ns CutSrc2 (221), [22] Ns CutInt2 (222)
--   Control Set 3 (Rows 5-6, Slots 25..35):
--     [25] PBend Int+ (163), [26] PBend Int- (164), [27] PBend Stp+ (165), [28] PBend Stp- (166),
--     [29] CmnMod Src (167), [30] CmnMod Int (168), [31] Porta SW (169),   [32] Porta Mode (170),
--     [33] Porta Time (171), [34] Porta Src (172),  [35] Porta Int (173)

local DEVICE_ID = 1

local function getGlobalChannel()
    local dev = preset.getDevice(DEVICE_ID)
    if dev then
        return (dev:getChannel() - 1) & 0x0F
    end
    return 0
end

-- ============================================================================
-- 1. Overlays & Enumerations
-- ============================================================================

MODSRC1 = {
    { value = 0,  label = "Off" },
    { value = 1,  label = "EG1" },
    { value = 2,  label = "EG2" },
    { value = 3,  label = "EG3" },
    { value = 4,  label = "EG4" },
    { value = 5,  label = "Amp EG" },
    { value = 6,  label = "LFO1" },
    { value = 7,  label = "LFO2" },
    { value = 8,  label = "LFO3" },
    { value = 9,  label = "LFO4" },
    { value = 10, label = "Portamento" },
    { value = 11, label = "Note[Linear]" },
    { value = 12, label = "Note[Exp]" },
    { value = 13, label = "Note Split[High]" },
    { value = 14, label = "Note Split[Low]" },
    { value = 15, label = "Velocity[Soft]" },
    { value = 16, label = "Velocity[Medium]" },
    { value = 17, label = "Velocity[Hard]" },
    { value = 18, label = "Pitch Bend" },
    { value = 19, label = "After Touch" },
    { value = 20, label = "Mod Wheel(CC#1)" },
    { value = 21, label = "ATouch+Mod.Wheel" },
    { value = 22, label = "ATHalf+Mod.Wheel" },
    { value = 23, label = "X[+/-](CC#16)" },
    { value = 24, label = "X[+](CC#16)" },
    { value = 25, label = "X[-](CC#16)" },
    { value = 26, label = "Y[+/-](CC#17)" },
    { value = 27, label = "Y[+](CC#17)" },
    { value = 28, label = "Y[-](CC#17)" },
    { value = 29, label = "Knob1(CC#19)" },
    { value = 30, label = "Knob2(CC#20)" },
    { value = 31, label = "Knob3(CC#21)" },
    { value = 32, label = "Knob4(CC#22)" },
    { value = 33, label = "Knob5(CC#23)" },
    { value = 34, label = "Mod.SW1(CC#80)" },
    { value = 35, label = "Mod.SW2(CC#81)" },
    { value = 36, label = "Foot SW(CC#82)" },
    { value = 37, label = "Foot Pedal(CC#4)" },
    { value = 38, label = "Damper(CC#64)" },
    { value = 39, label = "Sostenuto(CC#66)" },
    { value = 40, label = "Breath(CC#2)" },
    { value = 41, label = "MIDI Vol(CC#7)" },
    { value = 42, label = "MIDI Pan(CC#10)" },
    { value = 43, label = "MIDI Expr(CC#11)" },
    { value = 44, label = "Porta Time(CC#5)" },
    { value = 45, label = "Porta SW(CC#65)" },
    { value = 46, label = "MasterFX(CC#92)" },
    { value = 47, label = "FX1 SW(CC#94)" },
    { value = 48, label = "FX2 SW(CC#95)" },
}

local OV = {
    MODSRC1    = 1,
    SUB_WAVE   = 2,
    OCTAVE     = 3,
    NOISE_FLT  = 4,
    PB_STEP    = 5,
    PORTA_MODE = 6,
}

local ENUM_DEFS = {
    [OV.MODSRC1] = MODSRC1,
    [OV.SUB_WAVE] = {
        { value = 0, label = "SAW" },
        { value = 1, label = "SQU" },
        { value = 2, label = "TRI" },
        { value = 3, label = "SIN" },
    },
    [OV.OCTAVE] = {
        { value = 0, label = "32'" },
        { value = 1, label = "16'" },
        { value = 2, label = "8'" },
        { value = 3, label = "4'" },
    },
    [OV.NOISE_FLT] = {
        { value = 0, label = "THRU" },
        { value = 1, label = "LPF" },
        { value = 2, label = "HPF" },
        { value = 3, label = "BPF" },
    },
    [OV.PB_STEP] = {
        { value = 0,  label = "CONT" },
        { value = 1,  label = "1/8" },
        { value = 2,  label = "1/4" },
        { value = 3,  label = "1/2" },
        { value = 4,  label = "1 Semi" },
        { value = 5,  label = "2 Semi" },
        { value = 6,  label = "3 Semi" },
        { value = 7,  label = "4 Semi" },
        { value = 8,  label = "5 Semi" },
        { value = 9,  label = "6 Semi" },
        { value = 10, label = "7 Semi" },
        { value = 11, label = "8 Semi" },
        { value = 12, label = "9 Semi" },
        { value = 13, label = "10 Semi" },
        { value = 14, label = "11 Semi" },
        { value = 15, label = "12 Semi" },
    },
    [OV.PORTA_MODE] = {
        { value = 0, label = "NORMAL" },
        { value = 1, label = "FINGERED" },
    },
}

-- ============================================================================
-- 2. Parameter Mapping (PROG_PRM.TXT IDs 163..173 & 202..223, ExID = 0)
-- ============================================================================

SUB_NOISE_MAP = {
    -- SUB OSC (IDs 202..215)
    [1]  = { id = 215, kind = "list", ov = OV.SUB_WAVE },
    [2]  = { id = 202, kind = "list", ov = OV.OCTAVE },
    [3]  = { id = 203, kind = "num" },
    [4]  = { id = 204, kind = "num" },
    [5]  = { id = 205, kind = "num",  fmt = "hz10" },
    [6]  = { id = 206, kind = "num",  fmt = "note" },
    [7]  = { id = 207, kind = "num",  fmt = "slope" },
    [8]  = { id = 208, kind = "num",  fmt = "slope" },
    [9]  = { id = 209, kind = "list", ov = OV.MODSRC1 },
    [10] = { id = 210, kind = "num" },
    [11] = { id = 211, kind = "list", ov = OV.MODSRC1 },
    [12] = { id = 212, kind = "num" },
    [13] = { id = 213, kind = "list", ov = OV.MODSRC1 },
    [14] = { id = 214, kind = "num" },
    -- Noise Generator (IDs 216..223)
    [15] = { id = 216, kind = "list", ov = OV.NOISE_FLT },
    [16] = { id = 217, kind = "num" },
    [17] = { id = 218, kind = "num" },
    [18] = { id = 223, kind = "num" },
    [19] = { id = 219, kind = "list", ov = OV.MODSRC1 },
    [20] = { id = 220, kind = "num" },
    [21] = { id = 221, kind = "list", ov = OV.MODSRC1 },
    [22] = { id = 222, kind = "num" },
    -- OSC Common: Pitch Bend, Common Pitch Mod, Portamento (IDs 163..173)
    [25] = { id = 163, kind = "num" },
    [26] = { id = 164, kind = "num" },
    [27] = { id = 165, kind = "list", ov = OV.PB_STEP },
    [28] = { id = 166, kind = "list", ov = OV.PB_STEP },
    [29] = { id = 167, kind = "list", ov = OV.MODSRC1 },
    [30] = { id = 168, kind = "num" },
    [31] = { id = 169, kind = "num" },
    [32] = { id = 170, kind = "list", ov = OV.PORTA_MODE },
    [33] = { id = 171, kind = "num" },
    [34] = { id = 172, kind = "list", ov = OV.MODSRC1 },
    [35] = { id = 173, kind = "num" },
}

local NOTE_NAMES = { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" }

function fmtHz10(_valueObject, value)
    return string.format("%+.1f Hz", math.floor(value) / 10.0)
end

function fmtSlope(_valueObject, value)
    return string.format("%+.2f", math.floor(value) / 50.0)
end

function fmtNote(_valueObject, value)
    local v = math.floor(value)
    local n = NOTE_NAMES[(v % 12) + 1]
    local oct = (v // 12) - 1
    return string.format("%s%d", n, oct)
end

-- ============================================================================
-- 3. SysEx Builder & Sender
-- ============================================================================

function buildParamChangeBody(exId, paramId, signedVal, gCh)
    local g = gCh or getGlobalChannel()
    local id14 = ((exId & 0x07) << 11) | (paramId & 0x07FF)
    local v14 = signedVal & 0x3FFF
    return {
        0x42,
        0x30 | (g & 0x0F),
        0x46,
        0x41,
        0x01,
        id14 & 0x7F,
        (id14 >> 7) & 0x7F,
        v14 & 0x7F,
        (v14 >> 7) & 0x7F,
    }
end

local function sendParamChange(exId, paramId, signedVal)
    local dev = preset.getDevice(DEVICE_ID)
    local body = buildParamChangeBody(exId, paramId, signedVal)
    if dev then
        dev:sendSysex(body)
    else
        midi.sendSysex(PORT_1, body)
    end
end

-- ============================================================================
-- 4. Control Callbacks & Lifecycle Hooks
-- ============================================================================

function onSubNoiseParam(valueObject, value)
    local ctrlId = valueObject:getControl():getId()
    local spec = SUB_NOISE_MAP[ctrlId]
    if not spec then
        return
    end
    local v = math.floor(value)
    local z1Val = v
    if spec.kind == "list" then
        local ov = overlays.get(spec.ov)
        z1Val = (ov and ov:getValueByIndex(v)) or v
    end
    sendParamChange(0, spec.id, z1Val)
end

function preset.onLoad()
    for ovId, items in pairs(ENUM_DEFS) do
        overlays.create(ovId, items)
    end
end

function preset.onReady()
    for cid, spec in pairs(SUB_NOISE_MAP) do
        if spec.kind == "list" then
            controls.get(cid):getValue("value"):setOverlayId(spec.ov)
        end
    end
    info.setText("Z1 Sub/Noise/Common Ready")
end
