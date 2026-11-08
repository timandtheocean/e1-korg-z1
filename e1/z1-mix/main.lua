-- Korg Z1 - Mixer & Mix Modulation Page for Electra One mk2
-- Covers all 34 Z1 [Mixer] Program Parameters (PROG_PRM.TXT IDs 224..257, ExID = 0)
-- plus 2 custom Mixer Bus bar-graph visualizers (Out 1 -> Filter 1, Out 2 -> Filter 2).
--
-- Layout (36 slots across 3 Control Sets, 5 channel strips in Columns 1..5 + Switches/Meters in Column 6):
--   Columns 1..5: [Col 1] OSC1, [Col 2] OSC2, [Col 3] SUB OSC, [Col 4] NOISE, [Col 5] FEEDBACK
--   Control Set 1 (Rows 1-2, Slots 1..12):
--     Row 1 (Slots 1..6):   [1..5]  Out 1 Level (0..99) for OSC1/OSC2/SUB/NOISE/FBK, [6]  OSC1 Out SW (254)
--     Row 2 (Slots 7..12):  [7..11] Out 2 Level (0..99) for OSC1/OSC2/SUB/NOISE/FBK, [12] OSC2 Out SW (255)
--   Control Set 2 (Rows 3-4, Slots 13..24):
--     Row 3 (Slots 13..18): [13..17] Out 1 Level Mod Source (0..48, List 1),         [18] SUB Out SW (256)
--     Row 4 (Slots 19..24): [19..23] Out 1 Level Mod Int (-99..+99),                 [24] Noise Out SW (257)
--   Control Set 3 (Rows 5-6, Slots 25..36):
--     Row 5 (Slots 25..30): [25..29] Out 2 Level Mod Source (0..48, List 1),         [30] Out 1 Bus (custom graph)
--     Row 6 (Slots 31..36): [31..35] Out 2 Level Mod Int (-99..+99),                 [36] Out 2 Bus (custom graph)

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
    MODSRC1 = 1,
}

-- ============================================================================
-- 2. Z1 Mixer Parameter Mapping (PROG_PRM.TXT IDs 224..257, ExID = 0)
-- ============================================================================
-- 5 Mixer Channels (stride = 6 parameters per channel):
--   Ch 1 (OSC1):     base 224 (224..229), Output SW = 254
--   Ch 2 (OSC2):     base 230 (230..235), Output SW = 255
--   Ch 3 (SUB OSC):  base 236 (236..241), Output SW = 256
--   Ch 4 (NOISE):    base 242 (242..247), Output SW = 257
--   Ch 5 (Feedback): base 248 (248..253), always active (no Output SW)
--
-- Per-channel offsets (0..5):
--   +0: Out1 Level          (0..99)
--   +1: Out1 Level Mod Src  (0..48, Mod.Source List 1)
--   +2: Out1 Level Mod Int  (-99..+99)
--   +3: Out2 Level          (0..99)
--   +4: Out2 Level Mod Src  (0..48, Mod.Source List 1)
--   +5: Out2 Level Mod Int  (-99..+99)

MIX_CHANNELS = {
    [1] = { name = "OSC1",  short = "O1", base = 224, swId = 254, defOut1 = 99, defOut2 = 0, defSw = 1, color = 0xF49500 },
    [2] = { name = "OSC2",  short = "O2", base = 230, swId = 255, defOut1 = 99, defOut2 = 0, defSw = 1, color = 0xF45C51 },
    [3] = { name = "SUB",   short = "SB", base = 236, swId = 256, defOut1 = 0,  defOut2 = 0, defSw = 0, color = 0x529DEC },
    [4] = { name = "NOISE", short = "NS", base = 242, swId = 257, defOut1 = 0,  defOut2 = 0, defSw = 0, color = 0x03A598 },
    [5] = { name = "FBK",   short = "FB", base = 248, swId = nil, defOut1 = 0,  defOut2 = 0, defSw = 1, color = 0xC44795 },
}

-- Live mixer state (used by custom Bus 1 / Bus 2 bar-graph widgets and verified by tests)
mixState = {}
for ch = 1, 5 do
    local cfg = MIX_CHANNELS[ch]
    mixState[ch] = {
        out1Lvl = cfg.defOut1,
        out1Src = 0,
        out1Int = 0,
        out2Lvl = cfg.defOut2,
        out2Src = 0,
        out2Int = 0,
        sw      = cfg.defSw,
    }
end

-- Map control IDs (1..35, excluding custom widgets 30 & 36) to Z1 parameter specs
MIX_CTRL_MAP = {}
for ch = 1, 5 do
    local base = MIX_CHANNELS[ch].base
    -- Row 1 (Controls 1..5): Out 1 Level (+0)
    MIX_CTRL_MAP[ch]      = { id = base + 0, ch = ch, field = "out1Lvl", kind = "num",  bus = 1 }
    -- Row 2 (Controls 7..11): Out 2 Level (+3)
    MIX_CTRL_MAP[6 + ch]  = { id = base + 3, ch = ch, field = "out2Lvl", kind = "num",  bus = 2 }
    -- Row 3 (Controls 13..17): Out 1 Level Mod Source (+1)
    MIX_CTRL_MAP[12 + ch] = { id = base + 1, ch = ch, field = "out1Src", kind = "list", ov = OV.MODSRC1, bus = 1 }
    -- Row 4 (Controls 19..23): Out 1 Level Mod Int (+2)
    MIX_CTRL_MAP[18 + ch] = { id = base + 2, ch = ch, field = "out1Int", kind = "num",  bus = 1 }
    -- Row 5 (Controls 25..29): Out 2 Level Mod Source (+4)
    MIX_CTRL_MAP[24 + ch] = { id = base + 4, ch = ch, field = "out2Src", kind = "list", ov = OV.MODSRC1, bus = 2 }
    -- Row 6 (Controls 31..35): Out 2 Level Mod Int (+5)
    MIX_CTRL_MAP[30 + ch] = { id = base + 5, ch = ch, field = "out2Int", kind = "num",  bus = 2 }
end

-- Column 6 (Controls 6, 12, 18, 24): Mixer Output Switches (IDs 254..257)
MIX_CTRL_MAP[6]  = { id = 254, ch = 1, field = "sw", kind = "num", bus = 0 }
MIX_CTRL_MAP[12] = { id = 255, ch = 2, field = "sw", kind = "num", bus = 0 }
MIX_CTRL_MAP[18] = { id = 256, ch = 3, field = "sw", kind = "num", bus = 0 }
MIX_CTRL_MAP[24] = { id = 257, ch = 4, field = "sw", kind = "num", bus = 0 }

-- Custom Mixer Bus bar-graph control IDs (Slot 30 = Out 1 Bus, Slot 36 = Out 2 Bus)
local BUS_CTRL_ID = { [1] = 30, [2] = 36 }

-- ============================================================================
-- 3. Custom Mixer Bus Visualizer Widget (Out 1 -> FLT 1, Out 2 -> FLT 2)
-- ============================================================================

-- Compute normalized effective bar height in [0.0, 1.0] for channel `ch` on bus `busIdx` (1 or 2)
function evalMixBusLevel(ch, busIdx)
    local st = mixState[ch]
    if not st or st.sw == 0 then
        return 0.0
    end
    local lvl = (busIdx == 1) and st.out1Lvl or st.out2Lvl
    if lvl < 0 then lvl = 0 elseif lvl > 99 then lvl = 99 end
    return lvl / 99.0
end

local function makeBusPainter(busIdx)
    return function(control)
        local b = control:getBounds()
        local w = b[WIDTH]
        local h = b[HEIGHT]

        graphics.setColor(0x1E2631)
        graphics.fillRoundRect(0, 0, w, h, 4)
        graphics.setColor(0x3B4B5E)
        graphics.drawRoundRect(0, 0, w, h, 4)

        local top = 16
        local bot = h - 5
        local maxBarH = bot - top
        local colW = (w - 12) // 5

        for ch = 1, 5 do
            local cfg = MIX_CHANNELS[ch]
            local st  = mixState[ch]
            local x0  = 6 + (ch - 1) * colW
            local bw  = colW - 4

            -- Track background
            graphics.setColor(0x2A3544)
            graphics.fillRect(x0, top, bw, maxBarH)

            -- Active level bar (dimmed if channel Output SW is OFF)
            local rawLvl = (busIdx == 1) and st.out1Lvl or st.out2Lvl
            local barH = math.floor(((rawLvl or 0) / 99.0) * maxBarH + 0.5)
            if barH > 0 then
                graphics.setColor((st.sw == 1) and cfg.color or 0x4A5A6A)
                graphics.fillRect(x0, bot - barH, bw, barH)
            end

            --Modulation indicator dot at top of bar if Mod Src != Off and Mod Int != 0
            local modSrc = (busIdx == 1) and st.out1Src or st.out2Src
            local modInt = (busIdx == 1) and st.out1Int or st.out2Int
            if modSrc ~= 0 and modInt ~= 0 then
                graphics.setColor(WHITE)
                graphics.fillRect(x0 + (bw // 2) - 1, top, 3, 3)
            end
        end

        graphics.setColor(WHITE)
        local title = (busIdx == 1) and "OUT1 -> FLT1" or "OUT2 -> FLT2"
        graphics.print(5, 2, title, w - 10, LEFT, REGULAR, SMALL)
    end
end

local function repaintMixBuses(busIdx)
    if busIdx == 1 or busIdx == 0 then
        local c1 = preset.getControl(BUS_CTRL_ID[1])
        if c1 then c1:repaint() end
    end
    if busIdx == 2 or busIdx == 0 then
        local c2 = preset.getControl(BUS_CTRL_ID[2])
        if c2 then c2:repaint() end
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

function onMixParam(valueObject, value)
    local ctrlId = valueObject:getControl():getId()
    local spec = MIX_CTRL_MAP[ctrlId]
    if not spec then
        return
    end

    local v = math.floor(value)
    local z1Val = v
    if spec.kind == "list" then
        local ov = overlays.get(spec.ov)
        z1Val = (ov and ov:getValueByIndex(v)) or v
    end

    mixState[spec.ch][spec.field] = z1Val
    repaintMixBuses(spec.bus)

    sendParamChange(0, spec.id, z1Val)
end

-- ============================================================================
-- 6. Lifecycle Hooks
-- ============================================================================

function preset.onLoad()
    overlays.create(OV.MODSRC1, MODSRC1)
    for busIdx = 1, 2 do
        local c = preset.getControl(BUS_CTRL_ID[busIdx])
        if c then
            c:setPaintCallback(makeBusPainter(busIdx))
        end
    end
end

function preset.onReady()
    for cid, spec in pairs(MIX_CTRL_MAP) do
        if spec.kind == "list" then
            controls.get(cid):getValue("value"):setOverlayId(spec.ov)
        end
    end
    repaintMixBuses(0)
    info.setText("Z1 Mixer Ready")
end
