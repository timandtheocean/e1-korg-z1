-- Korg Z1 - Envelopes (EG1..EG4 & Amp EG) for Electra One mk2
-- Uses 5 dx7envelope widgets (8 curve params each) + Start Level faders
-- + Reveal Modulations toggle & EG Target selector for the 10 Mod params per EG.

local DEVICE_ID = 1

local function getGlobalChannel()
    local dev = preset.getDevice(DEVICE_ID)
    if dev then
        return (dev:getChannel() - 1) & 0x0F
    end
    return 0
end

-- ============================================================================
-- 1. Modulation Source List 1 (49 entries, 0..48) & EG Selector List
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

EG_TARGETS = {
    { value = 0, label = "EG 1" },
    { value = 1, label = "EG 2" },
    { value = 2, label = "EG 3" },
    { value = 3, label = "EG 4" },
}

local OV_EG_TARGET = 1
local OV_MODSRC1   = 2

-- ============================================================================
-- 2. Z1 Envelope Parameter Table (IDs from PROG_PRM.TXT, ExID = 0)
-- ============================================================================
-- Each EG has 9 curve parameters + 10 modulation parameters:
-- Curve: start, r1(AtkTime), l1(AtkLvl), r2(DcyTime), l2(BrkLvl), r3(SlpTime), l3(SusLvl), r4(RlsTime), l4(RlsLvl)
-- Mod:   [1]=LvlModSrc, [2]=LvlModInt, [3]=LvlVel, [4]=TimeModSrc, [5]=TimeModInt,
--        [6]=NodeModSrc, [7]=AtkModInt, [8]=DcyModInt, [9]=SlpModInt, [10]=RlsModInt

EGS = {
    -- 0: EG1 (IDs 31..49)
    [0] = {
        name = "EG1",
        isAmp = false,
        curve = { start = 31, r1 = 32, l1 = 33, r2 = 34, l2 = 35, r3 = 36, l3 = 37, r4 = 38, l4 = 39 },
        mod   = { 40, 41, 42, 43, 44, 45, 46, 47, 48, 49 },
    },
    -- 1: EG2 (IDs 50..68)
    [1] = {
        name = "EG2",
        isAmp = false,
        curve = { start = 50, r1 = 51, l1 = 52, r2 = 53, l2 = 54, r3 = 55, l3 = 56, r4 = 57, l4 = 58 },
        mod   = { 59, 60, 61, 62, 63, 64, 65, 66, 67, 68 },
    },
    -- 2: EG3 (IDs 69..87)
    [2] = {
        name = "EG3",
        isAmp = false,
        curve = { start = 69, r1 = 70, l1 = 71, r2 = 72, l2 = 73, r3 = 74, l3 = 75, r4 = 76, l4 = 77 },
        mod   = { 78, 79, 80, 81, 82, 83, 84, 85, 86, 87 },
    },
    -- 3: EG4 (IDs 88..106)
    [3] = {
        name = "EG4",
        isAmp = false,
        curve = { start = 88, r1 = 89, l1 = 90, r2 = 91, l2 = 92, r3 = 93, l3 = 94, r4 = 95, l4 = 96 },
        mod   = { 97, 98, 99, 100, 101, 102, 103, 104, 105, 106 },
    },
    -- 4: Amp EG (IDs 334..351; 333 Start and 341 Release Level are reserved on Z1)
    [4] = {
        name = "Amp EG",
        isAmp = true,
        curve = { start = nil, r1 = 334, l1 = 335, r2 = 336, l2 = 337, r3 = 338, l3 = 339, r4 = 340, l4 = nil },
        mod   = { 342, 343, 344, 345, 346, 347, 348, 349, 350, 351 },
    },
}

local MOD_LABELS = {
    { short = "Lvl Src",  kind = "list" },
    { short = "Lvl Int",  kind = "num"  },
    { short = "Velocity", kind = "num"  },
    { short = "Time Src", kind = "list" },
    { short = "Time Int", kind = "num"  },
    { short = "Node Src", kind = "list" },
    { short = "Atk Mod",  kind = "num"  },
    { short = "Dcy Mod",  kind = "num"  },
    { short = "Slp Mod",  kind = "num"  },
    { short = "Rls Mod",  kind = "num"  },
}

-- Control IDs in preset.json:
-- 1..5:   dx7envelope widgets for EG1..EG4, Amp EG (Slots 1..5)
-- 11..14: Start Level faders for EG1..EG4 (Slots 7..10)
-- 21..30: Amp EG Modulations (Slots 13..22, Control Set 2 - always visible, dedicated to Amp EG)
-- 20:     EG 1..4 Selector list (Slot 25, Control Set 3)
-- 31..40: EG 1..4 Modulations (Slots 26..35, Control Set 3 - always visible, switches between EG1..EG4)

local selectedEg = 0

-- Per-EG saved modulation values in memory so switching EG1..EG4 restores each EG's values
egModValues = {
    [0] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    [1] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    [2] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    [3] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    [4] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
}

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
-- 4. Callbacks for Envelopes, Start Levels, Amp EG Mod & EG 1..4 Mod
-- ============================================================================

-- Callback for dx7envelope controls 1..5 (handles l1, r1, l2, r2, l3, r3, l4, r4)
function onEnvHandle(valueObject, value)
    local ctrlId = valueObject:getControl():getId()
    local egIdx = ctrlId - 1
    local eg = EGS[egIdx]
    if not eg then
        return
    end
    local handleId = valueObject:getId()
    local paramId = eg.curve[handleId]
    if not paramId then
        return -- e.g. Amp EG l4 (Release Level is fixed at 0 on Z1)
    end
    sendParamChange(0, paramId, math.floor(value))
end

-- Callback for Start Level faders 11..14 (EG1..EG4)
function onStartLevel(valueObject, value)
    local ctrlId = valueObject:getControl():getId()
    local egIdx = ctrlId - 11
    local eg = EGS[egIdx]
    if not eg or not eg.curve.start then
        return
    end
    sendParamChange(0, eg.curve.start, math.floor(value))
end

-- Callback for dedicated Amp EG Modulation controls 21..30 (middle section, Control Set 2)
function onAmpEgMod(valueObject, value)
    local ctrl = valueObject:getControl()
    local idx = ctrl:getId() - 20
    local eg = EGS[4]
    if not eg or not eg.mod[idx] then
        return
    end

    local v = math.floor(value)
    egModValues[4][idx] = v

    local paramId = eg.mod[idx]
    local z1Val
    if MOD_LABELS[idx].kind == "list" then
        local ov = overlays.get(OV_MODSRC1)
        z1Val = (ov and ov:getValueByIndex(v)) or v
    else
        z1Val = v
    end
    sendParamChange(0, paramId, z1Val)
end

-- Update labels and restore saved values for the 10 EG 1..4 Modulation controls (IDs 31..40)
function updateEgModControls()
    local eg = EGS[selectedEg]
    if not eg then
        return
    end
    local saved = egModValues[selectedEg]

    window.stop()
    local modGrp = preset.getGroup(52)
    if modGrp then
        modGrp:setLabel(eg.name .. " MODULATIONS")
    end

    for i = 1, 10 do
        local ctrlId = 30 + i
        local ctrl = controls.get(ctrlId)
        local valObj = ctrl:getValue("value")
        local targetVal = saved[i] or 0

        ctrl:setName(eg.name .. " " .. MOD_LABELS[i].short)
        valObj:updateValue(targetVal)
    end
    window.resume()
end

-- Callback for Control 20: EG 1..4 Target selector (0..3)
function onEgSelect(valueObject, value)
    local newEg = math.floor(value)
    if newEg < 0 or newEg > 3 or newEg == selectedEg then
        return
    end
    selectedEg = newEg
    updateEgModControls()
    info.setText("Editing " .. EGS[selectedEg].name .. " Mod")
end

-- Callback for Controls 31..40 (bottom section, Control Set 3: EG 1..4 Modulations)
function onEgMod(valueObject, value)
    local ctrl = valueObject:getControl()
    local idx = ctrl:getId() - 30
    local eg = EGS[selectedEg]
    if not eg or not eg.mod[idx] then
        return
    end

    local v = math.floor(value)
    egModValues[selectedEg][idx] = v

    local paramId = eg.mod[idx]
    local z1Val
    if MOD_LABELS[idx].kind == "list" then
        local ov = overlays.get(OV_MODSRC1)
        z1Val = (ov and ov:getValueByIndex(v)) or v
    else
        z1Val = v
    end
    sendParamChange(0, paramId, z1Val)
end

-- ============================================================================
-- 5. Lifecycle Hooks
-- ============================================================================

function preset.onLoad()
    overlays.create(OV_EG_TARGET, EG_TARGETS)
    overlays.create(OV_MODSRC1, MODSRC1)
end

function preset.onReady()
    controls.get(20):getValue("value"):setOverlayId(OV_EG_TARGET)
    for i = 1, 10 do
        if MOD_LABELS[i].kind == "list" then
            controls.get(20 + i):getValue("value"):setOverlayId(OV_MODSRC1)
            controls.get(30 + i):getValue("value"):setOverlayId(OV_MODSRC1)
        end
    end
    info.setText("Z1 Envelopes Ready")
end
