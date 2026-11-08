# Page 04 — Sub Oscillator, Noise Generator & OSC Common / Portamento

[⬅ Back to User Manual Index](../README.md)

- **Source Folder:** [`e1/z1-sub-noise/`](../../e1/z1-sub-noise/)
- **Files:** [`preset.json`](../../e1/z1-sub-noise/preset.json) | [`main.lua`](../../e1/z1-sub-noise/main.lua) | [`main-tests.lua`](../../e1/z1-sub-noise/main-tests.lua)
- **Z1 Parameters Covered:** All **33** parameters across `[SUB OSC]` (`IDs 202..215`), `[Noise Generator]` (`IDs 216..223`), and `[OSC Common]` (`IDs 163..173`), all with `ExID = 0`.

> 📸 **[Screenshot Placeholder: `../media/04-sub-noise.png`]**
> *Add screenshot of the Sub Oscillator, Noise Generator, and OSC Common / Portamento control sets.*
>
> 🎬 **[Video Placeholder: `../media/04-sub-noise.mp4`]**
> *Add short video demonstrating Sub OSC waveform selection, Noise Filter sweep, and Portamento settings.*

---

## 1. Overview

This page groups the Korg Z1's **Sub Oscillator** (with its own full pitch-slope and dual pitch-modulation section), the **Noise Generator** (which includes a dedicated multimode pre-filter with Cutoff, Resonance, and dual Cutoff modulation), and **OSC Common** (Pitch Bend range/step, Common Pitch Modulation, and Portamento).

---

## 2. Control Layout (35 Controls across 3 Control Sets)

### Control Set 1 — Sub Oscillator (`IDs 202..212, 215`)

| Slot | Control ID | Parameter ID | Label | Type | Range / Values |
|:---:|:---:|:---:|---|---|---|
| **1** | `1` | `215` | `Sub Wave` | List | `0..3` (`Saw`, `Square`, `Triangle`, `Sine`) |
| **2** | `2` | `202` | `Sub Octave` | List | `-2..+1` (`16'`, `8'`, `4'`, `2'`) |
| **3** | `3` | `203` | `Sub Semi` | Fader | `-12..+12` semitones |
| **4** | `4` | `204` | `Sub Fine` | Fader | `-50..+50` cents |
| **5** | `5` | `205` | `Sub Offset` | Fader | `-99..+99` |
| **6** | `6` | `206` | `Sub CtrKey` | Fader | `0..127` (`C-1..G9` MIDI note formatter) |
| **7** | `7` | `207` | `Sub LoSlp` | Fader | `-50..+100` (`-1.0..+2.0`) |
| **8** | `8` | `208` | `Sub HiSlp` | Fader | `-50..+100` (`-1.0..+2.0`) |
| **9** | `9` | `209` | `Sub Mod1Src` | List | `0..48` (`MODSRC1`) |
| **10** | `10` | `210` | `Sub Mod1Int` | Fader | `-99..+99` |
| **11** | `11` | `211` | `Sub M1Ctrl` | List | `0..48` (`MODSRC1`) |
| **12** | `12` | `212` | `Sub M1CInt` | Fader | `-99..+99` |

### Control Set 2 — Sub OSC Mod 2 & Noise Generator (`IDs 213..214, 216..223`)

| Slot | Control ID | Parameter ID | Label | Type | Range / Values |
|:---:|:---:|:---:|---|---|---|
| **13** | `13` | `213` | `Sub Mod2Src` | List | `0..48` (`MODSRC1`) |
| **14** | `14` | `214` | `Sub Mod2Int` | Fader | `-99..+99` |
| **15** | `15` | `216` | `Noise Flt` | List | `0..3` (`LPF`, `HPF`, `BPF`, `THRU`) |
| **16** | `16` | `217` | `Noise Trim` | Fader | `0..99` |
| **17** | `17` | `218` | `Noise Cut` | Fader | `0..99` |
| **18** | `18` | `223` | `Noise Reso` | Fader | `0..99` |
| **19** | `19` | `219` | `Ns CutSrc1` | List | `0..48` (`MODSRC1`) |
| **20** | `20` | `220` | `Ns CutInt1` | Fader | `-99..+99` |
| **21** | `21` | `221` | `Ns CutSrc2` | List | `0..48` (`MODSRC1`) |
| **22** | `22` | `222` | `Ns CutInt2` | Fader | `-99..+99` |

### Control Set 3 — OSC Common & Portamento (`IDs 163..173`)

| Slot | Control ID | Parameter ID | Label | Type | Range / Values |
|:---:|:---:|:---:|---|---|---|
| **25** | `25` | `163` | `PBend Int+` | Fader | `-24..+24` semitones |
| **26** | `26` | `164` | `PBend Int-` | Fader | `-24..+24` semitones |
| **27** | `27` | `165` | `PBend Stp+` | Fader | `0..12` (`0 = Continuous`, `1..12` semitone steps) |
| **28** | `28` | `166` | `PBend Stp-` | Fader | `0..12` |
| **29** | `29` | `167` | `CmnMod Src` | List | `0..48` (`MODSRC1`) |
| **30** | `30` | `168` | `CmnMod Int` | Fader | `-99..+99` |
| **31** | `31` | `169` | `Porta SW` | Toggle Pad | `0..1` (`OFF` / `ON`) |
| **32** | `32` | `170` | `Porta Mode` | List | `0..1` (`Normal`, `Fingered`) |
| **33** | `33` | `171` | `Porta Time` | Fader | `0..99` |
| **34** | `34` | `172` | `Porta Src` | List | `0..48` (`MODSRC1`) |
| **35** | `35` | `173` | `Porta Int` | Fader | `-99..+99` |
