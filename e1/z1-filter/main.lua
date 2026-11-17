-- Korg Z1 - Filter 1 & 2 + Dynamic Assigned Cutoff EG for Electra One mk2
-- Control Set 1 (Rows 1-2, Slots 1..12): Routing, Link, Assigned Cutoff EG (dx7envelope + Start Level), Filter 1 & 2 Type/Trim/Cutoff/Reso
-- Control Set 2 (Rows 3-4, Slots 13..24): Filter Select (Filter 1 / Filter 2) + Cutoff/Resonance Modulations & Key Track
-- Control Set 3 (Rows 5-6, Slots 26..36): Dual-Bandpass (2BPF) Filter-B parameters - ONLY visible when selected Filter Type == 2BPF!

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
    ROUTING    = 1,
    MODSRC1    = 2,
    EG_TARGET  = 3,
    FLT_TYPE   = 4,
    EG_1_5     = 5,
    FLT_SELECT = 6,
}

local ENUM_DEFS = {
    [OV.ROUTING] = {
        { value = 0, label = "SERIAL 1" },
        { value = 1, label = "SERIAL 2" },
        { value = 2, label = "PARALLEL" },
    },
    [OV.MODSRC1] = MODSRC1,
    [OV.EG_TARGET] = {
        { value = 1, label = "FLT 1" },
        { value = 2, label = "FLT 2" },
        { value = 3, label = "FLT 1&2" },
    },
    [OV.FLT_TYPE] = {
        { value = 1, label = "LPF" },
        { value = 2, label = "HPF" },
        { value = 3, label = "BPF" },
        { value = 4, label = "BRF" },
        { value = 5, label = "2BPF" },
    },
    [OV.EG_1_5] = {
        { value = 1, label = "EG1" },
        { value = 2, label = "EG2" },
        { value = 3, label = "EG3" },
        { value = 4, label = "EG4" },
        { value = 5, label = "Amp EG" },
    },
    [OV.FLT_SELECT] = {
        { value = 0, label = "Filter 1" },
        { value = 1, label = "Filter 2" },
    },
}

-- ============================================================================
-- 2. Parameter Mapping (PROG_PRM.TXT, ExID = 0)
-- ============================================================================

-- All 5 Envelope Generators that can be assigned to Filter Cutoff Mod EG (Z1 values 1..5):
-- 1=EG1 (31..39), 2=EG2 (50..58), 3=EG3 (69..77), 4=EG4 (88..96), 5=Amp EG (334..340)
EGS = {
    [1] = { name = "EG1",    isAmp = false, curve = { start = 31,  r1 = 32,  l1 = 33,  r2 = 34,  l2 = 35,  r3 = 36,  l3 = 37,  r4 = 38,  l4 = 39  } },
    [2] = { name = "EG2",    isAmp = false, curve = { start = 50,  r1 = 51,  l1 = 52,  r2 = 53,  l2 = 54,  r3 = 55,  l3 = 56,  r4 = 57,  l4 = 58  } },
    [3] = { name = "EG3",    isAmp = false, curve = { start = 69,  r1 = 70,  l1 = 71,  r2 = 72,  l2 = 73,  r3 = 74,  l3 = 75,  r4 = 76,  l4 = 77  } },
    [4] = { name = "EG4",    isAmp = false, curve = { start = 88,  r1 = 89,  l1 = 90,  r2 = 91,  l2 = 92,  r3 = 93,  l3 = 94,  r4 = 95,  l4 = 96  } },
    [5] = { name = "Amp EG", isAmp = true,  curve = { start = nil, r1 = 334, l1 = 335, r2 = 336, l2 = 337, r3 = 338, l3 = 339, r4 = 340, l4 = nil } },
}

local HANDLES = { "l1", "r1", "l2", "r2", "l3", "r3", "l4", "r4" }

-- Saved curve values per EG (1..5) in memory (shared with z1-eg so edits on either page stay in sync)
egCurveSaved = _G.egCurveSaved or {}
_G.egCurveSaved = egCurveSaved
for egId = 1, 5 do
    local isAmp = EGS[egId].isAmp
    if not egCurveSaved[egId] then
        egCurveSaved[egId] = {
            start = 0,
            l1 = isAmp and 99 or 0, r1 = 0,
            l2 = isAmp and 99 or 0, r2 = 0,
            l3 = isAmp and 99 or 0, r3 = 0,
            l4 = 0,                 r4 = 0,
        }
    end
end

-- Track Filter 1 & Filter 2 Type (0..4 index -> 1..5 Z1 value; index 4 = 2BPF)
fltTypeIdx = { [0] = 0, [1] = 0 }

-- Static top-section parameters (Control IDs -> Z1 Parameter IDs)
local STATIC_PARAMS = {
    [1]  = { id = 258, kind = "list", ov = OV.ROUTING },   -- Filter Routing (0..2)
    [2]  = { id = 259, kind = "num" },                     -- Filter2 Link SW (0/1)
    [3]  = { id = 260, kind = "list", ov = OV.EG_TARGET }, -- Filter EG Knob's Target (1..3)
    [6]  = { id = 261, kind = "list", ov = OV.FLT_TYPE, flt = 0 }, -- Filter 1 Type (1..5)
    [7]  = { id = 262, kind = "num" },                     -- Filter 1 Input Trim (0..99)
    [10] = { id = 288, kind = "list", ov = OV.FLT_TYPE, flt = 1 }, -- Filter 2 Type (1..5)
    [11] = { id = 289, kind = "num" },                     -- Filter 2 Input Trim (0..99)
}

-- Combined 2-slot Cutoff + Resonance Filter Graph widgets (Control 8 = Filter 1, Control 12 = Filter 2)
local FILTER_GRAPH_PARAMS = {
    [8]  = { flt = 0, label = "F1", cutoff = { id = 263, def = 50 }, resonance = { id = 274, def = 0 } },
    [12] = { flt = 1, label = "F2", cutoff = { id = 290, def = 50 }, resonance = { id = 301, def = 0 } },
}
local FLT_TYPE_NAMES = { [0] = "LPF", [1] = "HPF", [2] = "BPF", [3] = "BRF", [4] = "2BPF" }
local FLT_GRAPH_STEP = 4

-- Per-Filter Dynamic Parameters (Filter 1 base = 264, Filter 2 base = 291; offset +27)
-- Controls 21..32: Cutoff/Reso Mod & Key Track (always visible for selected Filter 1 / Filter 2)
-- Controls 33..43: Filter-B (2BPF) parameters (ONLY visible when selected filter's Type == 2BPF!)
local DYN_DEFS = {
    -- Cutoff/Resonance Mod & Key Track (Control IDs 21..32, Slots 14..25)
    [21] = { f1 = 268, f2 = 295, short = "Cut ModEG",  kind = "list", ov = OV.EG_1_5,  defVal = 2 }, -- default index 2 = EG3 (Z1 value 3)
    [22] = { f1 = 269, f2 = 296, short = "Cut EG Int", kind = "num",  defVal = 0 },
    [23] = { f1 = 270, f2 = 297, short = "Cut Src1",   kind = "list", ov = OV.MODSRC1, defVal = 0 },
    [24] = { f1 = 271, f2 = 298, short = "Cut Int1",   kind = "num",  defVal = 0 },
    [25] = { f1 = 272, f2 = 299, short = "Cut Src2",   kind = "list", ov = OV.MODSRC1, defVal = 0 },
    [26] = { f1 = 273, f2 = 300, short = "Cut Int2",   kind = "num",  defVal = 0 },
    [27] = { f1 = 275, f2 = 302, short = "Reso Src",   kind = "list", ov = OV.MODSRC1, defVal = 0 },
    [28] = { f1 = 276, f2 = 303, short = "Reso Int",   kind = "num",  defVal = 0 },
    [29] = { f1 = 264, f2 = 291, short = "Trk LoKey",  kind = "num",  fmt = "note",    defVal = 60 },
    [30] = { f1 = 265, f2 = 292, short = "Trk HiKey",  kind = "num",  fmt = "note",    defVal = 60 },
    [31] = { f1 = 266, f2 = 293, short = "Trk LoInt",  kind = "num",  defVal = 0 },
    [32] = { f1 = 267, f2 = 294, short = "Trk HiInt",  kind = "num",  defVal = 0 },
    -- Filter-B (2BPF second bandpass peak) (Control IDs 33..43, Slots 26..36; hidden unless Type == 2BPF)
    [33] = { f1 = 277, f2 = 304, short = "2BPF TrimB",  kind = "num",  defVal = 0,  isB = true },
    [34] = { f1 = 278, f2 = 305, short = "2BPF CutB",   kind = "num",  defVal = 50, isB = true },
    [35] = { f1 = 286, f2 = 313, short = "2BPF ResoB",  kind = "num",  defVal = 0,  isB = true },
    [36] = { f1 = 279, f2 = 306, short = "2BPF LoKey",  kind = "num",  fmt = "note", defVal = 60, isB = true },
    [37] = { f1 = 280, f2 = 307, short = "2BPF HiKey",  kind = "num",  fmt = "note", defVal = 60, isB = true },
    [38] = { f1 = 281, f2 = 308, short = "2BPF LoInt",  kind = "num",  defVal = 0,  isB = true },
    [39] = { f1 = 282, f2 = 309, short = "2BPF HiInt",  kind = "num",  defVal = 0,  isB = true },
    [40] = { f1 = 283, f2 = 310, short = "2BPF EGInt",  kind = "num",  defVal = 0,  isB = true },
    [41] = { f1 = 284, f2 = 311, short = "2BPF Mod1",   kind = "num",  defVal = 0,  isB = true },
    [42] = { f1 = 285, f2 = 312, short = "2BPF Mod2",   kind = "num",  defVal = 0,  isB = true },
    [43] = { f1 = 287, f2 = 314, short = "2BPF ResMd",  kind = "num",  defVal = 0,  isB = true },
}

local selectedFlt = 0 -- 0 = Filter 1, 1 = Filter 2
local ready = false
local suppressDyn = {}

-- Per-Filter saved values in memory for controls 21..43
fltSavedValues = {
    [0] = {},
    [1] = {},
}
for cid, def in pairs(DYN_DEFS) do
    fltSavedValues[0][cid] = def.defVal
    fltSavedValues[1][cid] = def.defVal
end

local NOTE_NAMES = { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" }

function fmtNote(valueObject, value)
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
-- 4. Callbacks & Dynamic Assigned EG / 2BPF Updates
-- ============================================================================

-- Return the Z1 EG ID (1..5: EG1..EG4, Amp EG) currently assigned to the selected filter's Cutoff Mod EG
function getActiveFilterEgId()
    local egIdx = fltSavedValues[selectedFlt][21]
    if not egIdx or egIdx < 0 or egIdx > 4 then
        egIdx = 2 -- default index 2 = EG3
    end
    return egIdx + 1 -- 1..5
end

-- Update Control 4 (dx7envelope) and Control 5 (Start Level) to show & control the EG assigned to the active filter's Cutoff
function updateAssignedEgWidget(restoreValues)
    local egId = getActiveFilterEgId()
    local eg   = EGS[egId]
    if not eg then
        return
    end
    local fltPrefix = (selectedFlt == 0) and "F1 " or "F2 "
    local saved = egCurveSaved[egId]
    local envCtrl = controls.get(4)
    local startCtrl = controls.get(5)

    envCtrl:setName(fltPrefix .. eg.name)
    envCtrl:setColor(eg.isAmp and RED or BLUE)

    local lmin = eg.isAmp and 0 or -99
    if restoreValues then
        for _, h in ipairs({ "l1", "l2", "l3", "l4" }) do
            local vo = envCtrl:getValue(h)
            if vo then
                vo:getMessage():setRange(0, 99 - lmin)
                vo:setRange(lmin, 99, (eg.isAmp and h ~= "l4") and 99 or 0, false)
            end
        end
        for _, h in ipairs(HANDLES) do
            local vo = envCtrl:getValue(h)
            if vo then
                vo:updateValue(saved[h] or 0)
            end
        end
        envCtrl:repaint()
    end

    if eg.curve.start then
        startCtrl:setName(eg.name .. " StartLvl")
        if restoreValues then
            startCtrl:getValue("value"):updateValue(saved.start or 0)
        end
        startCtrl:setVisible(true)
    else
        startCtrl:setVisible(false)
    end
end

_G.onSharedEgCurveChanged = function(changedEgId)
    if ready and getActiveFilterEgId() == changedEgId then
        updateAssignedEgWidget(true)
    end
end

local function repaintFilterWidget(fltIdx)
    local cid = (fltIdx == 0) and 8 or 12
    local c = controls.get(cid)
    if c then
        c:repaint()
    end
end

local function fractionOfFilterVal(control, id)
    local value = control:getValue(id)
    if not value then return 0, 0 end
    local min, max = value:getMin(), value:getMax()
    local level = (value.isSet and value:isSet()) and value:getValue() or value:getValue() or value:getDefault() or min
    if max <= min then return 0, level end
    return (level - min) / (max - min), level
end

local function setupFilterWidget(cid)
    local spec = FILTER_GRAPH_PARAMS[cid]
    local ctrl = controls.get(cid)
    if not spec or not ctrl then
        return
    end
    local fltIdx = spec.flt

    ctrl:setPaintCallback(function(c)
        local bounds = c:getBounds()
        local w, h = bounds[WIDTH], bounds[HEIGHT]
        local cut, cutLevel = fractionOfFilterVal(c, "cutoff")
        local res, resLevel = fractionOfFilterVal(c, "resonance")
        local ftype = math.floor(tonumber(fltTypeIdx[fltIdx]) or 0)
        if ftype < 0 or ftype > 4 then
            ftype = 0
        end

        local on = c:getColor()
        local dimmed = (graphics.dim) and graphics.dim(on, 0.3) or on

        local top = 18
        local bottom = h - 4
        local flat = top + (bottom - top) * 0.55
        local cx = 4 + cut * (w - 8)
        local bump = res * (flat - top)
        local bumpWidth = w * 0.12
        local slope = (bottom - top) / (w * 0.2)

        local function bpfY(x, center, r)
            local ctr = center or cx
            local pk = flat - r * (flat - top)
            local bw = w * (0.14 - 0.08 * r)
            local u = (x - ctr) / bw
            local n2 = u * u
            local gain = 1 / (1 + n2 * n2 * 0.65)
            local y = bottom - (bottom - pk) * gain
            if y > bottom then y = bottom end
            return y
        end

        local cxB, resB = cx, 0
        if ftype == 4 then
            local saved = fltSavedValues[fltIdx] or {}
            local cutBVal = saved[34] ~= nil and saved[34] or 50
            local resBVal = saved[35] ~= nil and saved[35] or 0
            cxB = 4 + (cutBVal / 99) * (w - 8)
            resB = resBVal / 99
        end

        local function yAt(x)
            local y
            if ftype == 1 then
                -- HPF (High Pass Filter)
                if x < cx then
                    y = flat - bump + (cx - x) * slope
                else
                    local d = (x - cx) / bumpWidth
                    y = flat - (d < 1 and bump * (1 - d) * (1 - d) or 0)
                end
            elseif ftype == 2 then
                -- BPF (Band Pass Filter)
                y = bpfY(x, cx, res)
            elseif ftype == 3 then
                -- BRF (Band Reject / Notch Filter)
                local bw = w * (0.13 - 0.08 * res)
                local u = (x - cx) / bw
                local n2 = u * u
                local notch = 1 / (1 + n2 * n2)
                y = flat + notch * (bottom - flat)
            elseif ftype == 4 then
                -- 2BPF (Dual Band Pass Filter: Band A + Band B)
                y = math.min(bpfY(x, cx, res), bpfY(x, cxB, resB))
            else
                -- LPF (Low Pass Filter, ftype == 0)
                if x <= cx then
                    local d = (cx - x) / bumpWidth
                    y = flat - (d < 1 and bump * (1 - d) * (1 - d) or 0)
                else
                    y = flat - bump + (x - cx) * slope
                end
            end
            if y > bottom then y = bottom end
            if y < top then y = top end
            return y
        end

        graphics.setColor(dimmed)
        graphics.drawLine(0, bottom, w - 1, bottom)
        local marker = math.floor(cx + 0.5)
        graphics.drawLine(marker, top, marker, bottom)
        if ftype == 4 then
            local markerB = math.floor(cxB + 0.5)
            graphics.drawLine(markerB, top, markerB, bottom)
        end

        graphics.setColor(on)
        local segStartX = 0
        local prevX, prevY = 0, math.floor(yAt(0) + 0.5)
        for x = FLT_GRAPH_STEP, w - 1, FLT_GRAPH_STEP do
            local y = math.floor(yAt(x) + 0.5)
            if y ~= prevY then
                if prevX > segStartX then
                    graphics.drawLine(segStartX, prevY, prevX, prevY)
                end
                graphics.drawLine(prevX, prevY, x, y)
                segStartX = x
                prevY = y
            end
            prevX = x
        end
        if prevX > segStartX then
            graphics.drawLine(segStartX, prevY, prevX, prevY)
        end

        graphics.print(4, 0, spec.label .. " CUT " .. math.floor(cutLevel), 120, LEFT, REGULAR, SMALL)
        graphics.print(116, 0, FLT_TYPE_NAMES[ftype] or "LPF", 80, CENTER, REGULAR, SMALL)
        graphics.print(189, 0, "RESO " .. math.floor(resLevel), 120, RIGHT, REGULAR, SMALL)
    end)

    ctrl:setPotCallback(function(c, event)
        if event.delta == 0 then return end
        local v = c:getValue(event.valueId)
        if not v then return end
        local level = (v.isSet and v:isSet()) and v:getValue() or v:getValue() or v:getDefault() or v:getMin()
        local clamped = math.max(v:getMin(), math.min(v:getMax(), level + event.delta))
        if clamped == level then return end
        v:setValue(clamped)
    end)

    ctrl:setSwitchCallback(function(c, event)
        if event.type ~= 1 then return end
        local v = c:getValue(event.valueId)
        if not v then return end
        local def = v:getDefault() or v:getMin()
        local cur = (v.isSet and v:isSet()) and v:getValue() or v:getValue()
        if cur == def then return end
        v:setValue(def)
    end)
end

local lastIs2Bpf = nil
local lastGrpBLabel = nil

-- Show Filter-B (2BPF) controls (33..43) ONLY when the selected filter's Type is 2BPF (index 4 / Z1 value 5)
function updateFilterBVisibility(force)
    local is2Bpf = (fltTypeIdx[selectedFlt] == 4)
    local label  = ((selectedFlt == 0) and "FILTER 1" or "FILTER 2") .. " 2BPF BAND-B (DUAL BANDPASS)"
    if not force and lastIs2Bpf == is2Bpf and lastGrpBLabel == label then
        return
    end
    lastIs2Bpf = is2Bpf
    lastGrpBLabel = label
    local grpB = preset.getGroup(52)
    if grpB then
        grpB:setLabel(label)
        grpB:setVisible(is2Bpf)
    end
    for cid = 33, 43 do
        controls.get(cid):setVisible(is2Bpf)
    end
end

-- Callback for static top-section controls (1..3, 6..12)
function onStaticFilter(valueObject, value)
    local ctrl = valueObject:getControl()
    local ctrlId = ctrl:getId()
    local v = math.floor(value)

    local gspec = FILTER_GRAPH_PARAMS[ctrlId]
    if gspec then
        local valSpec = gspec[valueObject:getId()]
        if not valSpec then
            return
        end
        sendParamChange(0, valSpec.id, v)
        ctrl:repaint()
        return
    end

    local spec = STATIC_PARAMS[ctrlId]
    if not spec then
        return
    end
    if spec.kind == "list" and v < 0 then
        return
    end
    local z1Val = v
    if spec.kind == "list" then
        local idx = v
        local defs = ENUM_DEFS[spec.ov]
        if valueObject.getMin and valueObject:getMin() == 1 and defs and defs[1] and defs[1].value == 1 then
            idx = v - 1
            z1Val = v
        else
            local ov = overlays.get(spec.ov)
            z1Val = (defs and defs[idx + 1] and defs[idx + 1].value)
                 or (ov and ov:getValueByIndex(idx))
                 or v
        end
        if spec.flt ~= nil then
            if idx < 0 then idx = 0 elseif idx > 4 then idx = 4 end
            fltTypeIdx[spec.flt] = idx
            if spec.flt == selectedFlt then
                updateFilterBVisibility()
            end
            repaintFilterWidget(spec.flt)
        end
    end
    sendParamChange(0, spec.id, z1Val)
end

-- Callback for Control 4: Assigned Cutoff EG dx7envelope handles (l1..l4, r1..r4)
function onEg3Handle(valueObject, value)
    local egId = getActiveFilterEgId()
    local eg   = EGS[egId]
    if not eg then
        return
    end
    local handleId = valueObject:getId()
    local v = math.floor(value)
    egCurveSaved[egId][handleId] = v
    if _G.onFilterEgCurveChanged then
        _G.onFilterEgCurveChanged(egId, handleId, v)
    end

    local paramId = eg.curve[handleId]
    if not paramId then
        return -- e.g. Amp EG l4 (Release Level is reserved on Z1)
    end
    sendParamChange(0, paramId, v)
end

-- Callback for Control 5: Assigned Cutoff EG Start Level (EG1..EG4; hidden for Amp EG)
function onEgStartLevel(valueObject, value)
    local ctrl = valueObject:getControl()
    if not ctrl:isVisible() then
        return
    end
    local egId = getActiveFilterEgId()
    local eg   = EGS[egId]
    if not eg or not eg.curve.start then
        return
    end
    local v = math.floor(value)
    egCurveSaved[egId].start = v
    if _G.onFilterEgCurveChanged then
        _G.onFilterEgCurveChanged(egId, "start", v)
    end
    sendParamChange(0, eg.curve.start, v)
end

-- Relabel & restore saved values for Filter 1 / Filter 2 dynamic controls (21..43) + Assigned Cutoff EG widget
function updateFilterControls()
    local prefix = (selectedFlt == 0) and "F1 " or "F2 "
    local label  = (selectedFlt == 0) and "FILTER 1" or "FILTER 2"
    local saved  = fltSavedValues[selectedFlt]

    local grpMod = preset.getGroup(51)
    if grpMod then
        grpMod:setLabel(label .. " MOD & KEY TRACK")
    end

    for cid = 21, 43 do
        local def = DYN_DEFS[cid]
        local ctrl = controls.get(cid)
        if def and ctrl then
            ctrl:setName(prefix .. def.short)
            ctrl:getValue("value"):updateValue(saved[cid] or def.defVal)
        end
    end

    updateAssignedEgWidget(true)
    updateFilterBVisibility()
end

-- Callback for Control 20: Filter Target Selector (0 = Filter 1, 1 = Filter 2)
function onFilterSelect(valueObject, value)
    local newFlt = math.floor(value)
    if newFlt < 0 or newFlt > 1 or newFlt == selectedFlt then
        return
    end
    selectedFlt = newFlt
    updateFilterControls()
    info.setText(selectedFlt == 0 and "Editing Filter 1" or "Editing Filter 2")
end

-- Callback for Dynamic Filter Controls (21..43)
function onDynFilter(valueObject, value)
    if not ready then
        return
    end
    local ctrl = valueObject:getControl()
    if not ctrl:isVisible() then
        return
    end
    local ctrlId = ctrl:getId()
    local def = DYN_DEFS[ctrlId]
    if not def then
        return
    end

    local v = math.floor(value)
    if def.kind == "list" and v < 0 then
        return
    end
    fltSavedValues[selectedFlt][ctrlId] = v

    -- When Cutoff Mod EG (control 21) changes, snap the dx7envelope widget to the newly assigned EG!
    if ctrlId == 21 then
        updateAssignedEgWidget(true)
    elseif ctrlId == 34 or ctrlId == 35 then
        repaintFilterWidget(selectedFlt)
    end

    local paramId = (selectedFlt == 0) and def.f1 or def.f2
    local z1Val = v
    if def.kind == "list" then
        local ov = overlays.get(def.ov)
        z1Val = (ov and ov:getValueByIndex(v)) or v
    end
    sendParamChange(0, paramId, z1Val)
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
    controls.get(1):getValue("value"):setOverlayId(OV.ROUTING)
    controls.get(3):getValue("value"):setOverlayId(OV.EG_TARGET)
    controls.get(6):getValue("value"):setOverlayId(OV.FLT_TYPE)
    controls.get(10):getValue("value"):setOverlayId(OV.FLT_TYPE)
    controls.get(20):getValue("value"):setOverlayId(OV.FLT_SELECT)

    for cid, gspec in pairs(FILTER_GRAPH_PARAMS) do
        local c = controls.get(cid)
        if c then
            c:getValue("cutoff"):updateValue(gspec.cutoff.def)
            c:getValue("resonance"):updateValue(gspec.resonance.def)
        end
        setupFilterWidget(cid)
    end

    for cid, def in pairs(DYN_DEFS) do
        fltSavedValues[0][cid] = def.defVal
        fltSavedValues[1][cid] = def.defVal
        if def.kind == "list" then
            controls.get(cid):getValue("value"):setOverlayId(def.ov)
        end
        controls.get(cid):getValue("value"):updateValue(def.defVal)
    end
    updateAssignedEgWidget(false)
    updateFilterBVisibility()
    repaintFilterWidget(0)
    repaintFilterWidget(1)
    ready = true
    info.setText("Z1 Filter Ready")
end

local function z1ValToIdx(ovId, z1Val)
    if not ovId then return z1Val end
    local defs = ENUM_DEFS[ovId]
    if type(defs) == "table" then
        for i, item in ipairs(defs) do
            if type(item) == "table" and item.value == z1Val then return i - 1 end
        end
    end
    local ov = overlays.get(ovId)
    if ov and ov.getIndexByValue then
        local idx = ov:getIndexByValue(z1Val)
        if idx ~= nil then return idx end
    end
    if ov and ov.getValueByIndex then
        for i = 0, 63 do
            local v = ov:getValueByIndex(i)
            if v == nil then break end
            if v == z1Val then return i end
        end
    end
    return z1Val
end

local function syncEgCurveFromParams(p0)
    for egId = 1, 5 do
        local eg = EGS[egId]
        local saved = egCurveSaved[egId]
        if eg and saved then
            if eg.curve.start and p0[eg.curve.start] ~= nil then
                saved.start = p0[eg.curve.start]
            end
            for _, h in ipairs(HANDLES) do
                local pid = eg.curve[h]
                if pid and p0[pid] ~= nil then
                    saved[h] = p0[pid]
                end
            end
        end
    end
end

function preset.onZ1Param(exId, paramId, z1Val)
    if exId ~= 0 then return end
    for cid, gspec in pairs(FILTER_GRAPH_PARAMS) do
        if gspec.cutoff.id == paramId then
            local c = controls.get(cid)
            if c then
                c:getValue("cutoff"):updateValue(z1Val)
                c:repaint()
            end
            return
        elseif gspec.resonance.id == paramId then
            local c = controls.get(cid)
            if c then
                c:getValue("resonance"):updateValue(z1Val)
                c:repaint()
            end
            return
        end
    end
    for cid, spec in pairs(STATIC_PARAMS) do
        if spec.id == paramId then
            local disp = (spec.kind == "list") and z1ValToIdx(spec.ov, z1Val) or z1Val
            if spec.flt ~= nil then
                fltTypeIdx[spec.flt] = disp
                repaintFilterWidget(spec.flt)
            end
            local c = controls.get(cid)
            if c then c:getValue("value"):updateValue(disp) end
            updateFilterBVisibility()
            return
        end
    end
    for cid, def in pairs(DYN_DEFS) do
        if def.f1 == paramId or def.f2 == paramId then
            local disp = (def.kind == "list") and z1ValToIdx(def.ov, z1Val) or z1Val
            if def.f1 == paramId then
                fltSavedValues[0][cid] = disp
                if cid == 34 or cid == 35 then repaintFilterWidget(0) end
            end
            if def.f2 == paramId then
                fltSavedValues[1][cid] = disp
                if cid == 34 or cid == 35 then repaintFilterWidget(1) end
            end
            updateFilterControls()
            return
        end
    end
    syncEgCurveFromParams({ [paramId] = z1Val })
    updateAssignedEgWidget(true)
end

function preset.onZ1Dump(params)
    local p0 = params and params[0]
    if not p0 then return end
    for cid, gspec in pairs(FILTER_GRAPH_PARAMS) do
        local c = controls.get(cid)
        if c then
            if p0[gspec.cutoff.id] ~= nil then
                c:getValue("cutoff"):updateValue(p0[gspec.cutoff.id])
            end
            if p0[gspec.resonance.id] ~= nil then
                c:getValue("resonance"):updateValue(p0[gspec.resonance.id])
            end
        end
    end
    for cid, spec in pairs(STATIC_PARAMS) do
        local z1Val = p0[spec.id]
        if z1Val ~= nil then
            local disp = (spec.kind == "list") and z1ValToIdx(spec.ov, z1Val) or z1Val
            if spec.flt ~= nil then
                fltTypeIdx[spec.flt] = disp
            end
            local c = controls.get(cid)
            if c then c:getValue("value"):updateValue(disp) end
        end
    end
    for cid, def in pairs(DYN_DEFS) do
        if p0[def.f1] ~= nil then
            fltSavedValues[0][cid] = (def.kind == "list") and z1ValToIdx(def.ov, p0[def.f1]) or p0[def.f1]
        end
        if p0[def.f2] ~= nil then
            fltSavedValues[1][cid] = (def.kind == "list") and z1ValToIdx(def.ov, p0[def.f2]) or p0[def.f2]
        end
    end
    syncEgCurveFromParams(p0)
    updateFilterControls()
    repaintFilterWidget(0)
    repaintFilterWidget(1)
end
