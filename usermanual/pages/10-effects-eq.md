# Page 10 — Effects (FX1, FX2, Master FX), 2-Band EQ & Persistent FX Preset Manager

[⬅ Back to User Manual Index](../README.md)

- **Source Folder:** [`e1/z1-fx/`](../../e1/z1-fx/)
- **Files:** [`preset.json`](../../e1/z1-fx/preset.json) | [`main.lua`](../../e1/z1-fx/main.lua) | [`main-tests.lua`](../../e1/z1-fx/main-tests.lua)
- **Z1 Parameters Covered:**
  - `IDs 356..361` (`ExID = 0`): Effect Send, Send Mod Source/Int, `FX1 Select` (`0..14`), `FX2 Select` (`0..10`), `Master FX Select` (`0..2`)
  - `IDs 362..365` (`ExID = 0`): 2-Band Equalizer (`Low Freq`, `Low Gain`, `High Freq`, `High Gain`)
  - `IDs 800..1003` (`ExID = 3`): All **204** active `Effect 1` parameters across **15 algorithms** (`id14 = 6144 + ID`)
  - `IDs 800..951` (`ExID = 4`): All **152** active `Effect 2` parameters across **11 algorithms** (`id14 = 8192 + ID`)
  - `IDs 1004..1039` (`ExID = 5`): All **36** active `Master Effect` parameters across **3 algorithms** (`id14 = 10240 + ID`)

> 📸 **[Screenshot Placeholder: `../media/10-effects-eq.png`]**
> *Add screenshots showing FX1 (`TalkingModulator` or `Amp Sim/Phaser`), FX2, and Master FX (`Stereo Delay` / `Reverb`) views.*
>
> 🎬 **[Video Placeholder: `../media/10-effects-eq.mp4`]**
> *Add short video demonstrating `EDIT FX` unit switching, algorithm selection, and `FX PRESET` Save/Recall.*

---

## 1. Overview

The Korg Z1's effects processor consists of a **2-Band Pre-EQ**, two modulation/insert multi-effects (**Effect 1** with 15 algorithms and **Effect 2** with 11 algorithms), and a spatial **Master Effect** (3 algorithms: `OverDrive/HiGainWah`, `Stereo Delay`, and `Reverb`).

Key features of this page:
1. **Top-Level Chain & EQ Always Visible (Control Set 1, Rows 1–2):**
   - Select algorithms for `FX1`, `FX2`, and `Master FX`, adjust `FX Send` + modulation, and shape the `2-Band EQ`.
2. **`EDIT FX` Selector (`Control 11: FX1 (Mod) / FX2 (Mod) / Master FX`):**
   - Dynamically morphs the 20 slots in Control Sets 2 & 3 (`Faders 101..120` / `Lists 201..220`) to display the parameters of the selected FX unit and its active algorithm (`ExID = 3`, `4`, or `5`).
3. **Non-Contiguous `MODSRC2` Support:**
   - Correctly maps effect dynamic modulation sources that use Korg's non-contiguous **Modulation Source List 2** (`0 = Off`, `11..45 = Note[Linear]..Tempo`) via `overlay:getValueByIndex()`.
4. **Persistent FX Preset Manager (`Control 12`, `FX PRESET`):**
   - Allows saving and recalling **3 Per-Unit FX Presets** (`Save Unit 1..3` / `Load Unit 1..3`) and **2 Full FX-Chain Presets** (`Save Chain 1..2` / `Load Chain 1..2`), persisted across reboots via Electra One's `persist()` / `recall()` storage API.

---

## 2. Supported Effect Algorithms

| Unit | `ExID` | `Select` ID | Algorithms |
|---|:---:|:---:|---|
| **Effect 1 (`FX1`)** | `3` | `359` (`0..14`) | `0: Off`, `1: St.Comp/Limiter`, `2: Wah`, `3: TalkingModulator`, `4: St.Decimator`, `5: 4Band EQ`, `6: Amp Simulation`, `7: St.Chorus`, `8:HarmonicChorus`, `9: St.Ensemble`, `10: St.Flanger`, `11: St.Phaser`, `12: SmallPhaser`, `13: AutoPan/Tremolo`, `14: RotarySpeaker` |
| **Effect 2 (`FX2`)** | `4` | `360` (`0..10`) | `0: Off`, `1: St.Comp/Limiter`, `2: Wah`, `3: St.Decimator`, `4: 4Band EQ`, `5: St.Chorus`, `6: St.Flanger`, `7: St.Phaser`, `8: SmallPhaser`, `9: AutoPan/Tremolo`, `10: RotarySpeaker` |
| **Master FX (`MFX`)** | `5` | `361` (`0..2`) | `0: OverDrive/HiGainWah`, `1: Stereo Delay`, `2: Reverb` |
