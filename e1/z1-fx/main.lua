-- Korg Z1 - FX1, FX2, Master FX, 2-Band EQ & FX Preset Manager for Electra One mk2
-- Covers:
--   [Effect Send & Selects] (IDs 356..361, ExID = 0)
--   [2-Band EQ]             (IDs 362..365, ExID = 0)
--   [Effect 1 Parameters]   (IDs 800..1003, ExID = 3, 15 algorithms)
--   [Effect 2 Parameters]   (IDs 800..951,  ExID = 4, 11 algorithms)
--   [Master FX Parameters]  (IDs 1004..1039, ExID = 5, 3 algorithms)
--   [FX Preset Save/Recall] (Per-FX and Full FX-Chain presets via persist/recall & in-memory slots)
--
-- Layout (32 controls across 3 Control Sets):
--   Control Set 1 (Rows 1-2, Slots 1..12):
--     Row 1 (Slots 1..6):  [11] EDIT FX (FX1/FX2/MFX), [1] FX1 Select (359), [2] FX2 Select (360),
--                          [3] MFX Select (361),       [4] FX Send (356),    [5] Send ModSrc (357)
--     Row 2 (Slots 7..12): [6] Send ModInt (358),      [7] EQ LoFreq (362),  [8] EQ LoGain (363),
--                          [9] EQ HiFreq (364),        [10] EQ HiGain (365), [12] FX PRESET (Save/Recall)
--   Control Set 2 & 3 (Rows 3-6, Dynamic Slots 1..20 -> Faders 101..120 / Lists 201..220):
--     Up to 20 parameters for the active FX1 (ExID 3), FX2 (ExID 4), or Master FX (ExID 5) algorithm.

local DEVICE_ID = 1

local function getGlobalChannel()
    local dev = preset.getDevice(DEVICE_ID)
    if dev then
        return (dev:getChannel() - 1) & 0x0F
    end
    return 0
end

-- ============================================================================
-- 1. Overlays & Enumerations (MODSRC1 & Non-Contiguous MODSRC2)
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

-- Modulation Source List 2 (36 entries: 0 and 11..45 non-contiguous, used by all FX parameters)
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

FX1_TYPES = {
    { value = 0,  label = "Overdrive" },
    { value = 1,  label = "Compressor" },
    { value = 2,  label = "4 Band PEQ" },
    { value = 3,  label = "Wah" },
    { value = 4,  label = "Exciter" },
    { value = 5,  label = "Decimator" },
    { value = 6,  label = "Chorus" },
    { value = 7,  label = "Flanger" },
    { value = 8,  label = "Phaser" },
    { value = 9,  label = "Small Rotary" },
    { value = 10, label = "Delay (Mono)" },
    { value = 11, label = "Talking Mod" },
    { value = 12, label = "Multitap Dly" },
    { value = 13, label = "Ensemble" },
    { value = 14, label = "Rotary Spkr" },
}

FX2_TYPES = {
    { value = 0,  label = "Overdrive" },
    { value = 1,  label = "Compressor" },
    { value = 2,  label = "4 Band PEQ" },
    { value = 3,  label = "Wah" },
    { value = 4,  label = "Exciter" },
    { value = 5,  label = "Decimator" },
    { value = 6,  label = "Chorus" },
    { value = 7,  label = "Flanger" },
    { value = 8,  label = "Phaser" },
    { value = 9,  label = "Small Rotary" },
    { value = 10, label = "Delay (Mono)" },
}

MFX_TYPES = {
    { value = 0, label = "Stereo Delay" },
    { value = 1, label = "Reverb-Hall" },
    { value = 2, label = "Reverb-Room" },
}

local OV = {
    FX1_TYPE    = 1,
    FX2_TYPE    = 2,
    MFX_TYPE    = 3,
    MODSRC1     = 4,
    MODSRC2     = 5,
    EDIT_UNIT   = 6,
    PRESET_ACT  = 7,
    OD_MODE     = 10,
    EQ_TYPE     = 11,
    SWEEP_MODE  = 12,
    WAH_FLT     = 13,
    OFF_ON      = 14,
    TRI_SIN     = 15,
    SYNC_BASE   = 16,
    OUT_PHASE   = 17,
    SLOW_FAST   = 18,
    TALK_MODE   = 19,
    VOWEL       = 20,
    MTAP_TYPE   = 21,
    ROT_MODE    = 22,
    STDLY_TYPE  = 23,
}

local ENUM_DEFS = {
    [OV.FX1_TYPE]  = FX1_TYPES,
    [OV.FX2_TYPE]  = FX2_TYPES,
    [OV.MFX_TYPE]  = MFX_TYPES,
    [OV.MODSRC1]   = MODSRC1,
    [OV.MODSRC2]   = MODSRC2,
    [OV.EDIT_UNIT] = {
        { value = 0, label = "Edit FX 1" },
        { value = 1, label = "Edit FX 2" },
        { value = 2, label = "Edit MasterFX" },
    },
    [OV.PRESET_ACT] = {
        { value = 0, label = "Live Edit" },
        { value = 1, label = "Load Unit P1" },
        { value = 2, label = "Load Unit P2" },
        { value = 3, label = "Save Unit P1" },
        { value = 4, label = "Save Unit P2" },
        { value = 5, label = "Load Chain 1" },
        { value = 6, label = "Save Chain 1" },
    },
    [OV.OD_MODE]    = { { value = 0, label = "OVERDRIVE" }, { value = 1, label = "DISTORTION" } },
    [OV.EQ_TYPE]    = { { value = 0, label = "PEAKING" },   { value = 1, label = "SHELVING" } },
    [OV.SWEEP_MODE] = { { value = 0, label = "AUTO" },      { value = 1, label = "MOD SOURCE" } },
    [OV.WAH_FLT]    = { { value = 0, label = "BPF" },       { value = 1, label = "LPF" } },
    [OV.OFF_ON]     = { { value = 0, label = "OFF" },       { value = 1, label = "ON" } },
    [OV.TRI_SIN]    = { { value = 0, label = "TRIANGLE" },  { value = 1, label = "SINE" } },
    [OV.SYNC_BASE]  = {
        { value = 0, label = "32nd" }, { value = 1, label = "16th Tri" },
        { value = 2, label = "16th" }, { value = 3, label = "8th Tri" },
        { value = 4, label = "8th" },  { value = 5, label = "4th Tri" },
        { value = 6, label = "4th" },  { value = 7, label = "2nd" },
    },
    [OV.OUT_PHASE]  = { { value = 0, label = "NORMAL (+)" }, { value = 1, label = "INVERT (-)" }, { value = 2, label = "STEREO (+-)" } },
    [OV.SLOW_FAST]  = { { value = 0, label = "SLOW" },       { value = 1, label = "FAST" } },
    [OV.TALK_MODE]  = { { value = 0, label = "MANUAL" },     { value = 1, label = "MOD SOURCE" } },
    [OV.VOWEL]      = {
        { value = 0, label = "A" }, { value = 1, label = "I" }, { value = 2, label = "U" },
        { value = 3, label = "E" }, { value = 4, label = "O" },
    },
    [OV.MTAP_TYPE]  = {
        { value = 0, label = "Normal" }, { value = 1, label = "Cross 1" }, { value = 2, label = "Cross 2" },
        { value = 3, label = "Pan 1" },  { value = 4, label = "Pan 2" },
    },
    [OV.ROT_MODE]   = { { value = 0, label = "ROTATE" }, { value = 1, label = "STOP" } },
    [OV.STDLY_TYPE] = { { value = 0, label = "STEREO" }, { value = 1, label = "CROSS" } },
}

local function num(id, name, min, max, fmt, color)
    return { id = id, name = name, kind = "num", min = min, max = max, fmt = fmt, color = color or WHITE }
end

local function lst(id, name, ov, color)
    return { id = id, name = name, kind = "list", ov = ov, color = color or PURPLE }
end

local function mod2(id, name)
    return lst(id, name, OV.MODSRC2, BLUE)
end

local function mint(id, name, min, max, fmt)
    return num(id, name, min or -99, max or 99, fmt, GREEN)
end

-- ============================================================================
-- 2. All 15 FX1/FX2 Algorithms (IDs 800..1003) & 3 Master FX Algorithms (IDs 1004..1039)
-- ============================================================================

FX12_MODELS = {
    -- 0: Over Drive (19 params, IDs 800..818)
    [0] = {
        lst(800,  "OD Mode",       OV.OD_MODE, ORANGE),
        num(801,  "Drive",         0, 99, nil, RED),
        num(802,  "Out Level",     0, 99),
        num(803,  "Pre LowCut",    0, 99, nil, ORANGE),
        num(804,  "LoEQ Freq",     0, 49, nil, ORANGE),
        num(805,  "LoEQ Q",        0, 95, nil, ORANGE),
        num(806,  "LoEQ Gain",     -36, 36, "dbhalf", ORANGE),
        num(807,  "MidLo Freq",    0, 49, nil, ORANGE),
        num(808,  "MidLo Q",       0, 95, nil, ORANGE),
        num(809,  "MidLo Gain",    -36, 36, "dbhalf", ORANGE),
        num(810,  "MidHi Freq",    0, 49, nil, ORANGE),
        num(811,  "MidHi Q",       0, 95, nil, ORANGE),
        num(812,  "MidHi Gain",    -36, 36, "dbhalf", ORANGE),
        num(813,  "HiEQ Freq",     0, 49, nil, ORANGE),
        num(814,  "HiEQ Q",        0, 95, nil, ORANGE),
        num(815,  "HiEQ Gain",     -36, 36, "dbhalf", ORANGE),
        num(816,  "FX Balance",    0, 100, nil, RED),
        mod2(817, "Bal ModSrc"),
        mint(818, "Bal ModInt"),
    },
    -- 1: Compressor (9 params, IDs 819..827)
    [1] = {
        num(819,  "Sensitivity",   1, 99, nil, RED),
        num(820,  "Attack",        1, 99, nil, ORANGE),
        num(821,  "EQ Trim",       0, 99),
        num(822,  "PreLo Gain",    -36, 36, "dbhalf", ORANGE),
        num(823,  "PreHi Gain",    -36, 36, "dbhalf", ORANGE),
        num(824,  "Out Level",     0, 99),
        num(825,  "FX Balance",    0, 100, nil, RED),
        mod2(826, "Bal ModSrc"),
        mint(827, "Bal ModInt"),
    },
    -- 2: 4 Band PEQ (20 params, IDs 828..847)
    [2] = {
        num(828,  "Input Trim",    0, 99),
        lst(829,  "LoEQ Type",     OV.EQ_TYPE, PURPLE),
        num(830,  "LoEQ Freq",     0, 49, nil, ORANGE),
        num(831,  "LoEQ Q",        0, 95, nil, ORANGE),
        num(832,  "LoEQ Gain",     -36, 36, "dbhalf", ORANGE),
        num(833,  "MidLo Freq",    0, 49, nil, ORANGE),
        num(834,  "MidLo Q",       0, 95, nil, ORANGE),
        num(835,  "MidLo Gain",    -36, 36, "dbhalf", ORANGE),
        mod2(836, "MidLo Src"),
        mint(837, "MidLo Int",     -36, 36, "dbhalf"),
        num(838,  "MidHi Freq",    0, 49, nil, ORANGE),
        num(839,  "MidHi Q",       0, 95, nil, ORANGE),
        num(840,  "MidHi Gain",    -36, 36, "dbhalf", ORANGE),
        lst(841,  "HiEQ Type",     OV.EQ_TYPE, PURPLE),
        num(842,  "HiEQ Freq",     0, 49, nil, ORANGE),
        num(843,  "HiEQ Q",        0, 95, nil, ORANGE),
        num(844,  "HiEQ Gain",     -36, 36, "dbhalf", ORANGE),
        num(845,  "FX Balance",    0, 100, nil, RED),
        mod2(846, "Bal ModSrc"),
        mint(847, "Bal ModInt"),
    },
    -- 3: Wah (12 params, IDs 848..859)
    [3] = {
        num(848,  "Freq Bottom",   0, 99, nil, ORANGE),
        num(849,  "Freq Top",      0, 99, nil, ORANGE),
        lst(850,  "Sweep Mode",    OV.SWEEP_MODE, PURPLE),
        mod2(851, "Sweep Src"),
        num(852,  "Sweep Resp",    0, 99),
        num(853,  "Env Sens",      0, 99, nil, RED),
        num(854,  "Env Shape",     -99, 99, nil, ORANGE),
        num(855,  "Resonance",     0, 99, nil, RED),
        lst(856,  "Filter Mode",   OV.WAH_FLT, PURPLE),
        num(857,  "FX Balance",    0, 100, nil, RED),
        mod2(858, "Bal ModSrc"),
        mint(859, "Bal ModInt"),
    },
    -- 4: Exciter (12 params, IDs 860..871)
    [4] = {
        num(860,  "Blend",         -99, 99, nil, RED),
        mod2(861, "Blend Src"),
        mint(862, "Blend Int"),
        num(863,  "Emph Point",    0, 99, nil, ORANGE),
        mod2(864, "Emph Src"),
        mint(865, "Emph Int"),
        num(866,  "PreEQ Trim",    0, 99),
        num(867,  "PreLo Gain",    -36, 36, "dbhalf", ORANGE),
        num(868,  "PreHi Gain",    -36, 36, "dbhalf", ORANGE),
        num(869,  "FX Balance",    0, 100, nil, RED),
        mod2(870, "Bal ModSrc"),
        mint(871, "Bal ModInt"),
    },
    -- 5: Decimator (10 params, IDs 872..881)
    [5] = {
        lst(872,  "Pre LPF",       OV.OFF_ON, PURPLE),
        num(873,  "Sample Freq",   5, 120, nil, ORANGE),
        mod2(874, "SmpFrq Src"),
        mint(875, "SmpFrq Int",    -120, 120),
        num(876,  "Resolution",    4, 24, nil, RED),
        num(877,  "High Damp",     0, 99, nil, ORANGE),
        num(878,  "Out Level",     0, 99),
        num(879,  "FX Balance",    0, 100, nil, RED),
        mod2(880, "Bal ModSrc"),
        mint(881, "Bal ModInt"),
    },
    -- 6: Chorus (18 params, IDs 882..899)
    [6] = {
        num(882,  "Delay Time",    0, 140, nil, ORANGE),
        lst(883,  "LFO Wave",      OV.TRI_SIN, PURPLE),
        num(884,  "LFO Freq",      1, 115, nil, ORANGE),
        mod2(885, "LFOFrq Src"),
        mint(886, "LFOFrq Int",    -115, 115),
        lst(887,  "MIDI Sync",     OV.OFF_ON, PURPLE),
        lst(888,  "Sync Base",     OV.SYNC_BASE, PURPLE),
        num(889,  "Sync Time",     0, 15, "plus1", PURPLE),
        num(890,  "Depth",         0, 99, nil, RED),
        mod2(891, "Depth Src"),
        mint(892, "Depth Int"),
        num(893,  "PreEQ Trim",    0, 99),
        num(894,  "PreLo Gain",    -36, 36, "dbhalf", ORANGE),
        num(895,  "PreHi Gain",    -36, 36, "dbhalf", ORANGE),
        lst(896,  "Out Phase",     OV.OUT_PHASE, PURPLE),
        num(897,  "FX Balance",    0, 100, nil, RED),
        mod2(898, "Bal ModSrc"),
        mint(899, "Bal ModInt"),
    },
    -- 7: Flanger (16 params, IDs 900..915)
    [7] = {
        num(900,  "Delay Time",    0, 140, nil, ORANGE),
        lst(901,  "LFO Wave",      OV.TRI_SIN, PURPLE),
        num(902,  "LFO Shape",     -99, 99, nil, ORANGE),
        num(903,  "LFO Freq",      1, 115, nil, ORANGE),
        mod2(904, "LFOFrq Src"),
        mint(905, "LFOFrq Int",    -115, 115),
        lst(906,  "MIDI Sync",     OV.OFF_ON, PURPLE),
        lst(907,  "Sync Base",     OV.SYNC_BASE, PURPLE),
        num(908,  "Sync Time",     0, 15, "plus1", PURPLE),
        num(909,  "Depth",         0, 99, nil, RED),
        num(910,  "Feedback",      -99, 99, nil, RED),
        num(911,  "High Damp",     0, 99, nil, ORANGE),
        lst(912,  "Out Phase",     OV.OUT_PHASE, PURPLE),
        num(913,  "FX Balance",    0, 100, nil, RED),
        mod2(914, "Bal ModSrc"),
        mint(915, "Bal ModInt"),
    },
    -- 8: Phaser (16 params, IDs 916..931)
    [8] = {
        lst(916,  "LFO Wave",      OV.TRI_SIN, PURPLE),
        num(917,  "LFO Shape",     -99, 99, nil, ORANGE),
        num(918,  "LFO Freq",      1, 115, nil, ORANGE),
        mod2(919, "LFOFrq Src"),
        mint(920, "LFOFrq Int",    -115, 115),
        lst(921,  "MIDI Sync",     OV.OFF_ON, PURPLE),
        lst(922,  "Sync Base",     OV.SYNC_BASE, PURPLE),
        num(923,  "Sync Time",     0, 15, "plus1", PURPLE),
        num(924,  "Manual",        0, 99, nil, ORANGE),
        num(925,  "Depth",         0, 99, nil, RED),
        num(926,  "Resonance",     -99, 99, nil, RED),
        num(927,  "High Damp",     0, 99, nil, ORANGE),
        lst(928,  "Out Phase",     OV.OUT_PHASE, PURPLE),
        num(929,  "FX Balance",    0, 100, nil, RED),
        mod2(930, "Bal ModSrc"),
        mint(931, "Bal ModInt"),
    },
    -- 9: Small Rotary SP (9 params, IDs 932..940)
    [9] = {
        lst(932,  "Speed",         OV.SLOW_FAST, ORANGE),
        mod2(933, "Speed SW"),
        num(934,  "Horn Accel",    0, 99, nil, ORANGE),
        num(935,  "Horn Rate",     0, 99, nil, ORANGE),
        num(936,  "Mic Dist",      0, 99),
        num(937,  "Horn/Rotor",    0, 99),
        num(938,  "FX Balance",    0, 100, nil, RED),
        mod2(939, "Bal ModSrc"),
        mint(940, "Bal ModInt"),
    },
    -- 10: Delay (11 params, IDs 941..951)
    [10] = {
        mod2(941, "InLvl Src"),
        mint(942, "InLvl Int"),
        num(943,  "Delay Time",    0, 251, nil, ORANGE),
        num(944,  "Feedback",      -99, 99, nil, RED),
        mod2(945, "FB ModSrc"),
        mint(946, "FB ModInt"),
        num(947,  "Low Damp",      0, 99, nil, ORANGE),
        num(948,  "High Damp",     0, 99, nil, ORANGE),
        num(949,  "FX Balance",    0, 100, nil, RED),
        mod2(950, "Bal ModSrc"),
        mint(951, "Bal ModInt"),
    },
    -- 11: Talking Modulator (11 params, IDs 952..962; FX1 only)
    [11] = {
        lst(952,  "Ctrl Mode",     OV.TALK_MODE, PURPLE),
        num(953,  "Manual Ctrl",   0, 99, nil, ORANGE),
        mod2(954, "Ctrl Src"),
        lst(955,  "Voice Top",     OV.VOWEL, ORANGE),
        lst(956,  "Voice Ctr",     OV.VOWEL, ORANGE),
        lst(957,  "Voice Bot",     OV.VOWEL, ORANGE),
        num(958,  "Formant",       -99, 99, nil, RED),
        num(959,  "Resonance",     0, 99, nil, RED),
        num(960,  "FX Balance",    0, 100, nil, RED),
        mod2(961, "Bal ModSrc"),
        mint(962, "Bal ModInt"),
    },
    -- 12: Multitap Delay (17 params, IDs 963..979; FX1 only)
    [12] = {
        lst(963,  "Tap Type",      OV.MTAP_TYPE, PURPLE),
        mod2(964, "InLvl Src"),
        mint(965, "InLvl Int"),
        num(966,  "Tap1 Time",     0, 251, nil, ORANGE),
        num(967,  "Tap1 Level",    0, 99),
        num(968,  "Tap2 Time",     0, 251, nil, ORANGE),
        num(969,  "Feedback",      -99, 99, nil, RED),
        mod2(970, "FB ModSrc"),
        mint(971, "FB ModInt"),
        num(972,  "Low Damp",      0, 99, nil, ORANGE),
        num(973,  "High Damp",     0, 99, nil, ORANGE),
        num(974,  "Spread",        -99, 99, nil, ORANGE),
        mod2(975, "Spread Src"),
        mint(976, "Spread Int"),
        num(977,  "FX Balance",    0, 100, nil, RED),
        mod2(978, "Bal ModSrc"),
        mint(979, "Bal ModInt"),
    },
    -- 13: Ensemble (10 params, IDs 980..989; FX1 only)
    [13] = {
        num(980,  "Speed",         0, 99, nil, ORANGE),
        mod2(981, "Speed Src"),
        mint(982, "Speed Int"),
        num(983,  "Shimmer",       0, 99, nil, ORANGE),
        num(984,  "Depth",         0, 99, nil, RED),
        mod2(985, "Depth Src"),
        mint(986, "Depth Int"),
        num(987,  "FX Balance",    0, 100, nil, RED),
        mod2(988, "Bal ModSrc"),
        mint(989, "Bal ModInt"),
    },
    -- 14: Rotary Speaker (14 params, IDs 990..1003; FX1 only)
    [14] = {
        lst(990,  "Speed",         OV.SLOW_FAST, ORANGE),
        mod2(991, "Speed SW"),
        lst(992,  "Rot Mode",      OV.ROT_MODE, PURPLE),
        mod2(993, "Mode SW"),
        num(994,  "Rotor Accel",   0, 99, nil, ORANGE),
        num(995,  "Rotor Rate",    0, 99, nil, ORANGE),
        num(996,  "Horn Accel",    0, 99, nil, ORANGE),
        num(997,  "Horn Rate",     0, 99, nil, ORANGE),
        num(998,  "Mic Dist",      0, 99),
        num(999,  "Mic Spread",    0, 99),
        num(1000, "Horn/Rotor",    0, 99),
        num(1001, "FX Balance",    0, 100, nil, RED),
        mod2(1002,"Bal ModSrc"),
        mint(1003,"Bal ModInt"),
    },
}

MFX_MODELS = {
    -- 0: Stereo Delay (14 params, IDs 1004..1017, ExID = 5)
    [0] = {
        lst(1004, "Delay Type",    OV.STDLY_TYPE, PURPLE),
        mod2(1005,"InLvl Src"),
        mint(1006,"InLvl Int"),
        num(1007, "Left Time",     0, 251, nil, ORANGE),
        num(1008, "Right Time",    0, 251, nil, ORANGE),
        num(1009, "Feedback L",    -99, 99, nil, RED),
        num(1010, "Feedback R",    -99, 99, nil, RED),
        mod2(1011,"FB ModSrc"),
        mint(1012,"FB ModInt"),
        num(1013, "Low Damp",      0, 99, nil, ORANGE),
        num(1014, "High Damp",     0, 99, nil, ORANGE),
        num(1015, "FX Balance",    0, 100, nil, RED),
        mod2(1016,"Bal ModSrc"),
        mint(1017,"Bal ModInt"),
    },
    -- 1: Reverb-Hall (10 params, IDs 1018..1027, ExID = 5)
    [1] = {
        num(1018, "Reverb Time",   1, 100, nil, ORANGE),
        num(1019, "Pre Delay",     0, 200, nil, ORANGE),
        num(1020, "PreDly Thru",   0, 99),
        num(1021, "High Damp",     0, 99, nil, ORANGE),
        num(1022, "PreEQ Trim",    0, 99),
        num(1023, "PreLo Gain",    -36, 36, "dbhalf", ORANGE),
        num(1024, "PreHi Gain",    -36, 36, "dbhalf", ORANGE),
        num(1025, "FX Balance",    0, 100, nil, RED),
        mod2(1026,"Bal ModSrc"),
        mint(1027,"Bal ModInt"),
    },
    -- 2: Reverb-Room (12 params, IDs 1028..1039, ExID = 5)
    [2] = {
        num(1028, "Reverb Time",   1, 30, nil, ORANGE),
        num(1029, "Pre Delay",     0, 200, nil, ORANGE),
        num(1030, "PreDly Thru",   0, 99),
        num(1031, "High Damp",     0, 99, nil, ORANGE),
        num(1032, "ER Level",      0, 99),
        num(1033, "Reverb Lvl",    0, 99),
        num(1034, "PreEQ Trim",    0, 99),
        num(1035, "PreLo Gain",    -36, 36, "dbhalf", ORANGE),
        num(1036, "PreHi Gain",    -36, 36, "dbhalf", ORANGE),
        num(1037, "FX Balance",    0, 100, nil, RED),
        mod2(1038,"Bal ModSrc"),
        mint(1039,"Bal ModInt"),
    },
}

-- ============================================================================
-- 3. State, FX Preset Bank & SysEx Sender
-- ============================================================================

STATIC_FX_TOP = {
    [1]  = { id = 359, kind = "list", ov = OV.FX1_TYPE, unit = 0 },
    [2]  = { id = 360, kind = "list", ov = OV.FX2_TYPE, unit = 1 },
    [3]  = { id = 361, kind = "list", ov = OV.MFX_TYPE, unit = 2 },
    [4]  = { id = 356, kind = "num" },
    [5]  = { id = 357, kind = "list", ov = OV.MODSRC1 },
    [6]  = { id = 358, kind = "num" },
    [7]  = { id = 362, kind = "num" },
    [8]  = { id = 363, kind = "num",  fmt = "dbhalf" },
    [9]  = { id = 364, kind = "num" },
    [10] = { id = 365, kind = "num",  fmt = "dbhalf" },
}

fxUnitType = { [0] = 0, [1] = 0, [2] = 0 } -- Selected algorithm for FX1 (0..14), FX2 (0..10), MFX (0..2)
activeEditUnit = 0 -- 0 = FX1 (ExID 3), 1 = FX2 (ExID 4), 2 = Master FX (ExID 5)
local activeFxDefs = {}
local suppressFxSlot = {}

-- Saved values per unit (0..2) and paramId
fxSavedValues = { [0] = {}, [1] = {}, [2] = {} }

-- Persistent FX Preset Library (supports per-unit presets and full FX-chain presets)
fxPresetBank = {
    unit  = { [1] = {}, [2] = {} },
    chain = { [1] = nil },
}

function fmtDbHalf(_valueObject, value)
    return string.format("%+.1f dB", math.floor(value) * 0.5)
end

function fmtFxSlot(valueObject, value)
    local slot = valueObject:getControl():getId() % 100
    local def = activeFxDefs[slot]
    local v = math.floor(value)
    if not def or not def.fmt then
        return tostring(v)
    end
    if def.fmt == "dbhalf" then
        return string.format("%+.1f dB", v * 0.5)
    elseif def.fmt == "plus1" then
        return tostring(v + 1)
    end
    return tostring(v)
end

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
-- 4. Dynamic FX Relayout & Callbacks
-- ============================================================================

local function getUnitDefs(unit)
    local alg = fxUnitType[unit] or 0
    if unit == 2 then
        return MFX_MODELS[alg] or MFX_MODELS[0]
    end
    return FX12_MODELS[alg] or FX12_MODELS[0]
end

local function getUnitTitle(unit)
    local alg = fxUnitType[unit] or 0
    if unit == 0 then
        return "FX 1: " .. ((FX1_TYPES[alg + 1] and FX1_TYPES[alg + 1].label) or "FX1")
    elseif unit == 1 then
        return "FX 2: " .. ((FX2_TYPES[alg + 1] and FX2_TYPES[alg + 1].label) or "FX2")
    else
        return "MASTER FX: " .. ((MFX_TYPES[alg + 1] and MFX_TYPES[alg + 1].label) or "MFX")
    end
end

function applyFxLayout()
    local defs = getUnitDefs(activeEditUnit)
    activeFxDefs = {}
    suppressFxSlot = {}

    window.stop()
    local title = getUnitTitle(activeEditUnit)
    local grp2 = preset.getGroup(51)
    local grp3 = preset.getGroup(52)
    if grp2 then grp2:setLabel(title .. " PARAMETERS (1..12)") end
    if grp3 then grp3:setLabel(title .. " PARAMETERS (13..20)") end

    local saved = fxSavedValues[activeEditUnit]
    for s = 1, 20 do
        local def = defs[s]
        local fader = controls.get(100 + s)
        local list  = controls.get(200 + s)

        if not def then
            fader:setVisible(false)
            list:setVisible(false)
        elseif def.kind == "list" then
            activeFxDefs[s] = def
            fader:setVisible(false)

            local initVal = saved[def.id] or 0
            local vo = list:getValue("value")
            vo:setOverlayId(def.ov)
            suppressFxSlot[200 + s] = true
            vo:updateValue(initVal)
            suppressFxSlot[200 + s] = nil
            list:setName(def.name)
            list:setColor(def.color or PURPLE)
            list:setVisible(true)
        else
            activeFxDefs[s] = def
            list:setVisible(false)

            local neutral = (def.min < 0 and def.max > 0) and 0 or def.min
            local initVal = saved[def.id]
            if initVal == nil then initVal = neutral end

            local vo = fader:getValue("value")
            local span = def.max - def.min
            vo:getMessage():setRange(0, span)
            vo:setRange(def.min, def.max, neutral, false)
            suppressFxSlot[100 + s] = true
            vo:updateValue(initVal)
            suppressFxSlot[100 + s] = nil
            fader:setName(def.name)
            fader:setColor(def.color or WHITE)
            fader:setVisible(true)
        end
    end
    window.resume()
end

function onStaticFxTop(valueObject, value)
    local ctrlId = valueObject:getControl():getId()
    local spec = STATIC_FX_TOP[ctrlId]
    if not spec then
        return
    end
    local v = math.floor(value)
    local z1Val = v
    if spec.kind == "list" then
        local ov = overlays.get(spec.ov)
        z1Val = (ov and ov:getValueByIndex(v)) or v
    end

    if spec.unit ~= nil then
        fxUnitType[spec.unit] = z1Val
        if spec.unit == activeEditUnit then
            applyFxLayout()
        end
    end
    sendParamChange(0, spec.id, z1Val)
end

function onEditUnitSelect(_valueObject, value)
    local u = math.floor(value)
    if u < 0 or u > 2 or u == activeEditUnit then
        return
    end
    activeEditUnit = u
    applyFxLayout()
    info.setText(getUnitTitle(activeEditUnit))
end

function onFxSlot(valueObject, value)
    local ctrl = valueObject:getControl()
    local ctrlId = ctrl:getId()
    if suppressFxSlot[ctrlId] then
        suppressFxSlot[ctrlId] = nil
        return
    end
    if not ctrl:isVisible() then
        return
    end
    local s = ctrlId % 100
    local def = activeFxDefs[s]
    if not def then
        return
    end

    local rawVal = math.floor(value)
    fxSavedValues[activeEditUnit][def.id] = rawVal

    local z1Val = rawVal
    if def.kind == "list" then
        local ov = overlays.get(def.ov)
        z1Val = (ov and ov:getValueByIndex(rawVal)) or rawVal
    end

    -- ExID: FX1 = 3, FX2 = 4, Master FX = 5
    local exId = activeEditUnit + 3
    sendParamChange(exId, def.id, z1Val)
end

-- Save/Recall Per-Unit or Full-Chain FX Presets
function onFxPresetAction(_valueObject, value)
    local act = math.floor(value)
    if act == 0 then
        return
    end
    local defs = getUnitDefs(activeEditUnit)
    if act == 3 or act == 4 then
        -- Save current active unit to slot 1 or 2
        local pSlot = act - 2
        local snap = { alg = fxUnitType[activeEditUnit], params = {} }
        for _, d in ipairs(defs) do
            snap.params[d.id] = fxSavedValues[activeEditUnit][d.id] or 0
        end
        fxPresetBank.unit[pSlot][activeEditUnit] = snap
        if type(persist) == "function" then pcall(persist, fxPresetBank) end
        info.setText("Saved Unit Preset " .. pSlot)
    elseif act == 1 or act == 2 then
        -- Recall active unit from slot 1 or 2
        local pSlot = act
        local snap = fxPresetBank.unit[pSlot][activeEditUnit]
        if snap then
            fxUnitType[activeEditUnit] = snap.alg
            sendParamChange(0, 359 + activeEditUnit, snap.alg)
            local exId = activeEditUnit + 3
            for _, d in ipairs(getUnitDefs(activeEditUnit)) do
                local rawVal = snap.params[d.id] or 0
                fxSavedValues[activeEditUnit][d.id] = rawVal
                local z1Val = rawVal
                if d.kind == "list" then
                    local ov = overlays.get(d.ov)
                    z1Val = (ov and ov:getValueByIndex(rawVal)) or rawVal
                end
                sendParamChange(exId, d.id, z1Val)
            end
            applyFxLayout()
            info.setText("Loaded Unit Preset " .. pSlot)
        end
    elseif act == 6 then
        -- Save Full FX Chain (FX1 + FX2 + MFX)
        local chain = { units = {} }
        for u = 0, 2 do
            local uSnap = { alg = fxUnitType[u], params = {} }
            for _, d in ipairs(getUnitDefs(u)) do
                uSnap.params[d.id] = fxSavedValues[u][d.id] or 0
            end
            chain.units[u] = uSnap
        end
        fxPresetBank.chain[1] = chain
        if type(persist) == "function" then pcall(persist, fxPresetBank) end
        info.setText("Saved FX Chain 1")
    elseif act == 5 then
        -- Load Full FX Chain 1
        local chain = fxPresetBank.chain[1]
        if chain and chain.units then
            for u = 0, 2 do
                local uSnap = chain.units[u]
                if uSnap then
                    fxUnitType[u] = uSnap.alg
                    sendParamChange(0, 359 + u, uSnap.alg)
                    for pid, rv in pairs(uSnap.params) do
                        fxSavedValues[u][pid] = rv
                    end
                end
            end
            applyFxLayout()
            info.setText("Loaded FX Chain 1")
        end
    end
end

-- ============================================================================
-- 5. Lifecycle Hooks
-- ============================================================================

function preset.onLoad()
    for ovId, items in pairs(ENUM_DEFS) do
        overlays.create(ovId, items)
    end
    if type(recall) == "function" then
        pcall(recall, fxPresetBank)
    end
end

function preset.onReady()
    for cid, spec in pairs(STATIC_FX_TOP) do
        if spec.kind == "list" then
            controls.get(cid):getValue("value"):setOverlayId(spec.ov)
        end
    end
    controls.get(11):getValue("value"):setOverlayId(OV.EDIT_UNIT)
    controls.get(12):getValue("value"):setOverlayId(OV.PRESET_ACT)
    applyFxLayout()
    info.setText("Z1 Effects Ready")
end
