-- Korg Z1 - LFO 1..4 Page for Electra One mk2
-- Includes custom waveform visualizer widgets (inspired by roomi-fields/electraone-widgets graph/send-lfo)
-- that draw the live Z1 LFO waveform (all 18 Z1 LFO wave shapes + Offset shift + Fade-In envelope)!
--
-- Layout (36 slots across 3 Control Sets):
--   Control Set 1 (Rows 1-2, Slots 1..12):
--     Row 1 (Slots 1..6):  [1] LFO1 Wave (list), [2] LFO1 Shape (custom graph), [3] LFO1 Freq,
--                          [4] LFO2 Wave (list), [5] LFO2 Shape (custom graph), [6] LFO2 Freq
--     Row 2 (Slots 7..12): [7] LFO1 KeySync,     [8] LFO1 FadeIn,               [9] LFO1 Offset,
--                         [10] LFO2 KeySync,    [11] LFO2 FadeIn,              [12] LFO2 Offset
--   Control Set 2 (Rows 3-4, Slots 13..24):
--     Row 3 (Slots 13..18): [13] LFO3 Wave (list), [14] LFO3 Shape (custom graph), [15] LFO3 Freq,
--                           [16] LFO4 Wave (list), [17] LFO4 Shape (custom graph), [18] LFO4 Freq
--     Row 4 (Slots 19..24): [19] LFO3 KeySync,     [20] LFO3 FadeIn,               [21] LFO3 Offset,
--                           [22] LFO4 KeySync,     [23] LFO4 FadeIn,               [24] LFO4 Offset
--   Control Set 3 (Rows 5-6, Slots 25..34):
--     Slot 25:        [25] LFO SELECT (LFO 1 / LFO 2 / LFO 3 / LFO 4)
--     Slots 26..34:   [26] MIDI Sync (OFF/ON), [27] Sync Base (0..7), [28] Sync Time (1..16),
--                     [29] Freq Mod1 Src,      [30] Freq Mod1 Int,    [31] Freq Mod2 Src,
--                     [32] Freq Mod2 Int,      [33] Amp Mod Src,      [34] Amp Mod Int

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

-- [*3]: Z1 LFO Wave Form (18 wave shapes, 0..17)
LFO_WAVES = {
    { value = 0,  label = "Triangle 0" },
    { value = 1,  label = "Triangle 90" },
    { value = 2,  label = "Tri Random" },
    { value = 3,  label = "Sine" },
    { value = 4,  label = "Saw Up 0" },
    { value = 5,  label = "Saw Up 180" },
    { value = 6,  label = "Saw Down 0" },
    { value = 7,  label = "Saw Down 180" },
    { value = 8,  label = "Square" },
    { value = 9,  label = "Random S/H" },
    { value = 10, label = "Random Vect" },
    { value = 11, label = "Step Tri 4" },
    { value = 12, label = "Step Tri 6" },
    { value = 13, label = "Step Saw 4" },
    { value = 14, label = "Step Saw 6" },
    { value = 15, label = "Exp Triangle" },
    { value = 16, label = "Exp Saw Up" },
    { value = 17, label = "Exp Saw Down" },
}

local OV = {
    LFO_WAVE   = 1,
    MODSRC1    = 2,
    KEY_SYNC   = 3,
    SYNC_BASE  = 4,
    LFO_SELECT = 5,
}

local ENUM_DEFS = {
    [OV.LFO_WAVE] = LFO_WAVES,
    [OV.MODSRC1]  = MODSRC1,
    [OV.KEY_SYNC] = {
        { value = 0, label = "OFF" },
        { value = 1, label = "by TIMBRE" },
        { value = 2, label = "by VOICE" },
    },
    [OV.SYNC_BASE] = {
        { value = 0, label = "32nd" },
        { value = 1, label = "16th Tri" },
        { value = 2, label = "16th" },
        { value = 3, label = "8th Tri" },
        { value = 4, label = "8th" },
        { value = 5, label = "4th Tri" },
        { value = 6, label = "4th" },
        { value = 7, label = "2nd" },
    },
    [OV.LFO_SELECT] = {
        { value = 0, label = "LFO 1" },
        { value = 1, label = "LFO 2" },
        { value = 2, label = "LFO 3" },
        { value = 3, label = "LFO 4" },
    },
}

-- ============================================================================
-- 2. Z1 LFO Parameter Mapping (PROG_PRM.TXT IDs 107..162, ExID = 0)
-- ============================================================================
-- Each LFO has 14 parameters (stride = 14 bytes/IDs):
--   +0:  Wave Form (0..17)
--   +1:  Key Sync SW (0..2)
--   +2:  Frequency (0..199)
--   +3:  Frequency Mod1 Source (0..48)
--   +4:  Frequency Mod1 Int (-99..+99)
--   +5:  Frequency Mod2 Source (0..48)
--   +6:  Frequency Mod2 Int (-99..+99)
--   +7:  Fade In (0..99)
--   +8:  Amplitude Mod Source (0..48)
--   +9:  Amplitude Mod Int (-99..+99)
--   +10: Offset (-50..+50)
--   +11: MIDI Sync (0/1)
--   +12: MIDI Sync Base (0..7)
--   +13: MIDI Sync Time (0..15 -> 1..16)

LFO_BASE = {
    [1] = 107, -- LFO1: 107..120
    [2] = 121, -- LFO2: 121..134
    [3] = 135, -- LFO3: 135..148
    [4] = 149, -- LFO4: 149..162
}

-- Live state for each of the 4 LFOs (used by the custom waveform graph widgets & bottom section)
lfoState = {}
for i = 1, 4 do
    lfoState[i] = {
        wave   = 0,  -- 0..17
        syncSw = 0,  -- 0..2
        freq   = 50, -- 0..199
        fade   = 0,  -- 0..99
        offset = 0,  -- -50..+50
        -- Bottom section per-LFO saved values (controls 26..34):
        [26] = 0, -- MIDI Sync (0/1)
        [27] = 3, -- MIDI Sync Base (0..7, default 8th Tri)
        [28] = 0, -- MIDI Sync Time (0..15 -> 1..16)
        [29] = 0, -- Freq Mod1 Source
        [30] = 0, -- Freq Mod1 Int
        [31] = 0, -- Freq Mod2 Source
        [32] = 0, -- Freq Mod2 Int
        [33] = 0, -- Amp Mod Source
        [34] = 0, -- Amp Mod Int
    }
end

-- Map static top/middle controls to (lfoIndex, paramOffset, stateField, kind, ov)
local STATIC_LFO_CTRL = {
    -- LFO 1 (Slots 1, 2[custom], 3, 7, 8, 9)
    [1]  = { lfo = 1, off = 0,  field = "wave",   kind = "list", ov = OV.LFO_WAVE },
    [3]  = { lfo = 1, off = 2,  field = "freq",   kind = "num" },
    [7]  = { lfo = 1, off = 1,  field = "syncSw", kind = "list", ov = OV.KEY_SYNC },
    [8]  = { lfo = 1, off = 7,  field = "fade",   kind = "num" },
    [9]  = { lfo = 1, off = 10, field = "offset", kind = "num" },
    -- LFO 2 (Slots 4, 5[custom], 6, 10, 11, 12)
    [4]  = { lfo = 2, off = 0,  field = "wave",   kind = "list", ov = OV.LFO_WAVE },
    [6]  = { lfo = 2, off = 2,  field = "freq",   kind = "num" },
    [10] = { lfo = 2, off = 1,  field = "syncSw", kind = "list", ov = OV.KEY_SYNC },
    [11] = { lfo = 2, off = 7,  field = "fade",   kind = "num" },
    [12] = { lfo = 2, off = 10, field = "offset", kind = "num" },
    -- LFO 3 (Slots 13, 14[custom], 15, 19, 20, 21)
    [13] = { lfo = 3, off = 0,  field = "wave",   kind = "list", ov = OV.LFO_WAVE },
    [15] = { lfo = 3, off = 2,  field = "freq",   kind = "num" },
    [19] = { lfo = 3, off = 1,  field = "syncSw", kind = "list", ov = OV.KEY_SYNC },
    [20] = { lfo = 3, off = 7,  field = "fade",   kind = "num" },
    [21] = { lfo = 3, off = 10, field = "offset", kind = "num" },
    -- LFO 4 (Slots 16, 17[custom], 18, 22, 23, 24)
    [16] = { lfo = 4, off = 0,  field = "wave",   kind = "list", ov = OV.LFO_WAVE },
    [18] = { lfo = 4, off = 2,  field = "freq",   kind = "num" },
    [22] = { lfo = 4, off = 1,  field = "syncSw", kind = "list", ov = OV.KEY_SYNC },
    [23] = { lfo = 4, off = 7,  field = "fade",   kind = "num" },
    [24] = { lfo = 4, off = 10, field = "offset", kind = "num" },
}

-- Custom waveform widget control IDs for LFO 1..4
local SHAPE_CTRL_ID = { [1] = 2, [2] = 5, [3] = 14, [4] = 17 }

-- Bottom section dynamic controls (26..34) mapped to parameter offset from LFO_BASE[selectedLfo]
local DYN_LFO_DEFS = {
    [26] = { off = 11, short = "MIDI Sync", kind = "num",  defVal = 0 },
    [27] = { off = 12, short = "Sync Base", kind = "list", ov = OV.SYNC_BASE, defVal = 3 },
    [28] = { off = 13, short = "Sync Time", kind = "num",  fmt = "plus1",     defVal = 0 },
    [29] = { off = 3,  short = "FrqSrc 1",  kind = "list", ov = OV.MODSRC1,   defVal = 0 },
    [30] = { off = 4,  short = "FrqInt 1",  kind = "num",  defVal = 0 },
    [31] = { off = 5,  short = "FrqSrc 2",  kind = "list", ov = OV.MODSRC1,   defVal = 0 },
    [32] = { off = 6,  short = "FrqInt 2",  kind = "num",  defVal = 0 },
    [33] = { off = 8,  short = "Amp Src",   kind = "list", ov = OV.MODSRC1,   defVal = 0 },
    [34] = { off = 9,  short = "Amp Int",   kind = "num",  defVal = 0 },
}

local selectedLfo = 1 -- 1..4 (LFO1..LFO4)

function fmtPlus1(valueObject, value)
    return tostring(math.floor(value) + 1)
end

-- ============================================================================
-- 3. Custom LFO Waveform Visualizer Widget (inspired by electraone-widgets)
-- ============================================================================

local S_H_STEPS = { 0.65, -0.45, 0.80, -0.75, 0.25, -0.20, 0.55, -0.65 }

-- Compute normalized sample in [-1.0, +1.0] for Z1 LFO wave (0..17) at phase t in [0, 1)
function evalZ1Wave(wave, t)
    if wave == 0 then -- Triangle 0
        if t < 0.25 then return t * 4
        elseif t < 0.75 then return 2 - t * 4
        else return t * 4 - 4 end
    elseif wave == 1 then -- Triangle 90
        return 1 - math.abs(t * 2 - 1) * 2
    elseif wave == 2 then -- Tri Random
        local peak = (t < 0.5) and 0.85 or 0.45
        if t < 0.25 then return (t * 4) * peak
        elseif t < 0.75 then return (2 - t * 4) * peak
        else return (t * 4 - 4) * peak end
    elseif wave == 3 then -- Sine
        return math.sin(t * 2 * math.pi)
    elseif wave == 4 then -- Saw Up 0
        return ((t + 0.5) % 1.0) * 2 - 1
    elseif wave == 5 then -- Saw Up 180
        return t * 2 - 1
    elseif wave == 6 then -- Saw Down 0
        return 1 - ((t + 0.5) % 1.0) * 2
    elseif wave == 7 then -- Saw Down 180
        return 1 - t * 2
    elseif wave == 8 then -- Square
        return (t < 0.5) and 1.0 or -1.0
    elseif wave == 9 then -- Random S/H
        local idx = math.floor(t * 8) + 1
        return S_H_STEPS[idx] or 0
    elseif wave == 10 then -- Random Vector
        local pos = t * 6
        local idx = math.floor(pos) + 1
        local frac = pos - math.floor(pos)
        local a = S_H_STEPS[idx] or 0
        local b = S_H_STEPS[(idx % 6) + 1] or 0
        return a + (b - a) * frac
    elseif wave == 11 or wave == 12 then -- Step Tri 4 / 6
        local steps = (wave == 11) and 4 or 6
        local raw = 1 - math.abs(t * 2 - 1) * 2
        return math.floor(raw * steps + 0.5) / steps
    elseif wave == 13 or wave == 14 then -- Step Saw 4 / 6
        local steps = (wave == 13) and 4 or 6
        local raw = t * 2 - 1
        return math.floor(raw * steps + 0.5) / steps
    elseif wave == 15 then -- Exp Triangle
        local raw = 1 - math.abs(t * 2 - 1) * 2
        local sign = (raw >= 0) and 1 or -1
        return sign * (math.abs(raw) ^ 2.2)
    elseif wave == 16 then -- Exp Saw Up
        return (t ^ 2.4) * 2 - 1
    elseif wave == 17 then -- Exp Saw Down
        return 1 - (t ^ 2.4) * 2
    end
    return 0
end

local function makeWavePainter(lfoIdx)
    return function(control)
        local b = control:getBounds()
        local w = b[WIDTH]
        local h = b[HEIGHT]
        local st = lfoState[lfoIdx]

        -- Card outline & subtle zero-line ( accounting for LFO Offset -50..+50 )
        graphics.setColor(0x1E2631)
        graphics.fillRoundRect(0, 0, w, h, 4)
        graphics.setColor(0x3B4B5E)
        graphics.drawRoundRect(0, 0, w, h, 4)

        local top = 16
        local bot = h - 5
        local mid = (top + bot) // 2
        local amp = (bot - top) / 2

        -- Zero midline
        graphics.setColor(0x4A5A6A)
        graphics.drawLine(4, mid, w - 5, mid)

        -- Waveform trace (with Fade-In envelope and DC Offset preview)
        local traceColor = (selectedLfo == lfoIdx) and ORANGE or BLUE
        graphics.setColor(traceColor)

        local plotW = w - 10
        local fadeFrac = (st.fade or 0) / 140.0
        local dcShift = (st.offset or 0) / 100.0
        local lastX, lastY

        for px = 0, plotW do
            local t = px / plotW
            local env = (fadeFrac > 0.01 and t < fadeFrac) and (t / fadeFrac) or 1.0
            local yNorm = evalZ1Wave(st.wave, (t * 2) % 1.0) * env + dcShift
            if yNorm > 1.0 then yNorm = 1.0 elseif yNorm < -1.0 then yNorm = -1.0 end
            local sx = 5 + px
            local sy = math.floor(mid - yNorm * amp + 0.5)
            if lastX then
                graphics.drawLine(lastX, lastY, sx, sy)
            end
            lastX, lastY = sx, sy
        end

        -- Header label: "LFO1: Sine"
        local wName = (LFO_WAVES[st.wave + 1] and LFO_WAVES[st.wave + 1].label) or "Wave"
        graphics.setColor(WHITE)
        graphics.print(5, 2, string.format("LFO%d %s", lfoIdx, wName), w - 10, LEFT, REGULAR, SMALL)
    end
end

local function repaintAllShapes()
    for i = 1, 4 do
        local c = preset.getControl(SHAPE_CTRL_ID[i])
        if c then
            c:repaint()
        end
    end
end

-- ============================================================================
-- 4. SysEx Builder & Sender
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
-- 5. Control Callbacks
-- ============================================================================

-- Callback for static LFO 1..4 controls (Wave, KeySync, Freq, FadeIn, Offset)
function onStaticLfo(valueObject, value)
    local ctrlId = valueObject:getControl():getId()
    local spec = STATIC_LFO_CTRL[ctrlId]
    if not spec then
        return
    end
    local v = math.floor(value)
    local z1Val = v
    if spec.kind == "list" then
        local ov = overlays.get(spec.ov)
        z1Val = (ov and ov:getValueByIndex(v)) or v
    end

    lfoState[spec.lfo][spec.field] = z1Val
    local shapeCtrl = preset.getControl(SHAPE_CTRL_ID[spec.lfo])
    if shapeCtrl then
        shapeCtrl:repaint()
    end

    local paramId = LFO_BASE[spec.lfo] + spec.off
    sendParamChange(0, paramId, z1Val)
end

-- Update bottom-section (Control Set 3) controls 26..34 for selectedLfo
function updateLfoModControls()
    local prefix = "LFO" .. selectedLfo .. " "
    local st = lfoState[selectedLfo]

    window.stop()
    local grp = preset.getGroup(52)
    if grp then
        grp:setLabel("LFO " .. selectedLfo .. " MIDI SYNC & MODULATION")
    end

    for cid = 26, 34 do
        local def = DYN_LFO_DEFS[cid]
        local ctrl = controls.get(cid)
        if def and ctrl then
            ctrl:setName(prefix .. def.short)
            ctrl:getValue("value"):updateValue(st[cid] or def.defVal)
        end
    end
    repaintAllShapes()
    window.resume()
end

-- Callback for Control 25: LFO Selector (0..3 -> LFO 1..4)
function onLfoSelect(valueObject, value)
    local newLfo = math.floor(value) + 1
    if newLfo < 1 or newLfo > 4 or newLfo == selectedLfo then
        return
    end
    selectedLfo = newLfo
    updateLfoModControls()
    info.setText("Editing LFO " .. selectedLfo .. " Mod/Sync")
end

-- Callback for Bottom Section Dynamic Controls (26..34: MIDI Sync & Modulation for selectedLfo)
function onDynLfo(valueObject, value)
    local ctrlId = valueObject:getControl():getId()
    local def = DYN_LFO_DEFS[ctrlId]
    if not def then
        return
    end

    local v = math.floor(value)
    lfoState[selectedLfo][ctrlId] = v

    local z1Val = v
    if def.kind == "list" then
        local ov = overlays.get(def.ov)
        z1Val = (ov and ov:getValueByIndex(v)) or v
    end

    local paramId = LFO_BASE[selectedLfo] + def.off
    sendParamChange(0, paramId, z1Val)
end

-- ============================================================================
-- 6. Lifecycle Hooks
-- ============================================================================

function preset.onLoad()
    for ovId, items in pairs(ENUM_DEFS) do
        overlays.create(ovId, items)
    end
    for i = 1, 4 do
        local c = preset.getControl(SHAPE_CTRL_ID[i])
        if c then
            c:setPaintCallback(makeWavePainter(i))
            -- Touching a custom LFO graph selects that LFO in the bottom Mod/Sync section!
            c:setTouchCallback(function(self, event)
                if event.type == CLICK and selectedLfo ~= i then
                    controls.get(25):getValue("value"):setValue(i - 1)
                end
            end)
        end
    end
end

function preset.onReady()
    for cid, spec in pairs(STATIC_LFO_CTRL) do
        if spec.kind == "list" then
            controls.get(cid):getValue("value"):setOverlayId(spec.ov)
        end
    end
    controls.get(25):getValue("value"):setOverlayId(OV.LFO_SELECT)
    for cid, def in pairs(DYN_LFO_DEFS) do
        if def.kind == "list" then
            controls.get(cid):getValue("value"):setOverlayId(def.ov)
        end
    end
    repaintAllShapes()
    info.setText("Z1 LFO 1-4 Ready")
end
