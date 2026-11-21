-- Korg Z1 - FX1, FX2, Master FX, 2-Band EQ & FX Preset Manager for Electra One mk2
-- Covers:
--   [Effect Send & Selects] (IDs 356..361, ExID = 0)
--   [2-Band EQ]             (IDs 362..365, ExID = 0)
--   [Effect 1 Parameters]   (IDs 800..1003, ExID = 3, 15 algorithms)
--   [Effect 2 Parameters]   (IDs 800..951,  ExID = 4, 11 algorithms)
--   [Master FX Parameters]  (IDs 1004..1039, ExID = 5, 3 algorithms)
--   [FX Preset Library]     (Named presets: 8 slots per FX type, 25 FX-chain slots, persist/recall)
--
-- Layout:
--   Control Set 1 (Rows 1-2, Slots 1..12):
--     Row 1 (Slots 1..6):  [11] EDIT FX (FX1/FX2/MFX), [1] FX1 Select (359), [2] FX2 Select (360),
--                          [3] MFX Select (361),       [4] FX Send (356),    [5] Send ModSrc (357)
--     Row 2 (Slots 7..12): [6] Send ModInt (358),      [7] EQ LoFreq (362),  [8] EQ LoGain (363),
--                          [9] EQ HiFreq (364),        [10] EQ HiGain (365), [12] FX PRESETS (toggle pad)
--     FX2 Select is hidden while FX1 = Talking Mod / Multitap Dly / Ensemble / Rotary Spkr (FX1-only).
--   Control Set 2 & 3 (Rows 3-6, Dynamic Slots 1..20 -> Faders 101..120 / Lists 201..220):
--     Up to 20 parameters for the active FX1 (ExID 3), FX2 (ExID 4), or Master FX (ExID 5) algorithm.
--   Preset Library view (FX PRESETS on; replaces Control Sets 2 & 3):
--     [301] Preset Type (FX1/FX2/MFX/Chain), [302] Slot, [303] Preset List, [304] Load, [305] Save,
--     [306] Name Pos, [307] Name Char, [308] Rename, [309] Delete

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
    PRESET_TGT  = 7,
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
    [OV.PRESET_TGT] = {
        { value = 0, label = "FX 1" },
        { value = 1, label = "FX 2" },
        { value = 2, label = "Master FX" },
        { value = 3, label = "FX Chain" },
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
-- 3. State, SysEx Sender & Helpers
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

-- Current Z1 values of the top-row Send / EQ parameters (JSON defaults), used by chain presets
fxTopZ1 = { [356] = 50, [357] = 0, [358] = 0, [362] = 10, [363] = 0, [364] = 20, [365] = 0 }

fxUnitType = { [0] = 0, [1] = 0, [2] = 0 } -- Selected algorithm for FX1 (0..14), FX2 (0..10), MFX (0..2)
activeEditUnit = 0 -- 0 = FX1 (ExID 3), 1 = FX2 (ExID 4), 2 = Master FX (ExID 5)
local activeFxDefs = {}
local suppressFxSlot = {}
local suppressTop = false

-- Saved values per unit (0..2) and paramId (raw control values: list = overlay index)
fxSavedValues = { [0] = {}, [1] = {}, [2] = {} }

-- FX1-only algorithms (Talking Mod, Multitap Dly, Ensemble, Rotary Spkr): the Z1 cannot use FX2 meanwhile
FX1_ONLY_TYPES = { [11] = true, [12] = true, [13] = true, [14] = true }

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

function fmtDbHalf(_valueObject, value)
    return string.format("%+.1f dB", math.floor(value) * 0.5)
end

function fmtFxSlot(valueObject, value)
    local slot = valueObject:getControl():getId() % 50
    return formatSlotValue(activeFxDefs[slot], value)
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

-- Update a top-row control display (Z1 value) without re-sending it
local function setTopControl(ctrlId, z1Val)
    local spec = STATIC_FX_TOP[ctrlId]
    local c = controls.get(ctrlId)
    if not spec or not c then return end
    local disp = (spec.kind == "list") and z1ValToIdx(spec.ov, z1Val) or z1Val
    suppressTop = true
    c:getValue("value"):updateValue(disp)
    suppressTop = false
end

local function unitTypeLabel(unit, alg)
    local ovId = (unit == 0 and OV.FX1_TYPE) or (unit == 1 and OV.FX2_TYPE) or OV.MFX_TYPE
    local ov = overlays.get(ovId)
    return (ov and ov.getLabelByIndex and ov:getLabelByIndex(alg or 0)) or "?"
end

function isFx2Available()
    return not FX1_ONLY_TYPES[fxUnitType[0] or 0]
end

-- Hide "FX2 Select" while FX1 runs an FX1-only algorithm
function updateFx2Visibility()
    local c = controls.get(2)
    if c then c:setVisible(isFx2Available()) end
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
        return "FX 1: " .. unitTypeLabel(0, alg)
    elseif unit == 1 then
        if not isFx2Available() then
            return "FX 2: N/A (FX1 = " .. unitTypeLabel(0, fxUnitType[0]) .. ")"
        end
        return "FX 2: " .. unitTypeLabel(1, alg)
    else
        return "MASTER FX: " .. unitTypeLabel(2, alg)
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

function applyFxLayout()
    if presetView then
        showPresetManager()
        return
    end
    local fx2Blocked = (activeEditUnit == 1) and not isFx2Available()
    local defs = fx2Blocked and {} or getUnitDefs(activeEditUnit)
    activeFxDefs = {}
    suppressFxSlot = {}

    window.stop()
    setPresetControlsVisible(false)
    local title = getUnitTitle(activeEditUnit)
    local grp2 = preset.getGroup(51)
    local grp3 = preset.getGroup(52)
    if fx2Blocked then
        if grp2 then grp2:setLabel(title .. " - FX2 NOT USABLE WITH THIS FX1 TYPE") end
        if grp3 then grp3:setLabel(title) end
    else
        if grp2 then grp2:setLabel(title .. " PARAMETERS (1..12)") end
        if grp3 then grp3:setLabel(title .. " PARAMETERS (13..20)") end
    end
    if grp3 then grp3:setVisible(true) end

    applyDynamicSlots(defs, 1, 20, 0, 100, 200, activeFxDefs, fxSavedValues[activeEditUnit], nil, suppressFxSlot)
    window.resume()
end

function onStaticFxTop(valueObject, value)
    if suppressTop then
        return
    end
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

    if fxTopZ1[spec.id] ~= nil then
        fxTopZ1[spec.id] = z1Val
    end
    if spec.unit ~= nil then
        fxUnitType[spec.unit] = z1Val
        if spec.unit == 0 then
            updateFx2Visibility()
        end
        if spec.unit == activeEditUnit or (spec.unit == 0 and activeEditUnit == 1) or presetView then
            applyFxLayout()
        end
    end
    sendParamChange(0, spec.id, z1Val)
end

function onEditUnitSelect(_valueObject, value)
    local u = math.floor(value)
    if u < 0 or u > 2 or (u == activeEditUnit and not presetView) then
        return
    end
    activeEditUnit = u
    if presetView then
        setPresetView(false)
    else
        applyFxLayout()
    end
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
    local s = ctrlId % 50
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

-- ============================================================================
-- 4b. Named FX Preset Library
--   * Per FX type: 8 named slots for every FX1/FX2 algorithm (shared by FX1 and FX2, same parameters)
--     and for every Master FX algorithm.
--   * FX chains: 25 named slots (FX1 + FX2 + Master FX types/parameters, FX Send and 2-Band EQ).
--   Opened with the "FX PRESETS" pad (control 12); uses Control Set 2 while the FX slots are hidden.
-- ============================================================================

UNIT_PRESET_SLOTS  = 8
CHAIN_PRESET_SLOTS = 25
PRESET_NAME_LEN    = 16

CHAIN_TOP_IDS  = { 356, 357, 358, 362, 363, 364, 365 }
CHAIN_TOP_CTRL = { 4, 5, 6, 7, 8, 9, 10 }

PRESET_CTRL = {
    TARGET = 301, SLOT = 302, LIST = 303, LOAD = 304, SAVE = 305,
    NPOS = 306, NCHAR = 307, RENAME = 308, DELETE = 309,
}

-- Persisted with persist()/recall() as data.json. JSON-safe layout: string keys and dense 1..n arrays only.
--   fxLib.unit["fx6"]["s3"]  = { name = "Warm Chorus", v = { Z1 values in FX12_MODELS[6] order } }
--   fxLib.unit["mfx1"]["s1"] = { name = "Big Hall",    v = { Z1 values in MFX_MODELS[1] order } }
--   fxLib.chain["s12"]       = { name = "Lead Chain", sel = { fx1, fx2, mfx }, top = { 356,357,358,362..365 },
--                                u1 = {...}, u2 = {...}, u3 = {...} }
-- recall() returns empty tables flagged as JSON arrays; string keys added to those are dropped by persist().
-- Copy into plain tables so later saves are written as objects.
local function plainCopy(t)
    local out = {}
    for k, v in pairs(t) do
        out[k] = (type(v) == "table") and plainCopy(v) or v
    end
    return out
end

-- persist() blocks the UI: ~65 ms per write, ~1.9 s when the card was idle for ~40 s.
-- Writes are deferred and coalesced; while a preset manager view is open the card is kept warm.
if not _G.z1RequestPersist then
    local pending, waiters = false, {}
    local warmOwners, warmHandle, warmTicks = {}, nil, 0
    local WARM_PERIOD_MS, WARM_MAX_TICKS = 20000, 30

    local function writeLib()
        if type(persist) ~= "function" then return false end
        return (pcall(persist, _G.z1PersistLib))
    end

    local function hasSchedule()
        return type(schedule) == "table" and type(schedule.after) == "function"
    end

    local function stopWarm()
        if warmHandle then
            pcall(schedule.cancel, warmHandle)
            warmHandle = nil
        end
    end

    local function startWarm(initialWrite)
        if warmHandle or next(warmOwners) == nil or not hasSchedule() then return end
        warmTicks = 0
        if initialWrite then
            pcall(schedule.after, 250, function()
                if next(warmOwners) ~= nil and not pending then
                    if info and info.setText then info.setText("Preparing preset storage...") end
                    writeLib()
                end
            end)
        end
        local ok, h = pcall(schedule.every, WARM_PERIOD_MS, function()
            warmTicks = warmTicks + 1
            if warmTicks > WARM_MAX_TICKS or next(warmOwners) == nil then
                stopWarm()
            elseif not pending then
                writeLib()
            end
        end)
        if ok then warmHandle = h end
    end

    function _G.z1RequestPersist(onDone)
        if onDone then waiters[#waiters + 1] = onDone end
        warmTicks = 0
        startWarm(false)
        if pending then return end
        pending = true
        local function run()
            pending = false
            local ok = writeLib()
            local w = waiters
            waiters = {}
            for _, f in ipairs(w) do pcall(f, ok) end
        end
        if not (hasSchedule() and pcall(schedule.after, 50, run)) then
            run()
        end
    end

    function _G.z1WarmPersist(owner, on)
        if on then
            warmOwners[owner] = true
            startWarm(true)
        else
            warmOwners[owner] = nil
            if next(warmOwners) == nil then stopWarm() end
        end
    end
end

fxLib = _G.z1PersistLib or { version = 2, unit = {}, chain = {}, tuning = {}, oscUnit = {}, oscDual = {} }
_G.z1PersistLib = fxLib
fxLib.unit = fxLib.unit or {}
fxLib.chain = fxLib.chain or {}
fxLib.tuning = fxLib.tuning or {}
fxLib.oscUnit = fxLib.oscUnit or {}
fxLib.oscDual = fxLib.oscDual or {}

presetView    = false
presetTarget  = 0 -- 0 = FX1, 1 = FX2, 2 = Master FX, 3 = FX Chain
presetSlot    = 1
presetNamePos = 1
presetName    = {}
local suppressPreset = false
local shownPresetBank = nil
local pendingDelete = nil

local function defaultRaw(def)
    if def.kind == "list" then return 0 end
    return (def.min < 0 and def.max > 0) and 0 or def.min
end

local function rawToZ1(def, raw)
    if def.kind == "list" then
        local ov = overlays.get(def.ov)
        return (ov and ov:getValueByIndex(raw)) or raw
    end
    return raw
end

local function z1ToRaw(def, z1)
    if def.kind == "list" then
        return z1ValToIdx(def.ov, z1)
    end
    return z1
end

local function presetBankKey()
    if presetTarget == 3 then return "chain" end
    if presetTarget == 2 then return "mfx" .. tostring(fxUnitType[2] or 0) end
    return "fx" .. tostring(fxUnitType[presetTarget] or 0)
end

local function presetSlotCount()
    return (presetTarget == 3) and CHAIN_PRESET_SLOTS or UNIT_PRESET_SLOTS
end

local function getPresetEntry(slot)
    local key = "s" .. tostring(slot)
    if presetTarget == 3 then
        return fxLib.chain[key]
    end
    local bank = fxLib.unit[presetBankKey()]
    return (type(bank) == "table") and bank[key] or nil
end

local function setPresetEntry(slot, entry)
    local key = "s" .. tostring(slot)
    if presetTarget == 3 then
        fxLib.chain[key] = entry
    else
        local bk = presetBankKey()
        if type(fxLib.unit[bk]) ~= "table" then fxLib.unit[bk] = {} end
        fxLib.unit[bk][key] = entry
    end
end

local function savePresetLibrary(onDone)
    z1RequestPersist(onDone)
end

local function defaultPresetName(slot)
    if presetTarget == 3 then
        return string.format("Chain %02d", slot)
    end
    return string.format("%s %d", unitTypeLabel(presetTarget, fxUnitType[presetTarget]), slot)
end

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

local function setNameBuffer(str)
    setNameCharsBuffer(presetName, str, 0x7E)
end

local function getNameBuffer()
    return getProgramNameString(presetName, true)
end

local function presetHeader()
    if presetTarget == 3 then
        return string.format("FX CHAIN PRESETS (%d)", CHAIN_PRESET_SLOTS)
    end
    local unitName = ({ [0] = "FX1", [1] = "FX2", [2] = "MFX" })[presetTarget]
    return string.format("%s %s PRESETS (%d)", unitName,
        string.upper(unitTypeLabel(presetTarget, fxUnitType[presetTarget])), UNIT_PRESET_SLOTS)
end

local function captureUnitValues(unit)
    local v = {}
    for i, d in ipairs(getUnitDefs(unit)) do
        local raw = fxSavedValues[unit][d.id]
        if raw == nil then raw = defaultRaw(d) end
        v[i] = rawToZ1(d, raw)
    end
    return v
end

local function applyUnitValues(unit, v)
    local exId = unit + 3
    for i, d in ipairs(getUnitDefs(unit)) do
        local z1 = (type(v) == "table") and v[i] or nil
        if type(z1) == "number" then
            fxSavedValues[unit][d.id] = z1ToRaw(d, z1)
            sendParamChange(exId, d.id, z1)
        end
    end
end

local function captureChain(name)
    local top = {}
    for i, id in ipairs(CHAIN_TOP_IDS) do
        top[i] = fxTopZ1[id] or 0
    end
    return {
        name = name,
        sel  = { fxUnitType[0] or 0, fxUnitType[1] or 0, fxUnitType[2] or 0 },
        top  = top,
        u1   = captureUnitValues(0),
        u2   = captureUnitValues(1),
        u3   = captureUnitValues(2),
    }
end

local function applyChain(e)
    local units = { e.u1, e.u2, e.u3 }
    for u = 0, 2 do
        local alg = (type(e.sel) == "table") and e.sel[u + 1] or nil
        if type(alg) == "number" then
            fxUnitType[u] = alg
            sendParamChange(0, 359 + u, alg) -- FX select first, then its parameters
            setTopControl(u + 1, alg)
            applyUnitValues(u, units[u + 1])
        end
    end
    for i, id in ipairs(CHAIN_TOP_IDS) do
        local z1 = (type(e.top) == "table") and e.top[i] or nil
        if type(z1) == "number" then
            fxTopZ1[id] = z1
            sendParamChange(0, id, z1)
            setTopControl(CHAIN_TOP_CTRL[i], z1)
        end
    end
    updateFx2Visibility()
end

local function repaintPresetList()
    local c = controls.get(PRESET_CTRL.LIST)
    if c then c:repaint() end
end

local function syncNameChar()
    local c = controls.get(PRESET_CTRL.NCHAR)
    if c then
        suppressPreset = true
        c:getValue("value"):updateValue(presetName[presetNamePos] or 0x20)
        suppressPreset = false
    end
end

local function selectPresetSlot(slot)
    local n = presetSlotCount()
    presetSlot = math.max(1, math.min(n, slot))
    pendingDelete = nil
    local e = getPresetEntry(presetSlot)
    setNameBuffer(e and e.name or defaultPresetName(presetSlot))
    syncNameChar()
    repaintPresetList()
end

function setPresetControlsVisible(on)
    for _, cid in pairs(PRESET_CTRL) do
        local c = controls.get(cid)
        if c then c:setVisible(on) end
    end
end

function showPresetManager()
    window.stop()
    for s = 1, 20 do
        controls.get(100 + s):setVisible(false)
        local tf = controls.get(150 + s)
        if tf then tf:setVisible(false) end
        controls.get(200 + s):setVisible(false)
    end
    local grp2 = preset.getGroup(51)
    local grp3 = preset.getGroup(52)
    if grp2 then grp2:setLabel("FX PRESET LIBRARY - " .. presetHeader()) end
    if grp3 then grp3:setVisible(false) end
    setPresetControlsVisible(true)

    local n = presetSlotCount()
    local slotCtrl = controls.get(PRESET_CTRL.SLOT)
    if slotCtrl then
        local vo = slotCtrl:getValue("value")
        vo:getMessage():setRange(0, n - 1)
        vo:setRange(1, n, 1, false)
    end
    local bank = presetBankKey()
    if bank ~= shownPresetBank then
        shownPresetBank = bank
        selectPresetSlot(presetSlot)
    end
    if slotCtrl then
        suppressPreset = true
        slotCtrl:getValue("value"):updateValue(presetSlot)
        suppressPreset = false
    end
    local tgt = controls.get(PRESET_CTRL.TARGET)
    if tgt then
        suppressPreset = true
        tgt:getValue("value"):updateValue(presetTarget)
        suppressPreset = false
    end
    syncNameChar()
    repaintPresetList()
    window.resume()
end

function setPresetView(on)
    presetView = on and true or false
    z1WarmPersist("fx", presetView)
    if presetView and presetTarget ~= 3 then
        presetTarget = activeEditUnit
    end
    local pad = controls.get(12)
    if pad then
        suppressPreset = true
        pad:getValue("value"):updateValue(presetView and 1 or 0)
        suppressPreset = false
    end
    applyFxLayout()
end

function paintPresetList(control)
    local b = control:getBounds()
    local w, h = b[WIDTH], b[HEIGHT]
    graphics.setColor(0x18202C)
    graphics.fillRect(0, 0, w, h)
    graphics.setColor(0x03A598)
    graphics.drawRect(0, 0, w, h)

    graphics.setColor(ORANGE)
    graphics.print(6, 3, presetHeader(), w - 12, LEFT)

    local chars = {}
    for i = 1, PRESET_NAME_LEN do
        local ch = string.char(presetName[i] or 0x20)
        chars[i] = (i == presetNamePos) and ("[" .. ch .. "]") or ch
    end
    graphics.setColor(WHITE)
    graphics.print(6, 21, "Name: " .. table.concat(chars), w - 12, LEFT)

    local n = presetSlotCount()
    local rows = 6
    local first = math.max(1, math.min(presetSlot - 2, n - rows + 1))
    for r = 0, rows - 1 do
        local s = first + r
        if s > n then break end
        local y = 40 + r * 17
        local e = getPresetEntry(s)
        if s == presetSlot then
            graphics.setColor(0x03A598)
            graphics.fillRect(2, y - 1, w - 4, 17)
            graphics.setColor(0x000000)
        else
            graphics.setColor(e and WHITE or 0x7A8290)
        end
        graphics.print(8, y, string.format("%02d  %s", s, e and e.name or "- empty -"), w - 16, LEFT)
    end
end

-- Control 12: "FX PRESETS" toggle pad (open / close the preset library)
function onFxPresetView(_valueObject, value)
    if suppressPreset then return end
    local on = math.floor(value) > 0
    if on ~= presetView then
        setPresetView(on)
    end
end

function onPresetTarget(_valueObject, value)
    if suppressPreset then return end
    local t = math.max(0, math.min(3, math.floor(value)))
    if t == presetTarget then return end
    presetTarget = t
    if presetView then showPresetManager() end
    info.setText(presetHeader())
end

function onPresetSlot(_valueObject, value)
    if suppressPreset then return end
    selectPresetSlot(math.floor(value))
end

function fmtPresetSlot(_valueObject, value)
    local s = math.floor(value)
    local e = getPresetEntry(s)
    return string.format("%02d %s", s, e and e.name or "<empty>")
end

function onNamePos(_valueObject, value)
    presetNamePos = math.max(1, math.min(PRESET_NAME_LEN, math.floor(value)))
    syncNameChar()
    repaintPresetList()
end

function onNameChar(_valueObject, value)
    if suppressPreset then return end
    local c = math.max(0x20, math.min(0x7E, math.floor(value)))
    presetName[presetNamePos] = c
    repaintPresetList()
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

function onPresetLoad(_valueObject, value)
    if math.floor(value) <= 0 then return end
    pendingDelete = nil
    local e = getPresetEntry(presetSlot)
    if not e then
        info.setText(string.format("Slot %02d is empty", presetSlot))
        return
    end
    if presetTarget == 3 then
        applyChain(e)
    else
        if presetTarget == 1 and not isFx2Available() then
            info.setText("FX2 not usable with FX1 " .. unitTypeLabel(0, fxUnitType[0]))
            return
        end
        applyUnitValues(presetTarget, e.v)
    end
    shownPresetBank = nil
    applyFxLayout()
    info.setText("Loaded: " .. tostring(e.name))
end

function onPresetSave(_valueObject, value)
    if math.floor(value) <= 0 then return end
    pendingDelete = nil
    local name = getNameBuffer()
    if name == "" then name = defaultPresetName(presetSlot) end
    local entry
    if presetTarget == 3 then
        entry = captureChain(name)
    else
        entry = { name = name, v = captureUnitValues(presetTarget) }
    end
    setPresetEntry(presetSlot, entry)
    local slot = presetSlot
    repaintPresetList()
    info.setText(string.format("Saving %02d: %s...", slot, name))
    savePresetLibrary(function(ok)
        info.setText(string.format("Saved %02d: %s%s", slot, name, ok and "" or " (RAM only)"))
    end)
end

function onPresetRename(_valueObject, value)
    if math.floor(value) <= 0 then return end
    pendingDelete = nil
    local e = getPresetEntry(presetSlot)
    if not e then
        info.setText("Slot empty - use Save")
        return
    end
    local name = getNameBuffer()
    if name == "" then name = defaultPresetName(presetSlot) end
    e.name = name
    savePresetLibrary()
    repaintPresetList()
    info.setText("Renamed: " .. name)
end

-- Delete needs two presses on the same slot
function onPresetDelete(_valueObject, value)
    if math.floor(value) <= 0 then return end
    if not getPresetEntry(presetSlot) then
        info.setText(string.format("Slot %02d is empty", presetSlot))
        return
    end
    if pendingDelete ~= presetSlot then
        pendingDelete = presetSlot
        info.setText(string.format("Press DELETE again to clear %02d", presetSlot))
        return
    end
    pendingDelete = nil
    setPresetEntry(presetSlot, nil)
    savePresetLibrary()
    setNameBuffer(defaultPresetName(presetSlot))
    syncNameChar()
    repaintPresetList()
    info.setText(string.format("Cleared slot %02d", presetSlot))
end

-- ============================================================================
-- 5. Lifecycle Hooks
-- ============================================================================

function preset.onLoad()
    for ovId, items in pairs(ENUM_DEFS) do
        overlays.create(ovId, items)
    end
    if type(recall) == "function" and (type(recallJson) ~= "function" or recallJson() ~= nil) then
        local stored = {}
        if pcall(recall, stored) and stored.version == 2 then
            if type(stored.unit) == "table" then fxLib.unit = plainCopy(stored.unit) end
            if type(stored.chain) == "table" then fxLib.chain = plainCopy(stored.chain) end
            if type(stored.tuning) == "table" then fxLib.tuning = plainCopy(stored.tuning) end
            if type(stored.oscUnit) == "table" then fxLib.oscUnit = plainCopy(stored.oscUnit) end
            if type(stored.oscDual) == "table" then fxLib.oscDual = plainCopy(stored.oscDual) end
        end
    end
    local listCtrl = preset.getControl(PRESET_CTRL.LIST)
    if listCtrl then
        listCtrl:setPaintCallback(paintPresetList)
    end
end

function preset.onReady()
    for cid, spec in pairs(STATIC_FX_TOP) do
        if spec.kind == "list" then
            controls.get(cid):getValue("value"):setOverlayId(spec.ov)
        end
    end
    controls.get(11):getValue("value"):setOverlayId(OV.EDIT_UNIT)
    controls.get(PRESET_CTRL.TARGET):getValue("value"):setOverlayId(OV.PRESET_TGT)
    setNameBuffer(defaultPresetName(presetSlot))
    updateFx2Visibility()
    applyFxLayout()
    info.setText("Z1 Effects Ready")
end

function preset.onZ1Param(exId, paramId, z1Val)
    if exId == 0 then
        for cid, spec in pairs(STATIC_FX_TOP) do
            if spec.id == paramId then
                if fxTopZ1[paramId] ~= nil then
                    fxTopZ1[paramId] = z1Val
                end
                if spec.unit ~= nil then
                    fxUnitType[spec.unit] = z1Val
                    if spec.unit == 0 then
                        updateFx2Visibility()
                    end
                    if spec.unit == activeEditUnit or (spec.unit == 0 and activeEditUnit == 1) or presetView then
                        applyFxLayout()
                    end
                end
                setTopControl(cid, z1Val)
                return
            end
        end
    elseif exId >= 3 and exId <= 5 then
        local unit = exId - 3
        local defs = getUnitDefs(unit)
        for _, def in ipairs(defs or {}) do
            if def.id == paramId then
                local disp = (def.kind == "list") and z1ValToIdx(def.ov, z1Val) or z1Val
                fxSavedValues[unit][paramId] = disp
                if unit == activeEditUnit then
                    applyFxLayout()
                end
                return
            end
        end
    end
end

function preset.onZ1Dump(params)
    local p0 = params and params[0]
    if not p0 then return end
    for cid, spec in pairs(STATIC_FX_TOP) do
        local z1Val = p0[spec.id]
        if z1Val ~= nil then
            if fxTopZ1[spec.id] ~= nil then
                fxTopZ1[spec.id] = z1Val
            end
            if spec.unit ~= nil then
                fxUnitType[spec.unit] = z1Val
            end
            setTopControl(cid, z1Val)
        end
    end
    for unit = 0, 2 do
        local exId = unit + 3
        local pUnit = params[exId] or {}
        for _, def in ipairs(getUnitDefs(unit) or {}) do
            if pUnit[def.id] ~= nil then
                fxSavedValues[unit][def.id] = (def.kind == "list") and z1ValToIdx(def.ov, pUnit[def.id]) or pUnit[def.id]
            end
        end
    end
    updateFx2Visibility()
    applyFxLayout()
end
