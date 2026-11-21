-- Korg Z1 - OSC Common + OSC 1 & OSC 2 Multi-Page Editor for Electra One mk2
-- Page 1: OSC Common (Jump OSC 1 / Jump OSC 2 buttons, Selected OSC 1 & OSC 2 Model LCDs, Pitch/Slope/Mod IDs 175..187 & 189..201)
-- Page 2: OSC 1 Dynamic Model Editor (ID 174 ExID 0 + all 13 OSC1 Models IDs 464..754 ExID 1 + Jump back to OSC Common)
-- Page 3: OSC 2 Dynamic Model Editor (ID 188 ExID 0 + all 9 OSC2 Models IDs 464..615 ExID 2 + Jump back to OSC Common)

local DEVICE_ID = 1
OSC_COMMON_PAGE_ID = 1
OSC1_PAGE_ID       = 2
OSC2_PAGE_ID       = 3

local function getGlobalChannel()
    local dev = preset.getDevice(DEVICE_ID)
    if dev and dev.getChannel then
        return (dev:getChannel() - 1) & 0x0F
    end
    return 0
end

-- ============================================================================
-- 1. Overlays, Model Names & Enumerations
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

OSC1_TYPES = {
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

OSC2_TYPES = {
    { value = 0, label = "Standard OSC" },
    { value = 1, label = "Comb Filter" },
    { value = 2, label = "VPM OSC" },
    { value = 3, label = "Resonance OSC" },
    { value = 4, label = "Ring Mod OSC" },
    { value = 5, label = "Cross Mod OSC" },
    { value = 6, label = "Sync OSC" },
    { value = 7, label = "Organ Model" },
    { value = 8, label = "E.Piano Model" },
}

local OV = {
    MODSRC1      = 1,
    OCTAVE       = 2,
    OSC1_TYPE    = 3,
    OSC2_TYPE    = 4,
    PRESET_TGT   = 5,
    SAW_PULSE    = 10,
    LFO_6_9      = 11,
    CLIP_RESO    = 12,
    COMB_IN_1    = 13,
    WAVE_4       = 14,
    TYPE_1_2     = 15,
    VPM_MOD_W_1  = 16,
    OSC_IN_5_1   = 17,
    ORGAN_WAVE   = 18,
    TRIG_MODE    = 19,
    BRASS_INST   = 20,
    SMOOTH_JMP   = 21,
    EG_1_5       = 22,
    REED_INST    = 23,
    OFF_ON       = 24,
    COMB_IN_2    = 25,
    VPM_MOD_W_2  = 26,
    OSC_IN_5_2   = 27,
}

local ENUM_DEFS = {
    [OV.MODSRC1]   = MODSRC1,
    [OV.OCTAVE]    = {
        { value = 0, label = "32'" },
        { value = 1, label = "16'" },
        { value = 2, label = "8'" },
        { value = 3, label = "4'" },
    },
    [OV.OSC1_TYPE] = OSC1_TYPES,
    [OV.OSC2_TYPE] = OSC2_TYPES,
    [OV.PRESET_TGT] = {
        { value = 0, label = "OSC 1" },
        { value = 1, label = "OSC 2" },
        { value = 2, label = "Both OSCs" },
    },
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
    [OV.COMB_IN_1] = {
        { value = 0, label = "OSC2+Noise" },
        { value = 1, label = "SubOSC+Noise" },
        { value = 2, label = "Filter1+Noise" },
        { value = 3, label = "Filter2+Noise" },
        { value = 4, label = "Pulse Noise" },
        { value = 5, label = "Impulse" },
    },
    [OV.COMB_IN_2] = {
        { value = 0, label = "OSC1+Noise" },
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
    [OV.VPM_MOD_W_1] = {
        { value = 0, label = "SAW" },
        { value = 1, label = "SQU" },
        { value = 2, label = "TRI" },
        { value = 3, label = "SIN" },
        { value = 4, label = "OSC2" },
        { value = 5, label = "Sub OSC" },
        { value = 6, label = "Filter1" },
        { value = 7, label = "Filter2" },
    },
    [OV.VPM_MOD_W_2] = {
        { value = 0, label = "SAW" },
        { value = 1, label = "SQU" },
        { value = 2, label = "TRI" },
        { value = 3, label = "SIN" },
        { value = 4, label = "OSC1" },
        { value = 5, label = "Sub OSC" },
        { value = 6, label = "Filter1" },
        { value = 7, label = "Filter2" },
    },
    [OV.OSC_IN_5_1] = {
        { value = 0, label = "OSC2" },
        { value = 1, label = "Sub OSC" },
        { value = 2, label = "Noise" },
        { value = 3, label = "Filter1" },
        { value = 4, label = "Filter2" },
    },
    [OV.OSC_IN_5_2] = {
        { value = 0, label = "OSC1" },
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

-- Build model table parameterized by Comb/VPM/OSC input overlay IDs (for OSC1 vs OSC2)
local function buildModels(combOv, vpmOv, oscInOv, includePhysical)
    local m = {
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
        [1] = {
            lst(486,  "Input Sel",      combOv, ORANGE),
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
            lst(519,  "Mod Wave",       vpmOv, ORANGE),
            num(520,  "Mod Level",      0, 99),
            mod1(521, "ModLvl Src1"),
            mint(522, "ModLvl Int1"),
            mod1(523, "ModLvl Src2"),
            mint(524, "ModLvl Int2"),
        },
        [3] = {
            lst(525,  "Input Sel",      oscInOv, ORANGE),
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
        [4] = {
            lst(557,  "Input Sel",      oscInOv, ORANGE),
            lst(558,  "Carrier Wave",   OV.WAVE_4, ORANGE),
            num(559,  "Mod Depth",      0, 99, nil, RED),
            mod1(560, "Depth Src1"),
            mint(561, "Depth Int1"),
            mod1(562, "Depth Src2"),
            mint(563, "Depth Int2"),
            lst(564,  "Ring Type",      OV.TYPE_1_2, PURPLE),
            num(565,  "Wave Edge",      0, 99, nil, ORANGE),
        },
        [5] = {
            lst(566,  "Input Sel",      oscInOv, ORANGE),
            lst(567,  "Carrier Wave",   OV.WAVE_4, ORANGE),
            num(568,  "Mod Depth",      0, 99, nil, RED),
            mod1(569, "Depth Src1"),
            mint(570, "Depth Int1"),
            mod1(571, "Depth Src2"),
            mint(572, "Depth Int2"),
            num(573,  "Wave Edge",      0, 99, nil, ORANGE),
        },
        [6] = {
            lst(574,  "Input Sel",      oscInOv, ORANGE),
            lst(575,  "Slave Wave",     OV.WAVE_4, ORANGE),
            num(576,  "Wave Edge",      0, 99, nil, ORANGE),
        },
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
    }
    if includePhysical then
        m[9] = {
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
        }
        m[10] = {
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
        }
        m[11] = {
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
        }
        m[12] = {
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
        }
    end
    return m
end

OSC1_MODELS = buildModels(OV.COMB_IN_1, OV.VPM_MOD_W_1, OV.OSC_IN_5_1, true)
OSC2_MODELS = buildModels(OV.COMB_IN_2, OV.VPM_MOD_W_2, OV.OSC_IN_5_2, false)

-- Map Page 1 Control ID -> Z1 Program Parameter ID (ExID = 0)
local CTRL_PARAM = {
    [2]  = 174, -- OSC1 Type
    [3]  = 175, -- OSC1 Octave
    [4]  = 176, -- OSC1 Semitone
    [5]  = 177, -- OSC1 Fine
    [6]  = 178, -- OSC1 Pitch Offset
    [8]  = 188, -- OSC2 Type
    [9]  = 189, -- OSC2 Octave
    [10] = 190, -- OSC2 Semitone
    [11] = 191, -- OSC2 Fine
    [12] = 192, -- OSC2 Pitch Offset
    [13] = 179, -- OSC1 Pitch Slope Center Key
    [14] = 180, -- OSC1 Pitch Low Slope
    [15] = 181, -- OSC1 Pitch High Slope
    [16] = 186, -- OSC1 Pitch Mod2 Source
    [17] = 187, -- OSC1 Pitch Mod2 Intensity
    [19] = 193, -- OSC2 Pitch Slope Center Key
    [20] = 194, -- OSC2 Pitch Low Slope
    [21] = 195, -- OSC2 Pitch High Slope
    [22] = 200, -- OSC2 Pitch Mod2 Source
    [23] = 201, -- OSC2 Pitch Mod2 Intensity
    [25] = 182, -- OSC1 Pitch Mod1 Source
    [26] = 183, -- OSC1 Pitch Mod1 Intensity
    [27] = 184, -- OSC1 Pitch Mod1 DynamicMod Source
    [28] = 185, -- OSC1 Pitch Mod1 DynamicMod Intensity
    [31] = 196, -- OSC2 Pitch Mod1 Source
    [32] = 197, -- OSC2 Pitch Mod1 Intensity
    [33] = 198, -- OSC2 Pitch Mod1 DynamicMod Source
    [34] = 199, -- OSC2 Pitch Mod1 DynamicMod Intensity
}

local CTRL_OV = {
    [3]  = OV.OCTAVE,
    [9]  = OV.OCTAVE,
    [16] = OV.MODSRC1,
    [22] = OV.MODSRC1,
    [25] = OV.MODSRC1,
    [27] = OV.MODSRC1,
    [31] = OV.MODSRC1,
    [33] = OV.MODSRC1,
}

selectedOsc1Model = 0
selectedOsc2Model = 0
lastJumpedPage    = 1
local suppressModelCallback = false
local suppressJumpPad = false
local activeOsc1SlotDef = {}
local activeOsc2SlotDef = {}
local suppressSlot = {}
oscSaved = {}

function getOscModelName(oscIdx)
    local isOsc2 = (oscIdx == 2)
    local sel = isOsc2 and selectedOsc2Model or selectedOsc1Model
    local ov = overlays.get(isOsc2 and OV.OSC2_TYPE or OV.OSC1_TYPE)
    return (ov and ov.getLabelByIndex and ov:getLabelByIndex(sel)) or "Standard OSC"
end

-- ============================================================================
-- 2. SysEx Builder & Sender
-- ============================================================================

function buildParamChangeBody(exId, paramId, signedVal, gCh)
    if signedVal == nil then
        -- 2-arg call: buildParamChangeBody(paramId, signedVal) with exId = 0
        signedVal = paramId
        paramId = exId
        exId = 0
    end
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
-- 3. Custom Paint Callback & Dynamic Page Relayout (Pages 2 & 3)
-- ============================================================================

function paintOscModel(control)
    local isOsc2 = (control:getId() == 8)
    local bounds = control:getBounds()
    local w = bounds[WIDTH]
    local h = bounds[HEIGHT]
    graphics.setColor(0x18202C)
    graphics.fillRect(0, 0, w, h)
    graphics.setColor(isOsc2 and 0x529DEC or 0xF49500)
    graphics.drawRect(0, 0, w, h)

    local sel = isOsc2 and selectedOsc2Model or selectedOsc1Model
    graphics.setColor(isOsc2 and 0x529DEC or ORANGE)
    graphics.print(6, 3, string.format("OSC%d MODEL [%02d]", isOsc2 and 2 or 1, sel), w - 12, LEFT, REGULAR, SMALL)

    graphics.setColor(WHITE)
    graphics.print(6, 23, getOscModelName(isOsc2 and 2 or 1), w - 12, LEFT, BOLD, MEDIUM)
end

local function repaintModelWidgets()
    for _, cid in ipairs({ 2, 8 }) do
        local c = preset.getControl(cid)
        if c then c:repaint() end
    end
end

local function applyDynamicSlots(defs, slotFrom, slotTo, slotOffset, faderBase, listBase, slotDefMap, saved, keyShift, suppress)
    for slot = slotFrom, slotTo do
        local def = defs[slot - slotOffset]
        local fid = faderBase + slot
        local tfid = faderBase + 50 + slot
        local lid = listBase + slot
        local fader = controls.get(fid)
        local thin  = controls.get(tfid)
        local list  = controls.get(lid)
        if fader and list then
            if not def then
                if fader:isVisible() then fader:setVisible(false) end
                if thin and thin:isVisible() then thin:setVisible(false) end
                if list:isVisible() then list:setVisible(false) end
            elseif def.kind == "list" then
                slotDefMap[slot] = def
                if fader:isVisible() then fader:setVisible(false) end
                if thin and thin:isVisible() then thin:setVisible(false) end
                local key = keyShift and ((keyShift << 11) | def.id) or def.id
                local initVal = saved[key]
                if initVal == nil then initVal = def.defVal or 0 end
                local vo = list:getValue("value")
                vo:setOverlayId(def.ov)
                if vo:getValue() ~= initVal then
                    suppress[lid] = true
                    vo:updateValue(initVal)
                    suppress[lid] = nil
                end
                if list:getName() ~= def.name then list:setName(def.name) end
                local col = def.color or PURPLE
                if list:getColor() ~= col then list:setColor(col) end
                if not list:isVisible() then list:setVisible(true) end
            else
                slotDefMap[slot] = def
                if list:isVisible() then list:setVisible(false) end
                local useThin = (thin ~= nil and def.name ~= nil and def.name:find("Int", 1, true) ~= nil)
                local activeFader = useThin and thin or fader
                local activeFid   = useThin and tfid or fid
                local otherFader  = useThin and fader or thin
                if otherFader and otherFader:isVisible() then otherFader:setVisible(false) end
                local key = keyShift and ((keyShift << 11) | def.id) or def.id
                local neutral = def.defVal
                if neutral == nil then
                    neutral = (def.min < 0 and def.max > 0) and 0 or def.min
                end
                local initVal = saved[key]
                if initVal == nil then initVal = neutral end
                local vo = activeFader:getValue("value")
                if vo:getMin() ~= def.min or vo:getMax() ~= def.max or vo:getDefault() ~= neutral then
                    vo:getMessage():setRange(0, def.max - def.min)
                    vo:setRange(def.min, def.max, neutral, false)
                end
                if vo:getValue() ~= initVal then
                    suppress[activeFid] = true
                    vo:updateValue(initVal)
                    suppress[activeFid] = nil
                end
                if activeFader:getName() ~= def.name then activeFader:setName(def.name) end
                local col = def.color or WHITE
                if activeFader:getColor() ~= col then activeFader:setColor(col) end
                if not activeFader:isVisible() then activeFader:setVisible(true) end
            end
        end
    end
end

function applyOscModel(oscIdx, modelIdx)
    local isOsc2 = (oscIdx == 2)
    local models = isOsc2 and OSC2_MODELS or OSC1_MODELS
    local defs = models[modelIdx]
    if not defs then
        return
    end
    if isOsc2 then
        selectedOsc2Model = modelIdx
    else
        selectedOsc1Model = modelIdx
    end
    suppressModelCallback = true
    for _, cid in ipairs(isOsc2 and { 8, 601 } or { 2, 301 }) do
        local c = controls.get(cid)
        if c then c:getValue("value"):updateValue(modelIdx) end
    end
    suppressModelCallback = false

    local pageId     = isOsc2 and OSC2_PAGE_ID or OSC1_PAGE_ID
    local grpId      = isOsc2 and 70 or 60
    local prefix     = isOsc2 and "OSC2" or "OSC1"
    local faderBase  = isOsc2 and 700 or 400
    local listBase   = isOsc2 and 800 or 500
    local slotDefMap = isOsc2 and activeOsc2SlotDef or activeOsc1SlotDef
    for k in pairs(slotDefMap) do
        slotDefMap[k] = nil
    end
    if window and window.stop then
        window.stop()
    end
    local header = prefix .. " - " .. getOscModelName(oscIdx)
    if pages and pages.get then
        local pg = pages.get(pageId)
        if pg and pg.setName and (not pg.getName or pg:getName() ~= header) then
            pg:setName(header)
        end
    end
    local grp = preset.getGroup(grpId)
    if grp and (not grp.getLabel or grp:getLabel() ~= header) then
        grp:setLabel(header)
    end

    applyDynamicSlots(defs, 3, 36, 2, faderBase, listBase, slotDefMap, oscSaved, oscIdx, suppressSlot)
    if window and window.resume then
        window.resume()
    end
    repaintModelWidgets()
    if oscPresetView and showOscPresetManager then
        showOscPresetManager()
    end
end

function setOscModelsFromDump(osc1Type, osc2Type)
    if type(osc1Type) == "number" and osc1Type >= 0 and osc1Type <= 12 then
        applyOscModel(1, osc1Type)
    end
    if type(osc2Type) == "number" and osc2Type >= 0 and osc2Type <= 8 then
        applyOscModel(2, osc2Type)
    end
end

-- ============================================================================
-- 4. Formatters & Control Callbacks
-- ============================================================================

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

local function formatSlotValue(def, value)
    local v = math.floor(value)
    local fmt = def and def.fmt
    if not fmt then return tostring(v)
    elseif fmt == "dbhalf" then return string.format("%+.1f dB", v * 0.5)
    elseif fmt == "db" then return string.format("%+d dB", v)
    elseif fmt == "plus1" then return tostring(v + 1)
    elseif fmt == "hz10" then return string.format("%+.1f Hz", v / 10.0)
    elseif fmt == "slope" then return string.format("%+.2f", v / 50.0)
    elseif fmt == "coarse" then return (v == 0) and "0.5" or tostring(v)
    elseif fmt == "offneg" then return (v < 0) and "OFF" or tostring(v)
    elseif fmt == "note" and fmtNote then return fmtNote(nil, v)
    end
    return tostring(v)
end

function fmtOscSlot(valueObject, value)
    local ctrlId = valueObject:getControl():getId()
    local slotDefMap = (ctrlId >= 600) and activeOsc2SlotDef or activeOsc1SlotDef
    return formatSlotValue(slotDefMap[ctrlId % 50], value)
end

function onJumpPage(valueObject, value)
    if suppressJumpPad or math.floor(value) <= 0 then
        return
    end
    suppressJumpPad = true
    if valueObject and valueObject.updateValue then
        valueObject:updateValue(0)
    end
    suppressJumpPad = false
    local ctrlId = valueObject:getControl():getId()
    local targetPageId, label
    if ctrlId == 1 then
        targetPageId = OSC1_PAGE_ID
        label = "Jump -> OSC 1 (" .. getOscModelName(1) .. ")"
    elseif ctrlId == 7 then
        targetPageId = OSC2_PAGE_ID
        label = "Jump -> OSC 2 (" .. getOscModelName(2) .. ")"
    else
        targetPageId = OSC_COMMON_PAGE_ID
        label = "Jump -> OSC Common"
    end
    lastJumpedPage = targetPageId
    if pages and pages.display then
        pages.display(targetPageId)
    end
    info.setText(label)
end

function onOscType(valueObject, value)
    if suppressModelCallback then
        return
    end
    local ctrlId = valueObject:getControl():getId()
    local isOsc2 = (ctrlId == 8 or ctrlId == 601)
    local oscIdx = isOsc2 and 2 or 1
    local maxType = isOsc2 and 8 or 12
    local v = math.floor(value)
    if ctrlId == 301 or ctrlId == 601 then
        local ov = overlays.get(isOsc2 and OV.OSC2_TYPE or OV.OSC1_TYPE)
        v = (ov and ov:getValueByIndex(v)) or v
        if v < 0 or v > maxType then
            return
        end
    else
        v = math.max(0, math.min(maxType, v))
    end
    sendParamChange(0, isOsc2 and 188 or 174, v)
    applyOscModel(oscIdx, v)
    info.setText("OSC" .. oscIdx .. ": " .. getOscModelName(oscIdx))
end

function onOscSlot(valueObject, value)
    local ctrl = valueObject:getControl()
    local ctrlId = ctrl:getId()
    if suppressSlot[ctrlId] then
        suppressSlot[ctrlId] = nil
        return
    end
    if not ctrl:isVisible() then
        return
    end
    local isOsc2 = (ctrlId >= 600)
    local exId = isOsc2 and 2 or 1
    local slotDefMap = isOsc2 and activeOsc2SlotDef or activeOsc1SlotDef
    local def = slotDefMap[ctrlId % 50]
    if not def then
        return
    end
    local rawVal = math.floor(value)
    oscSaved[(exId << 11) | def.id] = rawVal

    local z1Val = rawVal
    if def.kind == "list" then
        local ov = overlays.get(def.ov)
        z1Val = (ov and ov:getValueByIndex(rawVal)) or rawVal
    end
    sendParamChange(exId, def.id, z1Val)
end

local COMMON_CTRLS = {
    [1] = { 3, 4, 5, 6, 13, 14, 15, 16, 17, 25, 26, 27, 28 },
    [2] = { 9, 10, 11, 12, 19, 20, 21, 22, 23, 31, 32, 33, 34 },
}
local COMMON_DEF_VAL = {
    [3] = 2, [4] = 0, [5] = 0, [6] = 0, [13] = 60, [14] = 0, [15] = 0, [16] = 0, [17] = 0, [25] = 0, [26] = 0, [27] = 0, [28] = 0,
    [9] = 2, [10] = 0, [11] = 0, [12] = 0, [19] = 60, [20] = 0, [21] = 0, [22] = 0, [23] = 0, [31] = 0, [32] = 0, [33] = 0, [34] = 0,
}
commonSaved = {}
for cid, dv in pairs(COMMON_DEF_VAL) do commonSaved[cid] = dv end

function onParam(valueObject, value)
    if suppressOscPreset then return end
    local ctrlId = valueObject:getControl():getId()
    local paramId = CTRL_PARAM[ctrlId]
    if not paramId then
        return
    end
    local z1Val = math.floor(value)
    local ovId = CTRL_OV[ctrlId]
    if ovId then
        local ov = overlays.get(ovId)
        z1Val = (ov and ov:getValueByIndex(z1Val)) or z1Val
    end
    commonSaved[ctrlId] = z1Val
    sendParamChange(0, paramId, z1Val)
end

-- ============================================================================
-- 4b. Named OSC Preset Library (OSC 1 per-type, OSC 2 per-type, & Both OSCs)
-- ============================================================================

OSC_UNIT_PRESET_SLOTS = 8
OSC_DUAL_PRESET_SLOTS = 25
OSC_COMMON_CS3_CTRLS  = { 25, 26, 27, 28, 31, 32, 33, 34 }
OSC_PRESET_CTRLS      = { 35, 36, 37, 38, 39, 40, 41, 42, 43 }

z1PersistLib = _G.z1PersistLib or { version = 2, unit = {}, chain = {}, tuning = {}, oscUnit = {}, oscDual = {} }
_G.z1PersistLib = z1PersistLib
z1PersistLib.oscUnit = z1PersistLib.oscUnit or {}
z1PersistLib.oscDual = z1PersistLib.oscDual or {}

oscPresetView    = false
oscPresetTarget  = 0 -- 0 = OSC 1 (selected OSC1 type), 1 = OSC 2 (selected OSC2 type), 2 = Both OSCs
oscPresetSlot    = 1
oscPresetNamePos = 1
oscPresetName    = {}
suppressOscPreset = false
local shownOscPresetBank = nil
local pendingOscDelete   = nil

function getProgramNameString(charsTable, trim)
    local src = charsTable or programNameChars
    local chars = {}
    for i = 1, 16 do
        local c = src[i] or 0x20
        if c < 0x20 or c > 0x7F then
            c = 0x20
        end
        chars[i] = string.char(c)
    end
    local s = table.concat(chars)
    return trim and (s:gsub("%s+$", "")) or s
end

function setNameCharsBuffer(dst, src, maxAscii)
    local hi = maxAscii or 0x7F
    local isStr = (type(src) == "string")
    local isTbl = (type(src) == "table")
    for i = 1, 16 do
        local b = isStr and string.byte(src, i) or (isTbl and src[i]) or 0x20
        if type(b) ~= "number" or b < 0x20 or b > hi then
            b = 0x20
        end
        dst[i] = b
    end
end

function fmtAsciiChar(_valueObject, value)
    local v = math.floor(value)
    if v < 0x20 or v > 0x7F then
        v = 0x20
    end
    if v == 0x20 then
        return "SPC (32)"
    elseif v == 0x7F then
        return "DEL (127)"
    end
    return string.format("'%s' (%d)", string.char(v), v)
end

local function oscPresetBankKey()
    if oscPresetTarget == 2 then return "dual" end
    local modelIdx = (oscPresetTarget == 1) and selectedOsc2Model or selectedOsc1Model
    return "osc" .. tostring(modelIdx or 0)
end

local function oscPresetSlotCount()
    return (oscPresetTarget == 2) and OSC_DUAL_PRESET_SLOTS or OSC_UNIT_PRESET_SLOTS
end

local function getOscPresetEntry(slot)
    local key = "s" .. tostring(slot)
    if oscPresetTarget == 2 then
        return z1PersistLib.oscDual[key]
    end
    local bank = z1PersistLib.oscUnit[oscPresetBankKey()]
    return (type(bank) == "table") and bank[key] or nil
end

local function setOscPresetEntry(slot, entry)
    local key = "s" .. tostring(slot)
    if oscPresetTarget == 2 then
        z1PersistLib.oscDual[key] = entry
    else
        local bk = oscPresetBankKey()
        if type(z1PersistLib.oscUnit[bk]) ~= "table" then z1PersistLib.oscUnit[bk] = {} end
        z1PersistLib.oscUnit[bk][key] = entry
    end
end

local function defaultOscPresetName(slot)
    if oscPresetTarget == 2 then
        return string.format("Dual OSC %02d", slot)
    end
    local mName = getOscModelName(oscPresetTarget + 1)
    return string.format("%s %d", string.sub(mName, 1, 13), slot)
end

local function oscPresetHeader()
    if oscPresetTarget == 2 then
        return string.format("BOTH OSC1+OSC2 PRESETS (%d)", OSC_DUAL_PRESET_SLOTS)
    end
    local oscIdx = oscPresetTarget + 1
    return string.format("OSC%d %s PRESETS (%d)",
        oscIdx, string.upper(getOscModelName(oscIdx)), OSC_UNIT_PRESET_SLOTS)
end

local function z1ValToIdx(ovId, z1Val)
    if not ovId then return z1Val end
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

local function defaultOscDefRaw(def)
    if def.kind == "list" then return 0 end
    return (def.min < 0 and def.max > 0) and 0 or def.min
end

local function captureOscCommon(oscIdx)
    local out = {}
    for i, cid in ipairs(COMMON_CTRLS[oscIdx]) do
        out[i] = commonSaved[cid] or COMMON_DEF_VAL[cid] or 0
    end
    return out
end

local function applyOscCommon(oscIdx, vals)
    if type(vals) ~= "table" then return end
    for i, cid in ipairs(COMMON_CTRLS[oscIdx]) do
        local z1Val = vals[i]
        if type(z1Val) == "number" then
            commonSaved[cid] = z1Val
            local pid = CTRL_PARAM[cid]
            if pid then sendParamChange(0, pid, z1Val) end
            local c = controls.get(cid)
            if c then
                local ovId = CTRL_OV[cid]
                local disp = ovId and z1ValToIdx(ovId, z1Val) or z1Val
                suppressOscPreset = true
                c:getValue("value"):updateValue(disp)
                suppressOscPreset = false
            end
        end
    end
end

local function captureOscUnitValues(oscIdx, modelIdx)
    local models = (oscIdx == 2) and OSC2_MODELS or OSC1_MODELS
    local defs = models[modelIdx] or {}
    local v = {}
    for i, d in ipairs(defs) do
        local raw = oscSaved[(oscIdx << 11) | d.id]
        if raw == nil then raw = defaultOscDefRaw(d) end
        if d.kind == "list" then
            local ov = overlays.get(d.ov)
            v[i] = (ov and ov:getValueByIndex(raw)) or raw
        else
            v[i] = raw
        end
    end
    return v
end

local function applyOscUnitValues(oscIdx, modelIdx, v)
    local models = (oscIdx == 2) and OSC2_MODELS or OSC1_MODELS
    local defs = models[modelIdx] or {}
    for i, d in ipairs(defs) do
        local z1Val = (type(v) == "table") and v[i] or nil
        if type(z1Val) == "number" then
            local raw = (d.kind == "list") and z1ValToIdx(d.ov, z1Val) or z1Val
            oscSaved[(oscIdx << 11) | d.id] = raw
            sendParamChange(oscIdx, d.id, z1Val)
        end
    end
    applyOscModel(oscIdx, modelIdx)
end

local function repaintOscPresetList()
    if not oscPresetView then return end
    local c = preset.getControl(37)
    if c then c:repaint() end
end

local function syncOscNameChar()
    local c = controls.get(41)
    if c then
        suppressOscPreset = true
        c:getValue("value"):updateValue(oscPresetName[oscPresetNamePos] or 0x20)
        suppressOscPreset = false
    end
end

local function selectOscPresetSlot(slot)
    local n = oscPresetSlotCount()
    oscPresetSlot = math.max(1, math.min(n, slot))
    pendingOscDelete = nil
    local e = getOscPresetEntry(oscPresetSlot)
    setNameCharsBuffer(oscPresetName, (e and e.name) or defaultOscPresetName(oscPresetSlot), 0x7E)
    syncOscNameChar()
    repaintOscPresetList()
end

function showOscPresetManager()
    window.stop()
    for _, cid in ipairs(OSC_COMMON_CS3_CTRLS) do
        local c = controls.get(cid)
        if c and c:isVisible() then c:setVisible(false) end
    end
    for _, cid in ipairs(OSC_PRESET_CTRLS) do
        local c = controls.get(cid)
        if c and not c:isVisible() then c:setVisible(true) end
    end
    local grp3 = preset.getGroup(52)
    if grp3 then grp3:setLabel("OSC PRESET LIBRARY - " .. oscPresetHeader()) end

    local n = oscPresetSlotCount()
    local slotCtrl = controls.get(36)
    if slotCtrl then
        local vo = slotCtrl:getValue("value")
        vo:getMessage():setRange(0, n - 1)
        vo:setRange(1, n, 1, false)
    end
    local bank = oscPresetBankKey()
    if bank ~= shownOscPresetBank then
        shownOscPresetBank = bank
        selectOscPresetSlot(oscPresetSlot)
    end
    suppressOscPreset = true
    if slotCtrl then slotCtrl:getValue("value"):updateValue(oscPresetSlot) end
    local tgt = controls.get(35)
    if tgt then tgt:getValue("value"):updateValue(oscPresetTarget) end
    local posCtrl = controls.get(40)
    if posCtrl then posCtrl:getValue("value"):updateValue(oscPresetNamePos) end
    suppressOscPreset = false
    syncOscNameChar()
    repaintOscPresetList()
    window.resume()
end

function setOscPresetView(on)
    oscPresetView = on and true or false
    pendingOscDelete = nil
    local pad = controls.get(24)
    if pad then
        suppressOscPreset = true
        pad:getValue("value"):updateValue(oscPresetView and 1 or 0)
        suppressOscPreset = false
    end
    if oscPresetView then
        showOscPresetManager()
        return
    end
    window.stop()
    for _, cid in ipairs(OSC_PRESET_CTRLS) do
        local c = controls.get(cid)
        if c and c:isVisible() then c:setVisible(false) end
    end
    for _, cid in ipairs(OSC_COMMON_CS3_CTRLS) do
        local c = controls.get(cid)
        if c and not c:isVisible() then c:setVisible(true) end
    end
    local grp3 = preset.getGroup(52)
    if grp3 then grp3:setLabel("OSC 1 & OSC 2 - PITCH MODULATION 1 & DYNAMIC CONTROLLER") end
    window.resume()
end

function paintOscPresetList(control)
    local b = control:getBounds()
    local w, h = b[WIDTH], b[HEIGHT]
    graphics.setColor(0x18202C)
    graphics.fillRect(0, 0, w, h)
    graphics.setColor(0x03A598)
    graphics.drawRect(0, 0, w, h)

    graphics.setColor(ORANGE)
    graphics.print(6, 3, oscPresetHeader(), w - 12, LEFT)

    local chars = {}
    for i = 1, 16 do
        local ch = string.char(oscPresetName[i] or 0x20)
        chars[i] = (i == oscPresetNamePos) and ("[" .. ch .. "]") or ch
    end
    graphics.setColor(WHITE)
    graphics.print(6, 21, "Name: " .. table.concat(chars), w - 12, LEFT)

    local n = oscPresetSlotCount()
    local rows = 6
    local first = math.max(1, math.min(oscPresetSlot - 2, n - rows + 1))
    for r = 0, rows - 1 do
        local s = first + r
        if s > n then break end
        local y = 40 + r * 17
        local e = getOscPresetEntry(s)
        if s == oscPresetSlot then
            graphics.setColor(0x03A598)
            graphics.fillRect(2, y - 1, w - 4, 17)
            graphics.setColor(0x000000)
        else
            graphics.setColor(e and WHITE or 0x7A8290)
        end
        graphics.print(8, y, string.format("%02d  %s", s, (e and e.name) or "- empty -"), w - 16, LEFT)
    end
end

function onOscPresetView(_valueObject, value)
    if suppressOscPreset then return end
    local on = math.floor(value) > 0
    if on ~= oscPresetView then
        setOscPresetView(on)
    end
end

function onOscPresetTarget(_valueObject, value)
    if suppressOscPreset then return end
    local t = math.max(0, math.min(2, math.floor(value)))
    if t == oscPresetTarget then return end
    oscPresetTarget = t
    shownOscPresetBank = nil
    if oscPresetView then showOscPresetManager() end
    info.setText(oscPresetHeader())
end

function onOscPresetSlot(_valueObject, value)
    if suppressOscPreset then return end
    selectOscPresetSlot(math.floor(value))
end

function fmtOscPresetSlot(_valueObject, value)
    local s = math.floor(value)
    local e = getOscPresetEntry(s)
    return string.format("%02d %s", s, (e and e.name) or "<empty>")
end

function onOscNamePos(_valueObject, value)
    oscPresetNamePos = math.max(1, math.min(16, math.floor(value)))
    syncOscNameChar()
    repaintOscPresetList()
end

function onOscNameChar(_valueObject, value)
    if suppressOscPreset then return end
    local c = math.max(0x20, math.min(0x7E, math.floor(value)))
    oscPresetName[oscPresetNamePos] = c
    repaintOscPresetList()
end

function onOscPresetSave(_valueObject, value)
    if math.floor(value) <= 0 then return end
    pendingOscDelete = nil
    local name = getProgramNameString(oscPresetName, true)
    if name == "" then name = defaultOscPresetName(oscPresetSlot) end
    local entry
    if oscPresetTarget == 2 then
        entry = {
            name  = name,
            types = { selectedOsc1Model, selectedOsc2Model },
            c1    = captureOscCommon(1),
            c2    = captureOscCommon(2),
            v1    = captureOscUnitValues(1, selectedOsc1Model),
            v2    = captureOscUnitValues(2, selectedOsc2Model),
        }
    else
        local oscIdx = oscPresetTarget + 1
        local mIdx = (oscIdx == 2) and selectedOsc2Model or selectedOsc1Model
        entry = {
            name  = name,
            model = mIdx,
            c     = captureOscCommon(oscIdx),
            v     = captureOscUnitValues(oscIdx, mIdx),
        }
    end
    setOscPresetEntry(oscPresetSlot, entry)
    local ok = (type(persist) == "function") and pcall(persist, z1PersistLib) or false
    repaintOscPresetList()
    info.setText(string.format("Saved %02d: %s%s", oscPresetSlot, name, ok and "" or " (RAM)"))
end

function onOscPresetLoad(_valueObject, value)
    if math.floor(value) <= 0 then return end
    pendingOscDelete = nil
    local e = getOscPresetEntry(oscPresetSlot)
    if not e then
        info.setText(string.format("Slot %02d is empty", oscPresetSlot))
        return
    end
    if oscPresetTarget == 2 then
        local t1 = (type(e.types) == "table" and type(e.types[1]) == "number") and e.types[1] or e.model
        if type(t1) == "number" then
            selectedOsc1Model = t1
            sendParamChange(0, 174, t1)
            applyOscCommon(1, e.c1 or e.c)
            applyOscUnitValues(1, t1, e.v1 or e.v)
        end
        local t2 = (type(e.types) == "table") and e.types[2] or nil
        if type(t2) == "number" and type(e.v2) == "table" then
            selectedOsc2Model = t2
            sendParamChange(0, 188, t2)
            applyOscCommon(2, e.c2)
            applyOscUnitValues(2, t2, e.v2)
        end
    else
        local oscIdx = oscPresetTarget + 1
        local mIdx = (oscIdx == 2) and selectedOsc2Model or selectedOsc1Model
        applyOscCommon(oscIdx, e.c)
        applyOscUnitValues(oscIdx, mIdx, e.v)
    end
    shownOscPresetBank = nil
    if oscPresetView then showOscPresetManager() end
    info.setText("Loaded: " .. tostring(e.name))
end

function onOscPresetRename(_valueObject, value)
    if math.floor(value) <= 0 then return end
    pendingOscDelete = nil
    local e = getOscPresetEntry(oscPresetSlot)
    if not e then
        info.setText("Slot empty - use Save")
        return
    end
    local name = getProgramNameString(oscPresetName, true)
    if name == "" then name = defaultOscPresetName(oscPresetSlot) end
    e.name = name
    if type(persist) == "function" then pcall(persist, z1PersistLib) end
    repaintOscPresetList()
    info.setText("Renamed: " .. name)
end

function onOscPresetDelete(_valueObject, value)
    if math.floor(value) <= 0 then return end
    if not getOscPresetEntry(oscPresetSlot) then
        info.setText(string.format("Slot %02d is empty", oscPresetSlot))
        return
    end
    if pendingOscDelete ~= oscPresetSlot then
        pendingOscDelete = oscPresetSlot
        info.setText(string.format("Press DELETE again to clear %02d", oscPresetSlot))
        return
    end
    pendingOscDelete = nil
    setOscPresetEntry(oscPresetSlot, nil)
    if type(persist) == "function" then pcall(persist, z1PersistLib) end
    setNameCharsBuffer(oscPresetName, defaultOscPresetName(oscPresetSlot), 0x7E)
    syncOscNameChar()
    repaintOscPresetList()
    info.setText(string.format("Cleared slot %02d", oscPresetSlot))
end

-- ============================================================================
-- 5. Lifecycle Hooks
-- ============================================================================

function preset.onLoad()
    suppressModelCallback = true
    for ovId, items in pairs(ENUM_DEFS) do
        overlays.create(ovId, items)
    end
    if type(recall) == "function" and (type(recallJson) ~= "function" or recallJson() ~= nil) then
        local stored = {}
        if pcall(recall, stored) and stored.version == 2 then
            if type(stored.unit) == "table" then z1PersistLib.unit = stored.unit end
            if type(stored.chain) == "table" then z1PersistLib.chain = stored.chain end
            if type(stored.tuning) == "table" then z1PersistLib.tuning = stored.tuning end
            if type(stored.oscUnit) == "table" then z1PersistLib.oscUnit = stored.oscUnit end
            if type(stored.oscDual) == "table" then z1PersistLib.oscDual = stored.oscDual end
        end
    end
    for _, cid in ipairs({ 2, 8 }) do
        local c = preset.getControl(cid)
        if c then c:setPaintCallback(paintOscModel) end
    end
    local listCtrl = preset.getControl(37)
    if listCtrl then
        listCtrl:setPaintCallback(paintOscPresetList)
    end
end

function preset.onReady()
    suppressModelCallback = false
    for cid, ovId in pairs(CTRL_OV) do
        local c = controls.get(cid)
        if c then c:getValue("value"):setOverlayId(ovId) end
    end
    local c35 = controls.get(35)
    if c35 then c35:getValue("value"):setOverlayId(OV.PRESET_TGT) end
    local c301 = controls.get(301)
    if c301 then c301:getValue("value"):setOverlayId(OV.OSC1_TYPE) end
    local c601 = controls.get(601)
    if c601 then c601:getValue("value"):setOverlayId(OV.OSC2_TYPE) end
    setNameCharsBuffer(oscPresetName, defaultOscPresetName(oscPresetSlot), 0x7E)
    applyOscModel(1, 0)
    applyOscModel(2, 0)
    setOscPresetView(false)
    info.setText("Z1 OSC Common Ready")
end

function preset.onZ1Param(exId, paramId, z1Val)
    if exId == 0 then
        if paramId == 174 then
            applyOscModel(1, z1Val)
            return
        elseif paramId == 188 then
            applyOscModel(2, z1Val)
            return
        end
        for cid, pid in pairs(CTRL_PARAM) do
            if pid == paramId then
                commonSaved[cid] = z1Val
                local c = controls.get(cid)
                if c then c:getValue("value"):updateValue(z1Val) end
            end
        end
    elseif exId == 1 or exId == 2 then
        local models = (exId == 1) and OSC1_MODELS or OSC2_MODELS
        local curModel = (exId == 1) and selectedOsc1Model or selectedOsc2Model
        local defs = models[curModel] or {}
        for _, def in ipairs(defs) do
            if def.id == paramId then
                local disp = (def.kind == "list") and z1ValToIdx(def.ov, z1Val) or z1Val
                oscSaved[(exId << 11) | paramId] = disp
                applyOscModel(exId, curModel)
                return
            end
        end
    end
end

function preset.onZ1Dump(params)
    local p0 = params and params[0]
    if not p0 then return end
    for cid, pid in pairs(CTRL_PARAM) do
        if p0[pid] ~= nil then
            commonSaved[cid] = p0[pid]
            local c = controls.get(cid)
            if c then
                local vo = c:getValue("value")
                if vo and vo:getValue() ~= p0[pid] then vo:updateValue(p0[pid]) end
            end
        end
    end
    local osc1Type = p0[174] or selectedOsc1Model
    local osc2Type = p0[188] or selectedOsc2Model
    local p1 = params[1] or {}
    for _, def in ipairs(OSC1_MODELS[osc1Type] or {}) do
        if p1[def.id] ~= nil then
            local disp = (def.kind == "list") and z1ValToIdx(def.ov, p1[def.id]) or p1[def.id]
            oscSaved[(1 << 11) | def.id] = disp
        end
    end
    local p2 = params[2] or {}
    for _, def in ipairs(OSC2_MODELS[osc2Type] or {}) do
        if p2[def.id] ~= nil then
            local disp = (def.kind == "list") and z1ValToIdx(def.ov, p2[def.id]) or p2[def.id]
            oscSaved[(2 << 11) | def.id] = disp
        end
    end
    setOscModelsFromDump(osc1Type, osc2Type)
end
