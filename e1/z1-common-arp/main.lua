-- Korg Z1 - Program Common, Assignable Controllers, Link Arpeggiator & Program Name for Electra One mk2
-- Covers:
--   [Program Name]    (IDs 1..16,    ExID = 0: 16 ASCII characters 0x20..0x7F)
--   [Program Common]  (IDs 17..30,   ExID = 0: Category, Group, Voice/Trigger, Unison, Scale, Random Pitch)
--   [Controller]      (IDs 366..373, ExID = 0: SW1, SW2, Foot SW, Foot Pedal, Pad Hold)
--   [Link Arpeggio]   (IDs 374..383, ExID = 0: Pattern, Speed, Resolution, Octave, Latch, KeySync, Vel/Gate)
--
-- Layout (35 controls across 3 Control Sets):
--   Control Set 1 (Rows 1-2, Slots 1..12):  Program Common & Unison (IDs 17..27, 30)
--   Control Set 2 (Rows 3-4, Slots 13..24): Scale (IDs 28..29) & Link Arpeggiator (IDs 374..383)
--   Control Set 3 (Rows 5-6, Slots 25..35): Assignable Controllers (IDs 366..373) & Program Name Editor/Display (IDs 1..16)

local DEVICE_ID = 1

local function getGlobalChannel()
    local dev = preset.getDevice(DEVICE_ID)
    if dev then
        return (dev:getChannel() - 1) & 0x0F
    end
    return 0
end

-- ============================================================================
-- 1. Overlays & Enumerations (including Non-Contiguous MODSRC2 for Retrigger)
-- ============================================================================

MODSRC2 = {
    { value = 0,  label = "Off" },
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
}

local OV = {
    CATEGORY   = 1,
    USER_GRP   = 2,
    VOICE_MODE = 3,
    KEY_PRIO   = 4,
    OFF_ON     = 5,
    MODSRC2    = 6,
    UNI_TYPE   = 7,
    UNI_MODE   = 8,
    SCALE_TYPE = 9,
    SCALE_KEY  = 10,
    ARP_PAT    = 11,
    ARP_RESO   = 12,
    ARP_OCT    = 13,
    SW1_FUNC   = 14,
    SW2_FUNC   = 15,
    FSW_FUNC   = 16,
    PED_FUNC   = 17,
    LATCH_MODE = 18,
}

local ENUM_DEFS = {
    [OV.CATEGORY] = {
        { value = 0,  label = "Synth-Hard" },
        { value = 1,  label = "Synth-Soft" },
        { value = 2,  label = "Synth-Lead" },
        { value = 3,  label = "Synth-Motion" },
        { value = 4,  label = "Synth-Bass" },
        { value = 5,  label = "E.Piano" },
        { value = 6,  label = "Organ" },
        { value = 7,  label = "Keyboard" },
        { value = 8,  label = "Bell" },
        { value = 9,  label = "Strings" },
        { value = 10, label = "Pad/Choir" },
        { value = 11, label = "Brass" },
        { value = 12, label = "Reed/Wind" },
        { value = 13, label = "Guitar/Plucked" },
        { value = 14, label = "Bass" },
        { value = 15, label = "Percussive" },
        { value = 16, label = "Arpeggio" },
        { value = 17, label = "SFX/Other" },
    },
    [OV.USER_GRP] = {
        { value = 0,  label = "GROUP 1" },  { value = 1,  label = "GROUP 2" },
        { value = 2,  label = "GROUP 3" },  { value = 3,  label = "GROUP 4" },
        { value = 4,  label = "GROUP 5" },  { value = 5,  label = "GROUP 6" },
        { value = 6,  label = "GROUP 7" },  { value = 7,  label = "GROUP 8" },
        { value = 8,  label = "GROUP 9" },  { value = 9,  label = "GROUP 10" },
        { value = 10, label = "GROUP 11" }, { value = 11, label = "GROUP 12" },
        { value = 12, label = "GROUP 13" }, { value = 13, label = "GROUP 14" },
        { value = 14, label = "GROUP 15" }, { value = 15, label = "GROUP 16" },
    },
    [OV.VOICE_MODE] = {
        { value = 0, label = "MONO MULTI" },
        { value = 1, label = "MONO SINGLE" },
        { value = 2, label = "POLY" },
    },
    [OV.KEY_PRIO] = {
        { value = 0, label = "LAST" },
        { value = 1, label = "LOW" },
        { value = 2, label = "HIGH" },
    },
    [OV.OFF_ON]  = { { value = 0, label = "OFF" }, { value = 1, label = "ON" } },
    [OV.MODSRC2] = MODSRC2,
    [OV.UNI_TYPE] = {
        { value = 0, label = "OFF" },
        { value = 1, label = "2 VOICES" },
        { value = 2, label = "3 VOICES" },
        { value = 3, label = "6 VOICES" },
    },
    [OV.UNI_MODE] = {
        { value = 0, label = "FIXED" },
        { value = 1, label = "DYNAMIC" },
    },
    [OV.SCALE_TYPE] = {
        { value = 0,  label = "Equal Temp" },
        { value = 1,  label = "Pure Major" },
        { value = 2,  label = "Pure Minor" },
        { value = 3,  label = "Arabic" },
        { value = 4,  label = "Pythagorean" },
        { value = 5,  label = "Werckmeister" },
        { value = 6,  label = "Kirnberger" },
        { value = 7,  label = "Slendro" },
        { value = 8,  label = "Pelog" },
        { value = 9,  label = "User Scale 1" },
        { value = 10, label = "User Scale 2" },
    },
    [OV.SCALE_KEY] = {
        { value = 0,  label = "C" },  { value = 1,  label = "C#" },
        { value = 2,  label = "D" },  { value = 3,  label = "D#" },
        { value = 4,  label = "E" },  { value = 5,  label = "F" },
        { value = 6,  label = "F#" }, { value = 7,  label = "G" },
        { value = 8,  label = "G#" }, { value = 9,  label = "A" },
        { value = 10, label = "A#" }, { value = 11, label = "B" },
    },
    [OV.ARP_PAT] = {
        { value = 0,  label = "UP" },     { value = 1,  label = "DOWN" },
        { value = 2,  label = "ALT 1" },  { value = 3,  label = "ALT 2" },
        { value = 4,  label = "RANDOM" }, { value = 5,  label = "USER 1-1" },
        { value = 6,  label = "USER 1-2" },{ value = 7,  label = "USER 1-3" },
        { value = 8,  label = "USER 1-4" },{ value = 9,  label = "USER 1-5" },
        { value = 10, label = "USER 2-1" },{ value = 11, label = "USER 2-2" },
        { value = 12, label = "USER 2-3" },{ value = 13, label = "USER 2-4" },
        { value = 14, label = "USER 2-5" },{ value = 15, label = "USER 3-1" },
        { value = 16, label = "USER 3-2" },{ value = 17, label = "USER 3-3" },
        { value = 18, label = "USER 3-4" },{ value = 19, label = "USER 3-5" },
    },
    [OV.ARP_RESO] = {
        { value = 0, label = "1/16 Tri (16T)" },
        { value = 1, label = "1/16" },
        { value = 2, label = "1/8 Tri (8T)" },
        { value = 3, label = "1/8" },
        { value = 4, label = "1/4 Tri (4T)" },
        { value = 5, label = "1/4" },
    },
    [OV.ARP_OCT] = {
        { value = 0, label = "1 Octave" },
        { value = 1, label = "2 Octaves" },
        { value = 2, label = "3 Octaves" },
        { value = 3, label = "4 Octaves" },
    },
    [OV.SW1_FUNC] = {
        { value = 0, label = "Mod.SW1(CC#80)" },
        { value = 1, label = "MasterFX(CC#92)" },
        { value = 2, label = "FX1 SW(CC#94)" },
        { value = 3, label = "FX2 SW(CC#95)" },
        { value = 4, label = "Octave Up" },
        { value = 5, label = "Octave Down" },
        { value = 6, label = "Mono SW(CC#18)" },
        { value = 7, label = "Unison(CC#75)" },
    },
    [OV.SW2_FUNC] = {
        { value = 0, label = "Mod.SW2(CC#81)" },
        { value = 1, label = "MasterFX(CC#92)" },
        { value = 2, label = "FX1 SW(CC#94)" },
        { value = 3, label = "FX2 SW(CC#95)" },
        { value = 4, label = "Octave Up" },
        { value = 5, label = "Octave Down" },
        { value = 6, label = "Mono SW(CC#18)" },
        { value = 7, label = "Unison(CC#75)" },
    },
    [OV.FSW_FUNC] = {
        { value = 0,  label = "Foot SW(CC#82)" },
        { value = 1,  label = "Damper(CC#64)" },
        { value = 2,  label = "Porta SW(CC#65)" },
        { value = 3,  label = "Sostenuto(CC#66)" },
        { value = 4,  label = "MasterFX(CC#92)" },
        { value = 5,  label = "FX1 SW(CC#94)" },
        { value = 6,  label = "FX2 SW(CC#95)" },
        { value = 7,  label = "Octave Up" },
        { value = 8,  label = "Octave Down" },
        { value = 9,  label = "Mono SW(CC#18)" },
        { value = 10, label = "Unison(CC#75)" },
        { value = 11, label = "Arpeggio SW" },
        { value = 12, label = "Pad Hold" },
    },
    [OV.PED_FUNC] = {
        { value = 0, label = "Foot Ped(CC#4)" },
        { value = 1, label = "Breath(CC#2)" },
        { value = 2, label = "PortaTime(CC#5)" },
        { value = 3, label = "Volume(CC#7)" },
        { value = 4, label = "Panpot(CC#10)" },
        { value = 5, label = "Expr(CC#11)" },
    },
    [OV.LATCH_MODE] = {
        { value = 0, label = "LATCH" },
        { value = 1, label = "UNLATCH" },
    },
}

-- ============================================================================
-- 2. Static Control Map (Slots 1..32 -> Z1 IDs 17..30, 366..383)
-- ============================================================================

STATIC_COMMON_MAP = {
    -- Control Set 1: Program Common & Unison (IDs 17..27, 30)
    [1]  = { id = 17,  kind = "list", ov = OV.CATEGORY },
    [2]  = { id = 18,  kind = "list", ov = OV.USER_GRP },
    [3]  = { id = 21,  kind = "list", ov = OV.VOICE_MODE },
    [4]  = { id = 20,  kind = "list", ov = OV.KEY_PRIO },
    [5]  = { id = 19,  kind = "list", ov = OV.OFF_ON },
    [6]  = { id = 22,  kind = "list", ov = OV.MODSRC2 },
    [7]  = { id = 23,  kind = "num" },
    [8]  = { id = 25,  kind = "list", ov = OV.OFF_ON },
    [9]  = { id = 24,  kind = "list", ov = OV.UNI_TYPE },
    [10] = { id = 26,  kind = "list", ov = OV.UNI_MODE },
    [11] = { id = 27,  kind = "num" },
    [12] = { id = 30,  kind = "num" },
    -- Control Set 2: Scale (IDs 28..29) & Link Arpeggio (IDs 374..383)
    [13] = { id = 29,  kind = "list", ov = OV.SCALE_TYPE },
    [14] = { id = 28,  kind = "list", ov = OV.SCALE_KEY },
    [15] = { id = 374, kind = "list", ov = OV.ARP_PAT },
    [16] = { id = 383, kind = "num" },
    [17] = { id = 382, kind = "list", ov = OV.ARP_RESO },
    [18] = { id = 377, kind = "list", ov = OV.ARP_OCT },
    [19] = { id = 375, kind = "list", ov = OV.OFF_ON },
    [20] = { id = 376, kind = "list", ov = OV.OFF_ON },
    [21] = { id = 378, kind = "list", ov = OV.OFF_ON },
    [22] = { id = 379, kind = "list", ov = OV.OFF_ON },
    [23] = { id = 380, kind = "num" },
    [24] = { id = 381, kind = "num" },
    -- Control Set 3: Assignable Controllers (IDs 366..373)
    [25] = { id = 366, kind = "list", ov = OV.SW1_FUNC },
    [26] = { id = 367, kind = "list", ov = OV.LATCH_MODE },
    [27] = { id = 368, kind = "list", ov = OV.SW2_FUNC },
    [28] = { id = 369, kind = "list", ov = OV.LATCH_MODE },
    [29] = { id = 370, kind = "list", ov = OV.FSW_FUNC },
    [30] = { id = 371, kind = "list", ov = OV.LATCH_MODE },
    [31] = { id = 372, kind = "list", ov = OV.PED_FUNC },
    [32] = { id = 373, kind = "list", ov = OV.OFF_ON },
}

-- ============================================================================
-- 3. Program Name State (IDs 1..16) & SysEx Builders
-- ============================================================================

programNameChars = {
    0x49, 0x6E, 0x69, 0x74, 0x20, 0x50, 0x72, 0x6F,
    0x67, 0x72, 0x61, 0x6D, 0x20, 0x20, 0x20, 0x20,
} -- Default: "Init Program    "
selectedCharPos = 1
local suppressCharCallback = false

function getProgramNameString()
    local chars = {}
    for i = 1, 16 do
        local c = programNameChars[i] or 0x20
        if c < 0x20 or c > 0x7F then c = 0x20 end
        chars[i] = string.char(c)
    end
    return table.concat(chars)
end

-- Helper to populate Program Name from an unpacked Z1 Program Dump (bytes 1..16) without echoing SysEx
function setProgramNameFromDump(unpackedBytes)
    if type(unpackedBytes) ~= "table" then
        return
    end
    for i = 1, 16 do
        local b = unpackedBytes[i]
        if type(b) == "number" and b >= 0x20 and b <= 0x7F then
            programNameChars[i] = b
        else
            programNameChars[i] = 0x20
        end
    end
    local charCtrl = controls.get(34)
    if charCtrl then
        suppressCharCallback = true
        charCtrl:getValue("value"):updateValue(programNameChars[selectedCharPos])
        suppressCharCallback = false
    end
    local dispCtrl = preset.getControl(35)
    if dispCtrl then
        dispCtrl:repaint()
    end
end

function fmtArpSpeed(_valueObject, value)
    return string.format("%d BPM", math.floor(value) + 30)
end

function fmtAsciiChar(_valueObject, value)
    local v = math.floor(value)
    if v < 0x20 or v > 0x7F then v = 0x20 end
    if v == 0x20 then
        return "SPC (32)"
    elseif v == 0x7F then
        return "DEL (127)"
    end
    return string.format("'%s' (%d)", string.char(v), v)
end

function paintProgramName(control)
    local bounds = control:getBounds()
    local w = bounds[WIDTH]
    local h = bounds[HEIGHT]
    graphics.setColor(0x18202C)
    graphics.fillRect(0, 0, w, h)
    graphics.setColor(0x529DEC)
    graphics.drawRect(0, 0, w, h)

    local nameStr = getProgramNameString()
    local curChar = string.sub(nameStr, selectedCharPos, selectedCharPos)
    graphics.setColor(ORANGE)
    graphics.print(6, 3, string.format("PROGRAM NAME [Pos %02d: '%s']", selectedCharPos, curChar), w - 12, LEFT, REGULAR, SMALL)

    graphics.setColor(WHITE)
    graphics.print(6, 23, nameStr, w - 12, LEFT, BOLD, MEDIUM)
end

function buildParamChangeBody(paramId, signedVal, gCh)
    local g = gCh or getGlobalChannel()
    local id14 = paramId & 0x3FFF
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

local function sendParamChange(paramId, signedVal)
    local dev = preset.getDevice(DEVICE_ID)
    local body = buildParamChangeBody(paramId, signedVal)
    if dev then
        dev:sendSysex(body)
    else
        midi.sendSysex(PORT_1, body)
    end
end

-- ============================================================================
-- 4. Control Callbacks
-- ============================================================================

function onStaticCommon(valueObject, value)
    local ctrlId = valueObject:getControl():getId()
    local spec = STATIC_COMMON_MAP[ctrlId]
    if not spec then
        return
    end
    local v = math.floor(value)
    local z1Val = v
    if spec.kind == "list" then
        local ov = overlays.get(spec.ov)
        z1Val = (ov and ov:getValueByIndex(v)) or v
    end
    sendParamChange(spec.id, z1Val)
end

function onNamePos(_valueObject, value)
    local pos = math.floor(value)
    if pos < 1 then pos = 1 elseif pos > 16 then pos = 16 end
    selectedCharPos = pos
    local charCtrl = controls.get(34)
    if charCtrl then
        suppressCharCallback = true
        charCtrl:getValue("value"):updateValue(programNameChars[selectedCharPos] or 0x20)
        suppressCharCallback = false
    end
    local dispCtrl = preset.getControl(35)
    if dispCtrl then
        dispCtrl:repaint()
    end
end

function onNameChar(_valueObject, value)
    if suppressCharCallback then
        return
    end
    local ascii = math.floor(value)
    if ascii < 0x20 then ascii = 0x20 elseif ascii > 0x7F then ascii = 0x7F end
    programNameChars[selectedCharPos] = ascii
    sendParamChange(selectedCharPos, ascii)
    local dispCtrl = preset.getControl(35)
    if dispCtrl then
        dispCtrl:repaint()
    end
end

-- ============================================================================
-- 5. Lifecycle Hooks
-- ============================================================================

function preset.onLoad()
    for ovId, items in pairs(ENUM_DEFS) do
        overlays.create(ovId, items)
    end
    local dispCtrl = preset.getControl(35)
    if dispCtrl then
        dispCtrl:setPaintCallback(paintProgramName)
    end
end

function preset.onReady()
    for cid, spec in pairs(STATIC_COMMON_MAP) do
        if spec.kind == "list" then
            controls.get(cid):getValue("value"):setOverlayId(spec.ov)
        end
    end
    local dispCtrl = preset.getControl(35)
    if dispCtrl then
        dispCtrl:repaint()
    end
    info.setText("Z1 Common & Arp Ready")
end
