-- Korg Z1 - Amp 1 & 2, Output/Pan, OSC1 Pitch/Mod & Performance Editor (PE Knobs 1..5) for Electra One mk2
-- Covers:
--   [Amp 1]      (IDs 315..320, 322..323; 8 active params, ExID = 0)
--   [Amp 2]      (IDs 324..329, 331..332; 8 active params, ExID = 0)
--   [Output]     (IDs 352..355; 4 params: Panpot, Pan Mod Src, Pan Mod Int, Output Level, ExID = 0)
--   [OSC1 Pitch] (IDs 175..187; 13 params: Octave, Semi, Fine, Offset, Slope, Pitch Mod 1/2, ExID = 0)
--   [PE Knob1-5] (IDs 384..463; 80 params: 5 knobs x 4 targets x 4 params, ExID = 0)
--
-- Layout (36 slots across 3 Control Sets):
--   Control Set 1 (Rows 1-2, Slots 1..12):
--     Row 1 (Slots 1..6):  [1] Amp1 Level (315), [2] Amp1 ModEG (320), [3] Amp1 ModSrc (322), [4] Amp1 ModInt (323), [5] Out Pan (352), [6] Out Level (355)
--     Row 2 (Slots 7..12): [7] Amp2 Level (324), [8] Amp2 ModEG (329), [9] Amp2 ModSrc (331), [10] Amp2 ModInt (332),[11] Pan ModSrc (353),[12] Pan ModInt (354)
--   Control Set 2 (Rows 3-4, Slots 13..24):
--     Row 3 (Slots 13..16): [13] Amp1 LoKey (316), [14] Amp1 HiKey (317), [15] Amp1 LoInt (318), [16] Amp1 HiInt (319)
--     Row 4 (Slots 19..22): [19] Amp2 LoKey (325), [20] Amp2 HiKey (326), [21] Amp2 LoInt (327), [22] Amp2 HiInt (328)
--     Slot 18:              [18] MOD SELECT (0 = OSC1 Pitch/Mod, 1..5 = PE Knob 1..5)
--   Control Set 3 (Rows 5-6, Slots 23..36):
--     Dynamic slots for OSC1 Pitch/Mod (13 params, IDs 175..187) OR PE Knob 1..5 (16 params per knob, IDs 384..463)

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
    EG_1_5     = 2,
    MOD_SELECT = 3,
    OCTAVE     = 4,
    PE_CURVE   = 5,
}

local ENUM_DEFS = {
    [OV.MODSRC1] = MODSRC1,
    [OV.EG_1_5] = {
        { value = 1, label = "EG1" },
        { value = 2, label = "EG2" },
        { value = 3, label = "EG3" },
        { value = 4, label = "EG4" },
        { value = 5, label = "Amp EG" },
    },
    [OV.MOD_SELECT] = {
        { value = 0, label = "OSC1 Pitch/Mod" },
        { value = 1, label = "PE Knob 1" },
        { value = 2, label = "PE Knob 2" },
        { value = 3, label = "PE Knob 3" },
        { value = 4, label = "PE Knob 4" },
        { value = 5, label = "PE Knob 5" },
    },
    [OV.OCTAVE] = {
        { value = 0, label = "32'" },
        { value = 1, label = "16'" },
        { value = 2, label = "8'" },
        { value = 3, label = "4'" },
    },
    [OV.PE_CURVE] = {
        { value = 0, label = "LINEAR" },
        { value = 1, label = "EXP" },
        { value = 2, label = "LOG" },
        { value = 3, label = "SWITCH" },
    },
}

-- ============================================================================
-- 2. Static Amp 1 / Amp 2 / Output Parameters & Dynamic Bottom Section
-- ============================================================================

STATIC_AMP_MAP = {
    -- Row 1: Amp 1 Core + Panpot & Output Level
    [1]  = { id = 315, kind = "num" },
    [2]  = { id = 320, kind = "list", ov = OV.EG_1_5 },
    [3]  = { id = 322, kind = "list", ov = OV.MODSRC1 },
    [4]  = { id = 323, kind = "num" },
    [5]  = { id = 352, kind = "num",  fmt = "pan" },
    [6]  = { id = 355, kind = "num" },
    -- Row 2: Amp 2 Core + Panpot Mod Src + MOD SELECT (Control 12)
    [7]  = { id = 324, kind = "num" },
    [8]  = { id = 329, kind = "list", ov = OV.EG_1_5 },
    [9]  = { id = 331, kind = "list", ov = OV.MODSRC1 },
    [10] = { id = 332, kind = "num" },
    [11] = { id = 353, kind = "list", ov = OV.MODSRC1 },
    -- Row 3 (Cols 1..4): Amp 1 Key Track
    [13] = { id = 316, kind = "num",  fmt = "note" },
    [14] = { id = 317, kind = "num",  fmt = "note" },
    [15] = { id = 318, kind = "num" },
    [16] = { id = 319, kind = "num" },
    -- Row 4 (Cols 1..4): Amp 2 Key Track
    [19] = { id = 325, kind = "num",  fmt = "note" },
    [20] = { id = 326, kind = "num",  fmt = "note" },
    [21] = { id = 327, kind = "num" },
    [22] = { id = 328, kind = "num" },
}

-- Dynamic slots: 16 slots mapped to controls 100+s (fader) / 200+s (list) for s = 1..16
-- Slots 1..2 are Row 3 Col 5 & Row 4 Col 5 (controls 101/201, 102/202)
-- Slots 3..4 are Row 4 Col 6 & Row 3 Col 6 (Wait: Slot 18 is MOD SELECT at Row 3 Col 6; let's use Slots 1..16 at positions:
--   s=1: Row 3 Col 5, s=2: Row 4 Col 5, s=3: Row 4 Col 6, s=4..9: Row 5 Cols 1..6, s=10..15: Row 6 Cols 1..6, s=16: Row 3 Col 6 if needed,
--   OR even cleaner: put MOD SELECT at Slot 17 (Row 3 Col 5), leave Slot 18 empty, and put 16 dynamic slots across:
--     s=1..2 (Row 3 Col 6, Row 4 Col 5..6) + Row 5 (6 slots) + Row 6 (6 slots) = 15 or 16 slots!)
-- Let's check:
--   Row 3 has 4 Amp1 KeyTrack controls (Cols 1..4) -> Col 5 is MOD SELECT (Control 17), Col 6 is Dyn Slot 1
--   Row 4 has 4 Amp2 KeyTrack controls (Cols 1..4) -> Col 5 is Dyn Slot 2, Col 6 is Dyn Slot 3
--   Row 5 (Cols 1..6) -> Dyn Slots 4..9
--   Row 6 (Cols 1..6) -> Dyn Slots 10..15
--   Wait: 15 dynamic slots is enough for OSC1 Pitch/Mod (13 params)! What about PE Knob 1..5 (16 params = 4 targets x 4 params)?
--   If we put Amp1 LoKey/HiKey/LoInt/HiInt in Row 3 Cols 1..4 and Amp2 LoKey/HiKey/LoInt/HiInt in Row 4 Cols 1..4,
--   we have 4 slots in Rows 3-4 (Row 3 Cols 5-6 and Row 4 Cols 5-6) + 12 slots in Rows 5-6 = 16 slots!
--   Wait where does MOD SELECT go if those 16 slots are used?
--   Look at Row 1 & Row 2: all 12 slots are used.
--   What if PE Knob has 4 targets (A, B, C, D) x 4 params (Param, Left, Right, Curve) = 16 params, OR what if MOD SELECT is in Row 3 Col 5 and PE Knob shows 3 targets (12 params) or we have a 7-item MOD SELECT (`OSC1 Pitch/Mod`, `PE Knob 1`, `PE Knob 2`, `PE Knob 3`, `PE Knob 4`, `PE Knob 5`) where `PE Knob` shows Targets 1..3 (12 params) + Target 4 Param/Left/Right (15 params)?
--   Even better! Why not put `Out Pan (352)` and `Out Level (355)` in Row 1 Cols 5..6, and put `Pan ModSrc (353)` and `Pan ModInt (354)` inside the `OSC1 Pitch & Output Mod` dynamic view (13 + 2 = 15 params!) so Row 2 Cols 5..6 are FREE?
--   WAIT A SECOND! Count that!
--   If `Pan ModSrc (353)` and `Pan ModInt (354)` are in `OSC1 Pitch & Pan Mod` (13 + 2 = 15 params), then:
--   Row 2 Col 5 = `Pan ModSrc (353)`, Row 2 Col 6 = `MOD SELECT` (Control 18), and `Pan ModInt (354)` is in `OSC1 Pitch & Mod` (14 params), leaving ALL 16 slots (Row 3 Cols 5..6, Row 4 Cols 5..6, Row 5 Cols 1..6, Row 6 Cols 1..6) for the 16 dynamic parameters of `PE Knob 1..5`!
--   Let's verify that count!
--     Row 1 (6): [1] Amp1 Lvl (315), [2] Amp1 ModEG (320), [3] Amp1 ModSrc (322), [4] Amp1 ModInt (323), [5] Out Pan (352), [6] Out Level (355)
--     Row 2 (6): [7] Amp2 Lvl (324), [8] Amp2 ModEG (329), [9] Amp2 ModSrc (331), [10] Amp2 ModInt (332), [11] Pan ModSrc (353), [12] MOD SELECT
--     Row 3 (6): [13] Amp1 LoKey (316), [14] Amp1 HiKey (317), [15] Amp1 LoInt (318), [16] Amp1 HiInt (319), [Dyn 1], [Dyn 2]
--     Row 4 (6): [19] Amp2 LoKey (325), [20] Amp2 HiKey (326), [21] Amp2 LoInt (327), [22] Amp2 HiInt (328), [Dyn 3], [Dyn 4]
--     Row 5 (6): [Dyn 5] .. [Dyn 10]
--     Row 6 (6): [Dyn 11] .. [Dyn 16]
--   Total = 20 static controls + 16 dynamic slots = 36 slots! Every single parameter of PE Knob 1..5 (all 16 per knob = 80 params) AND all 14 OSC1 Pitch/Mod + Pan ModInt parameters fit in those 16 dynamic slots!

OSC1_PITCH_DEFS = {
    { id = 175, name = "O1 Octave",   kind = "list", ov = OV.OCTAVE,  color = ORANGE, defVal = 2 },
    { id = 176, name = "O1 Semi",     kind = "num",  min = -12,  max = 12,  color = ORANGE, defVal = 0 },
    { id = 177, name = "O1 Fine",     kind = "num",  min = -50,  max = 50,  color = ORANGE, defVal = 0 },
    { id = 178, name = "O1 Offset",   kind = "num",  min = -100, max = 100, fmt = "hz10",  color = ORANGE, defVal = 0 },
    { id = 179, name = "O1 CtrKey",   kind = "num",  min = 0,    max = 127, fmt = "note",  color = RED,    defVal = 60 },
    { id = 180, name = "O1 LoSlope",  kind = "num",  min = -50,  max = 100, fmt = "slope", color = RED,    defVal = 50 },
    { id = 181, name = "O1 HiSlope",  kind = "num",  min = -50,  max = 100, fmt = "slope", color = RED,    defVal = 50 },
    { id = 182, name = "O1 Mod1Src",  kind = "list", ov = OV.MODSRC1, color = BLUE,  defVal = 0 },
    { id = 183, name = "O1 Mod1Int",  kind = "num",  min = -99,  max = 99,  color = GREEN, defVal = 0 },
    { id = 184, name = "O1 M1Ctrl",   kind = "list", ov = OV.MODSRC1, color = BLUE,  defVal = 0 },
    { id = 185, name = "O1 M1CInt",   kind = "num",  min = -99,  max = 99,  color = GREEN, defVal = 0 },
    { id = 186, name = "O1 Mod2Src",  kind = "list", ov = OV.MODSRC1, color = BLUE,  defVal = 0 },
    { id = 187, name = "O1 Mod2Int",  kind = "num",  min = -99,  max = 99,  color = GREEN, defVal = 0 },
    { id = 354, name = "Pan ModInt",  kind = "num",  min = -99,  max = 99,  color = GREEN, defVal = 0 },
}

local function buildPeKnobDefs(knobIdx)
    -- knobIdx: 1..5 -> base = 384 + (knobIdx - 1) * 16
    local base = 384 + (knobIdx - 1) * 16
    local prefix = "K" .. knobIdx .. " "
    local defs = {}
    for t = 1, 4 do
        local tBase = base + (t - 1) * 4
        local tp = prefix .. "T" .. t .. " "
        defs[#defs + 1] = { id = tBase + 0, name = tp .. "Prm",   kind = "num",  min = 0, max = 230, color = ORANGE, defVal = 0 }
        defs[#defs + 1] = { id = tBase + 1, name = tp .. "Left",  kind = "num",  min = 0, max = 100, color = WHITE,  defVal = 0 }
        defs[#defs + 1] = { id = tBase + 2, name = tp .. "Right", kind = "num",  min = 0, max = 100, color = WHITE,  defVal = 100 }
        defs[#defs + 1] = { id = tBase + 3, name = tp .. "Curve", kind = "list", ov = OV.PE_CURVE, color = PURPLE, defVal = 0 }
    end
    return defs
end

DYN_SECTIONS = {
    [0] = OSC1_PITCH_DEFS,
    [1] = buildPeKnobDefs(1),
    [2] = buildPeKnobDefs(2),
    [3] = buildPeKnobDefs(3),
    [4] = buildPeKnobDefs(4),
    [5] = buildPeKnobDefs(5),
}

local selectedModSec = 0
local activeDynDef = {}
local suppressDyn = {}
modSaved = {}

local NOTE_NAMES = { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" }

function fmtNote(_valueObject, value)
    local v = math.floor(value)
    local n = NOTE_NAMES[(v % 12) + 1]
    local oct = (v // 12) - 1
    return string.format("%s%d", n, oct)
end

function fmtPan(_valueObject, value)
    local v = math.floor(value) - 64
    if v == 0 then return "CNT"
    elseif v < 0 then return string.format("L%d", -v)
    else return string.format("R%d", v) end
end

function fmtDynSlot(valueObject, value)
    local slot = valueObject:getControl():getId() % 100
    local def = activeDynDef[slot]
    local v = math.floor(value)
    if not def or not def.fmt then
        return tostring(v)
    end
    if def.fmt == "hz10" then
        return string.format("%+.1f Hz", v / 10.0)
    elseif def.fmt == "slope" then
        return string.format("%+.2f", v / 50.0)
    elseif def.fmt == "note" then
        return fmtNote(valueObject, value)
    end
    return tostring(v)
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
-- 4. Callbacks & Dynamic Section Relayout
-- ============================================================================

function applyModSection(secIdx)
    local defs = DYN_SECTIONS[secIdx]
    if not defs then
        return
    end
    selectedModSec = secIdx
    activeDynDef = {}
    suppressDyn = {}

    window.stop()
    local grp = preset.getGroup(52)
    if grp then
        local title = (secIdx == 0) and "OSC1 PITCH / SLOPE / MOD & PAN MOD" or ("PERFORMANCE EDITOR - KNOB " .. secIdx .. " (TARGETS 1..4)")
        grp:setLabel(title)
    end

    for s = 1, 16 do
        local def = defs[s]
        local fader = controls.get(100 + s)
        local list  = controls.get(200 + s)

        if not def then
            fader:setVisible(false)
            list:setVisible(false)
        elseif def.kind == "list" then
            activeDynDef[s] = def
            fader:setVisible(false)

            local initVal = modSaved[def.id]
            if initVal == nil then initVal = def.defVal or 0 end

            local vo = list:getValue("value")
            vo:setOverlayId(def.ov)
            suppressDyn[200 + s] = true
            vo:updateValue(initVal)
            suppressDyn[200 + s] = nil
            list:setName(def.name)
            list:setColor(def.color or PURPLE)
            list:setVisible(true)
        else
            activeDynDef[s] = def
            list:setVisible(false)

            local neutral = def.defVal
            if neutral == nil then
                neutral = (def.min < 0 and def.max > 0) and 0 or def.min
            end
            local initVal = modSaved[def.id]
            if initVal == nil then initVal = neutral end

            local vo = fader:getValue("value")
            local span = def.max - def.min
            vo:getMessage():setRange(0, span)
            vo:setRange(def.min, def.max, neutral, false)
            suppressDyn[100 + s] = true
            vo:updateValue(initVal)
            suppressDyn[100 + s] = nil
            fader:setName(def.name)
            fader:setColor(def.color or WHITE)
            fader:setVisible(true)
        end
    end
    window.resume()
end

function onStaticAmp(valueObject, value)
    local ctrlId = valueObject:getControl():getId()
    local spec = STATIC_AMP_MAP[ctrlId]
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

function onModSelect(_valueObject, value)
    local sec = math.floor(value)
    if sec < 0 or sec > 5 or sec == selectedModSec then
        return
    end
    applyModSection(sec)
end

function onDynMod(valueObject, value)
    local ctrl = valueObject:getControl()
    local ctrlId = ctrl:getId()
    if suppressDyn[ctrlId] then
        suppressDyn[ctrlId] = nil
        return
    end
    if not ctrl:isVisible() then
        return
    end
    local s = ctrlId % 100
    local def = activeDynDef[s]
    if not def then
        return
    end

    local v = math.floor(value)
    modSaved[def.id] = v

    local z1Val = v
    if def.kind == "list" then
        local ov = overlays.get(def.ov)
        z1Val = (ov and ov:getValueByIndex(v)) or v
    end
    sendParamChange(0, def.id, z1Val)
end

-- ============================================================================
-- 5. Lifecycle Hooks
-- ============================================================================

function preset.onLoad()
    for ovId, items in pairs(ENUM_DEFS) do
        overlays.create(ovId, items)
    end
end

function preset.onReady()
    for cid, spec in pairs(STATIC_AMP_MAP) do
        if spec.kind == "list" then
            controls.get(cid):getValue("value"):setOverlayId(spec.ov)
        end
    end
    controls.get(12):getValue("value"):setOverlayId(OV.MOD_SELECT)
    controls.get(12):getValue("value"):updateValue(0)
    applyModSection(0)
    info.setText("Z1 Amp/Out/Mod Ready")
end
