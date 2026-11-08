# Page 09 — Amp 1 & 2, Output/Pan, OSC 1 Pitch/Mod & Performance Editor (PE Knobs 1–5)

[⬅ Back to User Manual Index](../README.md)

- **Source Folder:** [`e1/z1-mod/`](../../e1/z1-mod/)
- **Files:** [`preset.json`](../../e1/z1-mod/preset.json) | [`main.lua`](../../e1/z1-mod/main.lua) | [`main-tests.lua`](../../e1/z1-mod/main-tests.lua)
- **Z1 Parameters Covered:** All **113** active parameters across `[Amp 1]` (`IDs 315..323`), `[Amp 2]` (`IDs 324..332`), `[Output]` (`IDs 352..355`), `[OSC1 Pitch]` (`IDs 175..187`), and `[Performance Editor Knob 1..5]` (`IDs 384..463`, 80 parameters), all with `ExID = 0`.

> 📸 **[Screenshot Placeholder: `../media/09-amp-mod-pe.png`]**
> *Add screenshots showing Amp 1/2 + Output/Pan on the top rows and switching `MOD SELECT` between `OSC1 Pitch/Mod` and `PE Knob 1..5`.*
>
> 🎬 **[Video Placeholder: `../media/09-amp-mod-pe.mp4`]**
> *Add short video demonstrating `MOD SELECT` switching between `OSC1 Pitch/Mod` and the 5 Performance Editor Knobs.*

---

## 1. Overview

This page brings together the Korg Z1's dual **Amplifier** stages (**Amp 1** and **Amp 2**), **Master Output / Panpot**, **OSC 1 Core Pitch, Slope & Pitch Modulation**, and the **Performance Editor (`PE Knobs 1..5`)**, where each physical Z1 Performance Knob can simultaneously modulate up to **4 target parameters** (`Target A`, `Target B`, `Target C`, `Target D`) with programmable polarity (`+`/`-`), curve (`Mode 0..3`), and intensity (`0..99`).

---

## 2. Control Layout

### Control Set 1 — Amp 1, Amp 2 & Stereo Output/Pan (Rows 1–2)

| Slot | Control ID | Parameter ID | Label | Type | Range / Values |
|:---:|:---:|:---:|---|---|---|
| **1** | `1` | `315` | `Amp1 Level` | Fader | `0..99` |
| **2** | `2` | `320` | `Amp1 ModEG` | List | `0..4` (`EG1`, `EG2`, `EG3`, `EG4`, `Amp EG`) |
| **3** | `3` | `322` | `Amp1 ModSrc` | List | `0..48` (`MODSRC1`) |
| **4** | `4` | `323` | `Amp1 ModInt` | Fader | `-99..+99` |
| **5** | `5` | `352` | `Out Pan` | Fader | `-50..+50` (`L50..C00..R50`) |
| **6** | `6` | `355` | `Out Level` | Fader | `0..99` |
| **7** | `7` | `324` | `Amp2 Level` | Fader | `0..99` |
| **8** | `8` | `329` | `Amp2 ModEG` | List | `0..4` (`EG1`, `EG2`, `EG3`, `EG4`, `Amp EG`) |
| **9** | `9` | `331` | `Amp2 ModSrc` | List | `0..48` (`MODSRC1`) |
| **10** | `10` | `332` | `Amp2 ModInt` | Fader | `-99..+99` |
| **11** | `11` | `353` | `Pan ModSrc` | List | `0..48` (`MODSRC1`) |
| **12** | `12` | `354` | `Pan ModInt` | Fader | `-99..+99` |

### Control Set 2 — Amp 1/2 Key Track & `MOD SELECT` (Rows 3–4)
- **Slots 13..16 (`Amp 1 Key Track`):** `Amp1 LoKey` (`316`), `Amp1 HiKey` (`317`), `Amp1 LoInt` (`318`), `Amp1 HiInt` (`319`).
- **Slots 19..22 (`Amp 2 Key Track`):** `Amp2 LoKey` (`325`), `Amp2 HiKey` (`326`), `Amp2 LoInt` (`327`), `Amp2 HiInt` (`328`).
- **Slot 18 (`MOD SELECT`):** Selects the active bank for Slots `17, 23..36`:
  - `0 = OSC1 Pitch/Mod` (`IDs 175..187`, 13 parameters)
  - `1 = PE Knob 1` (`IDs 384..399`, 16 parameters)
  - `2 = PE Knob 2` (`IDs 400..415`, 16 parameters)
  - `3 = PE Knob 3` (`IDs 416..431`, 16 parameters)
  - `4 = PE Knob 4` (`IDs 432..447`, 16 parameters)
  - `5 = PE Knob 5` (`IDs 448..463`, 16 parameters)

### Control Set 3 — Dynamic `OSC1 Pitch/Mod` or `PE Knob 1..5` (Slots `17, 23..36`)
- **When `MOD SELECT = OSC1 Pitch/Mod` (`0`):**
  Exposes `OSC1 Octave` (`175`), `Semitone` (`176`), `Fine` (`177`), `Offset` (`178`), `Center Key` (`179`), `Low Slope` (`180`), `High Slope` (`181`), `Mod1 Src/Int/Ctrl/CtrlInt` (`182..185`), and `Mod2 Src/Int` (`186..187`).
- **When `MOD SELECT = PE Knob 1..5` (`1..5`):**
  Exposes all 16 parameters for the selected Performance Editor Knob (`Target A..D` `0..230`, `Polar A..D` `+/-`, `Mode A..D` `0..3`, and `Int A..D` `0..99`).
