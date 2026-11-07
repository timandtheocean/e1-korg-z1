-- Korg Z1 - Phase 2: OSC1 Dynamic Model Editor for Electra One mk2
-- Firmware 5.0+ (Lua 5.4, 32-bit integers)

local DEVICE_ID = 1
local ACTIVE_PAGE = 1

-- Global MIDI channel (0..15). Default 0 (MIDI Channel 1); also reads device channel - 1.
local function getGlobalChannel()
    local dev = preset.getDevice(DEVICE_ID)
    if dev then
        return (dev:getChannel() - 1) & 0x0F
    end
    return 0
end

-- ============================================================================
-- 1. In-memory Modulation Source Lists & Enums (Single Source of Truth)
-- ============================================================================

-- Modulation Source List 1 (49 entries, values 0..48 contiguous)
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

-- Modulation Source List 2 (36 entries, values 0 and 11..45; prepared for FX/Common)
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

-- OSC1 Oscillator Types (0..12)
OSC_TYPES = {
    { value = 0,  label = "Standard OSC" },
    { value = 1,  label = "Comb Filter" },
    { value = 2,  label = "VPM OSC" },
    { value = 3,  label = "Resonance OSC" },
    { value = 4,  label = "Ring Mod OSC" },
    { value = 5,  label = "Cross Mod OSC" },
    { value = 6,  label = "Sync OSC" },
    { value = 7,  label = "Organ Model" },
    { value = 8,  label = "E.Piano Model" },
    { value = 9,  label = "Brass Model" },
    { value = 10, label = "Reed Model" },
    { value = 11, label = "Plucked String" },
    { value = 12, label = "Bowed String" },
}

-- Overlay IDs
local OV = {
    OSC_TYPE   = 1,
    MODSRC1    = 2,
    MODSRC2    = 3,
    SAW_PULSE  = 10,
    LFO_6_9    = 11,
    CLIP_RESO  = 12,
    COMB_IN    = 13,
    WAVE_4     = 14,
    TYPE_1_2   = 15,
    VPM_MOD_W  = 16,
    OSC_IN_5   = 17,
    ORGAN_WAVE = 18,
    TRIG_MODE  = 19,
    BRASS_INST = 20,
    SMOOTH_JMP = 21,
    EG_1_5     = 22,
    REED_INST  = 23,
    OFF_ON     = 24,
}

local ENUM_DEFS = {
    [OV.OSC_TYPE]  = OSC_TYPES,
    [OV.MODSRC1]   = MODSRC1,
    [OV.MODSRC2]   = MODSRC2,
    [OV.SAW_PULSE] = {
        { value = 0, label = "SAW" },
        { value = 1, label = "PULSE" },
    },
    [OV.LFO_6_9] = {
        { value = 6, label = "LFO1" },
        { value = 7, label = "LFO2" },
        { value = 8, label = "LFO3" },
        { value = 9, label = "LFO4" },
    },
    [OV.CLIP_RESO] = {
        { value = 0, label = "CLIP" },
        { value = 1, label = "RESO" },
    },
    [OV.COMB_IN] = {
        { value = 0, label = "OSC2+Noise" },
        { value = 1, label = "SubOSC+Noise" },
        { value = 2, label = "Filter1+Noise" },
        { value = 3, label = "Filter2+Noise" },
        { value = 4, label = "Pulse Noise" },
        { value = 5, label = "Impulse" },
    },
    [OV.WAVE_4] = {
        { value = 0, label = "SAW" },
        { value = 1, label = "SQU" },
        { value = 2, label = "TRI" },
        { value = 3, label = "SIN" },
    },
    [OV.TYPE_1_2] = {
        { value = 0, label = "Type 1" },
        { value = 1, label = "Type 2" },
    },
    [OV.VPM_MOD_W] = {
        { value = 0, label = "SAW" },
        { value = 1, label = "SQU" },
        { value = 2, label = "TRI" },
        { value = 3, label = "SIN" },
        { value = 4, label = "OSC2" },
        { value = 5, label = "Sub OSC" },
        { value = 6, label = "Filter1" },
        { value = 7, label = "Filter2" },
    },
    [OV.OSC_IN_5] = {
        { value = 0, label = "OSC2" },
        { value = 1, label = "Sub OSC" },
        { value = 2, label = "Noise" },
        { value = 3, label = "Filter1" },
        { value = 4, label = "Filter2" },
    },
    [OV.ORGAN_WAVE] = {
        { value = 0, label = "SIN1" },
        { value = 1, label = "SIN2" },
        { value = 2, label = "SIN3" },
        { value = 3, label = "TRI" },
    },
    [OV.TRIG_MODE] = {
        { value = 0, label = "SINGLE" },
        { value = 1, label = "MULTI" },
    },
    [OV.BRASS_INST] = {
        { value = 0, label = "Brass 1" },
        { value = 1, label = "Brass 2" },
        { value = 2, label = "Brass 3" },
        { value = 3, label = "Horn 1" },
        { value = 4, label = "Horn 2" },
        { value = 5, label = "ReedBrass" },
    },
    [OV.SMOOTH_JMP] = {
        { value = 0, label = "Smooth" },
        { value = 1, label = "Jump" },
    },
    [OV.EG_1_5] = {
        { value = 1, label = "EG1" },
        { value = 2, label = "EG2" },
        { value = 3, label = "EG3" },
        { value = 4, label = "EG4" },
        { value = 5, label = "Amp EG" },
    },
    [OV.REED_INST] = {
        { value = 0,  label = "Hard Sax 1" },
        { value = 1,  label = "Hard Sax 2" },
        { value = 2,  label = "Hard Sax 3" },
        { value = 3,  label = "Soft Sax 1" },
        { value = 4,  label = "Soft Sax 2" },
        { value = 5,  label = "DoubleReed 1" },
        { value = 6,  label = "DoubleReed 2" },
        { value = 7,  label = "Bassoon" },
        { value = 8,  label = "Clarinet" },
        { value = 9,  label = "Flute 1" },
        { value = 10, label = "Flute 2" },
        { value = 11, label = "PanFlute" },
        { value = 12, label = "Ocarina" },
        { value = 13, label = "Shakuhachi" },
        { value = 14, label = "Harmonica 1" },
        { value = 15, label = "Harmonica 2" },
        { value = 16, label = "ReedSynth" },
    },
    [OV.OFF_ON] = {
        { value = 0, label = "OFF" },
        { value = 1, label = "ON" },
    },
}

-- Helper constructors for model parameter descriptors
local function num(id, name, min, max, fmt, color)
    return { id = id, name = name, kind = "num", min = min, max = max, fmt = fmt, color = color or WHITE }
end

local function lst(id, name, ov, color)
    local c = color or (ov == OV.MODSRC1 and BLUE or PURPLE)
    return { id = id, name = name, kind = "list", ov = ov, color = c }
end

local function mod1(id, name)
    return lst(id, name, OV.MODSRC1, BLUE)
end

local function mint(id, name, min, max)
    return num(id, name, min or -99, max or 99, nil, GREEN)
end

-- ============================================================================
-- 2. All 13 OSC1 Models (IDs 464..754, ExID = 1)
-- ============================================================================
MODELS = {
    -- 0: Standard OSC (22 params)
    [0] = {
        lst(464,  "Wave",           OV.SAW_PULSE, ORANGE),
        num(465,  "Wave Edge",      0, 99, nil, ORANGE),
        num(466,  "Wave Level",     0, 99),
        num(467,  "Tri Level",      0, 99),
        num(468,  "Sine Level",     0, 99),
        num(469,  "Tri Phase",      -99, 99, nil, ORANGE),
        num(470,  "Wave Form",      -99, 99, nil, ORANGE),
        lst(471,  "WF Mod LFO",     OV.LFO_6_9, BLUE),
        mint(472, "WF LFO Int"),
        mod1(473, "WF Mod Src"),
        mint(474, "WF Mod Int"),
        num(475,  "WS In Level",    0, 99, nil, RED),
        mod1(476, "WS In ModSrc"),
        mint(477, "WS In ModInt"),
        num(478,  "WS Offset",      -99, 99, nil, RED),
        lst(479,  "WS Table",       OV.CLIP_RESO, RED),
        num(480,  "Wave Shape",     0, 99, nil, RED),
        mod1(481, "WS Mod Src"),
        mint(482, "WS Mod Int"),
        num(483,  "WS Balance",     0, 99, nil, RED),
        mod1(484, "WS Bal Src"),
        mint(485, "WS Bal Int"),
    },

    -- 1: Comb Filter OSC (14 params)
    [1] = {
        lst(486,  "Input Sel",      OV.COMB_IN, ORANGE),
        num(487,  "In Wave Lvl",    0, 99),
        num(488,  "Noise Level",    0, 99),
        num(489,  "Width",          0, 99, nil, RED),
        mod1(490, "In Lvl Src"),
        mint(491, "In Lvl Int"),
        num(492,  "Feedback",       0, 99, nil, RED),
        mod1(493, "FB Mod1 Src"),
        mint(494, "FB Mod1 Int"),
        mod1(495, "FB Mod2 Src"),
        mint(496, "FB Mod2 Int"),
        num(497,  "High Damp",      0, 99, nil, ORANGE),
        mod1(498, "HiDamp Src"),
        mint(499, "HiDamp Int"),
    },

    -- 2: VPM OSC (25 params)
    [2] = {
        lst(500,  "Car Wave",       OV.WAVE_4, ORANGE),
        num(501,  "Car Level",      0, 99),
        mod1(502, "CarLvl Src1"),
        mint(503, "CarLvl Int1"),
        mod1(504, "CarLvl Src2"),
        mint(505, "CarLvl Int2"),
        num(506,  "Car W.Shape",    0, 99, nil, RED),
        mod1(507, "CarWS Src1"),
        mint(508, "CarWS Int1"),
        mod1(509, "CarWS Src2"),
        mint(510, "CarWS Int2"),
        lst(511,  "Car WS Type",    OV.TYPE_1_2, RED),
        num(512,  "Car Feedback",   0, 99, nil, RED),
        num(513,  "Mod Coarse",     0, 16, "coarse", ORANGE),
        num(514,  "Mod Fine",       -50, 50, nil, ORANGE),
        mod1(515, "ModFrq Src1"),
        mint(516, "ModFrq Int1"),
        mod1(517, "ModFrq Src2"),
        mint(518, "ModFrq Int2"),
        lst(519,  "Mod Wave",       OV.VPM_MOD_W, ORANGE),
        num(520,  "Mod Level",      0, 99),
        mod1(521, "ModLvl Src1"),
        mint(522, "ModLvl Int1"),
        mod1(523, "ModLvl Src2"),
        mint(524, "ModLvl Int2"),
    },

    -- 3: Resonance OSC (32 params)
    [3] = {
        lst(525,  "Input Sel",      OV.OSC_IN_5, ORANGE),
        num(526,  "Input Level",    0, 99),
        mod1(527, "InLvl Src1"),
        mint(528, "InLvl Int1"),
        mod1(529, "InLvl Src2"),
        mint(530, "InLvl Int2"),
        num(531,  "BPF1 Reso",      0, 99, nil, RED),
        num(532,  "BPF1 Harm",      0, 15, "plus1", ORANGE),
        mod1(533, "BPF1 HrmSrc"),
        mint(534, "BPF1 HrmInt",    -15, 15),
        num(535,  "BPF1 Fine",      -99, 99, nil, ORANGE),
        num(536,  "BPF1 Level",     0, 99),
        num(537,  "BPF2 Reso",      0, 99, nil, RED),
        num(538,  "BPF2 Harm",      0, 15, "plus1", ORANGE),
        mod1(539, "BPF2 HrmSrc"),
        mint(540, "BPF2 HrmInt",    -15, 15),
        num(541,  "BPF2 Fine",      -99, 99, nil, ORANGE),
        num(542,  "BPF2 Level",     0, 99),
        num(543,  "BPF3 Reso",      0, 99, nil, RED),
        num(544,  "BPF3 Harm",      0, 15, "plus1", ORANGE),
        mod1(545, "BPF3 HrmSrc"),
        mint(546, "BPF3 HrmInt",    -15, 15),
        num(547,  "BPF3 Fine",      -99, 99, nil, ORANGE),
        num(548,  "BPF3 Level",     0, 99),
        num(549,  "BPF4 Reso",      0, 99, nil, RED),
        num(550,  "BPF4 Harm",      0, 15, "plus1", ORANGE),
        mod1(551, "BPF4 HrmSrc"),
        mint(552, "BPF4 HrmInt",    -15, 15),
        num(553,  "BPF4 Fine",      -99, 99, nil, ORANGE),
        num(554,  "BPF4 Level",     0, 99),
        mod1(555, "Reso ModSrc"),
        mint(556, "Reso ModInt"),
    },

    -- 4: Ring Mod.OSC (9 params)
    [4] = {
        lst(557,  "Input Sel",      OV.OSC_IN_5, ORANGE),
        lst(558,  "Carrier Wave",   OV.WAVE_4, ORANGE),
        num(559,  "Mod Depth",      0, 99, nil, RED),
        mod1(560, "Depth Src1"),
        mint(561, "Depth Int1"),
        mod1(562, "Depth Src2"),
        mint(563, "Depth Int2"),
        lst(564,  "Ring Type",      OV.TYPE_1_2, PURPLE),
        num(565,  "Wave Edge",      0, 99, nil, ORANGE),
    },

    -- 5: Cross Mod.OSC (8 params)
    [5] = {
        lst(566,  "Input Sel",      OV.OSC_IN_5, ORANGE),
        lst(567,  "Carrier Wave",   OV.WAVE_4, ORANGE),
        num(568,  "Mod Depth",      0, 99, nil, RED),
        mod1(569, "Depth Src1"),
        mint(570, "Depth Int1"),
        mod1(571, "Depth Src2"),
        mint(572, "Depth Int2"),
        num(573,  "Wave Edge",      0, 99, nil, ORANGE),
    },

    -- 6: Sync OSC (3 params)
    [6] = {
        lst(574,  "Input Sel",      OV.OSC_IN_5, ORANGE),
        lst(575,  "Slave Wave",     OV.WAVE_4, ORANGE),
        num(576,  "Wave Edge",      0, 99, nil, ORANGE),
    },

    -- 7: Organ Model (25 params)
    [7] = {
        lst(577,  "DB1 Wave",       OV.ORGAN_WAVE, ORANGE),
        num(578,  "DB1 Harm",       0, 15, "plus1", ORANGE),
        num(579,  "DB1 Fine",       -99, 99, nil, ORANGE),
        num(580,  "DB1 Level",      0, 99),
        mod1(581, "DB1 Lvl Src"),
        mint(582, "DB1 Lvl Int"),
        num(583,  "DB1 PercLvl",    0, 99, nil, RED),
        lst(584,  "DB2 Wave",       OV.ORGAN_WAVE, ORANGE),
        num(585,  "DB2 Harm",       0, 15, "plus1", ORANGE),
        num(586,  "DB2 Fine",       -99, 99, nil, ORANGE),
        num(587,  "DB2 Level",      0, 99),
        mod1(588, "DB2 Lvl Src"),
        mint(589, "DB2 Lvl Int"),
        num(590,  "DB2 PercLvl",    0, 99, nil, RED),
        lst(591,  "DB3 Wave",       OV.ORGAN_WAVE, ORANGE),
        num(592,  "DB3 Harm",       0, 15, "plus1", ORANGE),
        num(593,  "DB3 Fine",       -99, 99, nil, ORANGE),
        num(594,  "DB3 Level",      0, 99),
        mod1(595, "DB3 Lvl Src"),
        mint(596, "DB3 Lvl Int"),
        num(597,  "DB3 PercLvl",    0, 99, nil, RED),
        lst(598,  "Perc Trig",      OV.TRIG_MODE, PURPLE),
        num(599,  "Perc Decay",     0, 99, nil, RED),
        mod1(600, "Perc ModSrc"),
        mint(601, "Perc ModInt"),
    },

    -- 8: E. Piano Model (14 params)
    [8] = {
        num(602,  "Hammer Force",   0, 99, nil, RED),
        num(603,  "Force VelCrv",   -1, 99, "offneg", GREEN),
        num(604,  "Hammer Width",   0, 99, nil, RED),
        num(605,  "Click Level",    0, 99),
        num(606,  "Tone Decay",     0, 99),
        num(607,  "Tone Release",   0, 99),
        num(608,  "Overtone Lvl",   0, 99, nil, ORANGE),
        num(609,  "Overtone Frq",   0, 99, nil, ORANGE),
        num(610,  "Overtone Dec",   0, 99, nil, ORANGE),
        num(611,  "Pickup Pos",     0, 99, nil, RED),
        mod1(612, "Pickup Src"),
        mint(613, "Pickup Int"),
        num(614,  "Low EQ Freq",    0, 49, nil, ORANGE),
        num(615,  "Low EQ Gain",    -18, 18, "db", ORANGE),
    },

    -- 9: Brass Model (19 active params; reserved IDs skipped)
    [9] = {
        lst(616,  "Inst Type",      OV.BRASS_INST, ORANGE),
        lst(617,  "PitchBend +",    OV.SMOOTH_JMP, PURPLE),
        lst(618,  "PitchBend -",    OV.SMOOTH_JMP, PURPLE),
        lst(619,  "Pressure EG",    OV.EG_1_5, BLUE),
        mint(620, "Press EG Int"),
        mod1(621, "Press Src1"),
        mint(622, "Press Int1"),
        mod1(623, "Press Src2"),
        mint(624, "Press Int2"),
        num(626,  "Lip Char",       0, 99, nil, RED),
        mod1(627, "Lip Mod Src"),
        mint(628, "Lip Mod Int"),
        num(632,  "Bell Tone",      0, 99, nil, ORANGE),
        num(633,  "Bell Reso",      0, 99, nil, RED),
        num(634,  "Noise Level",    0, 99),
        num(645,  "PEQ Freq",       0, 49, nil, ORANGE),
        num(646,  "PEQ Q",          0, 29, nil, ORANGE),
        num(647,  "PEQ Gain",       -18, 18, "db", ORANGE),
        num(648,  "Strength",       0, 99, nil, RED),
    },

    -- 10: Reed Model (22 active params; reserved IDs skipped)
    [10] = {
        lst(654,  "Inst Type",      OV.REED_INST, ORANGE),
        lst(655,  "PitchBend +",    OV.SMOOTH_JMP, PURPLE),
        lst(656,  "PitchBend -",    OV.SMOOTH_JMP, PURPLE),
        lst(657,  "Pressure EG",    OV.EG_1_5, BLUE),
        mint(658, "Press EG Int"),
        mod1(659, "Press Src1"),
        mint(660, "Press Int1"),
        mod1(661, "Press Src2"),
        mint(662, "Press Int2"),
        num(668,  "Noise Level",    0, 99),
        mod1(681, "Reed ModSrc"),
        mint(682, "Reed ModInt"),
        num(683,  "HPF Cutoff",     0, 99, nil, RED),
        num(684,  "HPF Reso",       0, 99, nil, RED),
        num(685,  "PEQ Freq",       0, 49, nil, ORANGE),
        num(686,  "PEQ Q",          0, 29, nil, ORANGE),
        num(687,  "PEQ Gain",       -18, 18, "db", ORANGE),
        num(689,  "WS Offset",      -99, 99, nil, RED),
        lst(690,  "WS Table",       OV.CLIP_RESO, RED),
        num(691,  "Wave Shape",     0, 99, nil, RED),
        mod1(692, "WS Mod Src"),
        mint(693, "WS Mod Int"),
    },

    -- 11: Plucked String Model (31 params)
    [11] = {
        num(694,  "Attack Lvl",     0, 99),
        mint(695, "Atk Lvl Vel"),
        num(696,  "Atk Crv Up",     0, 99, nil, RED),
        mint(697, "Crv Up Vel"),
        num(698,  "Atk Crv Dwn",    0, 99, nil, RED),
        mint(699, "Crv Dwn Vel"),
        num(700,  "Atk Noise",      0, 99),
        mint(701, "AtkNoiseVel"),
        num(702,  "String Pos",     0, 99, nil, RED),
        mod1(703, "StrPos Src"),
        mint(704, "StrPos Int"),
        num(705,  "Dispersion",     0, 99, nil, ORANGE),
        mod1(706, "Disp ModSrc"),
        mint(707, "Disp ModInt"),
        num(708,  "Damping",        0, 99, nil, ORANGE),
        mint(709, "Damp KeyTrk"),
        mod1(710, "Damp ModSrc"),
        mint(711, "Damp ModInt"),
        num(712,  "Decay",          0, 99),
        mint(713, "Decay KeyTrk"),
        num(714,  "Release",        0, 99),
        num(715,  "Harmonics",      0, 99, nil, ORANGE),
        mod1(716, "Harm ModSrc"),
        mint(717, "Harm ModInt"),
        lst(718,  "Pickup SW",      OV.OFF_ON, PURPLE),
        num(719,  "Pickup Pos",     0, 99, nil, RED),
        mod1(720, "Pickup Src"),
        mint(721, "Pickup Int"),
        num(722,  "Low EQ Freq",    0, 49, nil, ORANGE),
        num(723,  "Low EQ Gain",    -18, 18, "db", ORANGE),
        num(724,  "Low Boost",      0, 99, nil, ORANGE),
    },

    -- 12: Bowed String Model (30 params)
    [12] = {
        lst(725,  "BowSpd EG",      OV.EG_1_5, BLUE),
        mint(726, "BowSpd EGInt"),
        mod1(727, "BowSpd Src1"),
        mint(728, "BowSpd Int1"),
        mod1(729, "BowSpd Src2"),
        mint(730, "BowSpd Int2"),
        lst(731,  "Bow Diff",       OV.OFF_ON, PURPLE),
        lst(732,  "Pressure EG",    OV.EG_1_5, BLUE),
        mint(733, "Press EG Int"),
        mod1(734, "Press ModSrc"),
        mint(735, "Press ModInt"),
        num(736,  "Rosin Amt",      0, 99, nil, RED),
        num(737,  "String Pos",     0, 99, nil, RED),
        mod1(738, "StrPos Src"),
        mint(739, "StrPos Int"),
        num(740,  "Damping",        0, 99, nil, ORANGE),
        num(741,  "Damp TrkKey",    0, 127, "note", ORANGE),
        mint(742, "Damp Lo Int"),
        mint(743, "Damp Hi Int"),
        mod1(744, "Damp ModSrc"),
        mint(745, "Damp ModInt"),
        num(746,  "Dispersion",     0, 99, nil, ORANGE),
        mod1(747, "Disp ModSrc"),
        mint(748, "Disp ModInt"),
        num(749,  "Reflection",     0, 99, nil, RED),
        mod1(750, "Refl ModSrc"),
        mint(751, "Refl ModInt"),
        num(752,  "PEQ Freq",       0, 49, nil, ORANGE),
        num(753,  "PEQ Q",          0, 29, nil, ORANGE),
        num(754,  "PEQ Gain",       -18, 18, "db", ORANGE),
    },
}

-- ============================================================================
-- 3. SysEx Builder & Sender
-- ============================================================================

-- Build Korg Z1 Parameter Change body (without F0/F7) for group 01 (Program)
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
-- 4. Dynamic Page Relayout & Control Callbacks
-- ============================================================================

-- Active parameter definition for each slot 2..36 on Page 1
local activeSlotDef = {}
local currentModel = 0
local suppressSlot = {}

local NOTE_NAMES = { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" }

function fmtSlot(valueObject, value)
    local ctrlId = valueObject:getControl():getId()
    local slot = ctrlId % 100
    local def = activeSlotDef[slot]
    local v = math.floor(value)
    if not def or not def.fmt then
        return tostring(v)
    end
    if def.fmt == "plus1" then
        return tostring(v + 1)
    elseif def.fmt == "coarse" then
        return v == 0 and "0.5" or tostring(v)
    elseif def.fmt == "offneg" then
        return v < 0 and "OFF" or tostring(v)
    elseif def.fmt == "db" then
        return string.format("%+d dB", v)
    elseif def.fmt == "note" then
        local n = NOTE_NAMES[(v % 12) + 1]
        local oct = (v // 12) - 1
        return string.format("%s%d", n, oct)
    end
    return tostring(v)
end

function applyModel(modelIdx)
    local defs = MODELS[modelIdx]
    if not defs then
        return
    end
    currentModel = modelIdx
    activeSlotDef = {}
    suppressSlot = {}

    window.stop()

    local pageTitle = OSC_TYPES[modelIdx + 1] and OSC_TYPES[modelIdx + 1].label or "OSC1"
    pages.get(ACTIVE_PAGE):setName("OSC1: " .. pageTitle)
    local grp = preset.getGroup(50)
    if grp then
        grp:setLabel("OSC1 - " .. pageTitle)
    end

    for slot = 2, 36 do
        local def = defs[slot - 1]
        local fader = controls.get(100 + slot)
        local list  = controls.get(200 + slot)

        if not def then
            fader:setVisible(false)
            list:setVisible(false)
        elseif def.kind == "list" then
            activeSlotDef[slot] = def
            fader:setVisible(false)

            local valObj = list:getValue("value")
            valObj:setOverlayId(def.ov)
            suppressSlot[200 + slot] = true
            valObj:updateValue(0)
            list:setName(def.name)
            list:setColor(def.color or PURPLE)
            list:setVisible(true)
        else
            activeSlotDef[slot] = def
            list:setVisible(false)

            local valObj = fader:getValue("value")
            local span = def.max - def.min
            local neutral = (def.min < 0 and def.max > 0) and 0 or def.min
            valObj:getMessage():setRange(0, span)
            valObj:setRange(def.min, def.max, neutral, false)
            suppressSlot[100 + slot] = true
            valObj:updateValue(neutral)
            fader:setName(def.name)
            fader:setColor(def.color or WHITE)
            fader:setVisible(true)
        end
    end

    window.resume()
end

-- Callback for Control 1 (OSC1 Type selector, slot 1)
function onOscType(valueObject, value)
    local idx = math.floor(value)
    local ov = overlays.get(OV.OSC_TYPE)
    local z1Type = (ov and ov:getValueByIndex(idx)) or idx
    sendParamChange(0, 174, z1Type)
    applyModel(z1Type)
    info.setText(OSC_TYPES[z1Type + 1] and OSC_TYPES[z1Type + 1].label or "OSC1")
end

-- Callback for Slots 2..36 (faders 102..136 and lists 202..236)
function onSlot(valueObject, value)
    local ctrl = valueObject:getControl()
    local ctrlId = ctrl:getId()
    if suppressSlot[ctrlId] then
        suppressSlot[ctrlId] = nil
        return
    end
    if not ctrl:isVisible() then
        return
    end
    local slot = ctrl:getId() % 100
    local def = activeSlotDef[slot]
    if not def then
        return
    end

    local z1Val
    if def.kind == "list" then
        local ov = overlays.get(def.ov)
        z1Val = (ov and ov:getValueByIndex(math.floor(value))) or math.floor(value)
    else
        z1Val = math.floor(value)
    end

    sendParamChange(1, def.id, z1Val)
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
    local typeVal = controls.get(1):getValue("value")
    typeVal:setOverlayId(OV.OSC_TYPE)
    typeVal:updateValue(0)
    applyModel(0)
    info.setText("Z1 OSC1 Ready")
end
