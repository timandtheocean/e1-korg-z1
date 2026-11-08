# Page 08 — Quad LFOs (LFO 1–4) with Live Custom Waveform Visualizers

[⬅ Back to User Manual Index](../README.md)

- **Source Folder:** [`e1/z1-lfo/`](../../e1/z1-lfo/)
- **Files:** [`preset.json`](../../e1/z1-lfo/preset.json) | [`main.lua`](../../e1/z1-lfo/main.lua) | [`main-tests.lua`](../../e1/z1-lfo/main-tests.lua)
- **Z1 Parameters Covered:** All **44** `[LFO1]`–`[LFO4]` parameters (`IDs 119..162`, `ExID = 0`) + 4 live custom Lua **LFO Waveform Graph** widgets (`Controls 2, 5, 14, 17`).

> 📸 **[Screenshot Placeholder: `../media/08-lfos.png`]**
> *Add screenshot of the 4 LFO custom waveform displays rendering different wave shapes, offsets, and fade-in ramps.*
>
> 🎬 **[Video Placeholder: `../media/08-lfos.mp4`]**
> *Add short video demonstrating live waveform redrawing as `Wave`, `Offset`, and `FadeIn` are adjusted.*

---

## 1. Overview

The Korg Z1 includes four LFOs (**LFO 1**–**LFO 4**), each offering **18 waveform shapes** (`Triangle` through `StepTri4/6`), `Frequency`, `Offset` (`-99..+99`), `Fade-In` (`0..99`), `Key Sync` (`OFF`, `Timbre`, `Voice`), `MIDI Tempo Sync` (`Sync SW`, `Base Note`, `Times`), dual Frequency Modulation (`LFO1/2`) or single Frequency Modulation (`LFO3/4`), and Amplitude Modulation (`LFO1/2`).

Each LFO features a custom Lua **Waveform Visualizer Widget** (`paintLfo1..paintLfo4` in [`main.lua`](../../e1/z1-lfo/main.lua)) inspired by `roomi-fields/electraone-widgets` that mathematically synthesizes and draws:
1. All **18 Korg Z1 LFO wave shapes** (`Triangle`, `Saw Up`, `Saw Down`, `Square1`, `Sine`, `Guitar`, `ExpTri`, `ExpSawUp`, `ExpSawDown`, `Square2`, `Octave`, `Fifth`, `3rd`, `RandomVector`, `Sample&Hold`, `RandomGate`, `StepTri4`, `StepTri6`).
2. Vertical **Offset** shift (`-99..+99`) relative to the dashed zero-crossing baseline.
3. Progressive **Fade-In** envelope attenuation (`0..99`) across the left portion of the cycle, plus a header badge showing `SYNC` or `KS` when active.

---

## 2. Control Layout (34 Controls across 3 Control Sets)

### Control Set 1 — LFO 1 & LFO 2 Core + Waveform Visualizers (Rows 1–2)
- **LFO 1 (Left 3 Columns, Slots `1..3` & `7..9`):**
  - `[1]` `LFO1 Wave` (`ID 119`, `0..17`), `[2]` **`LFO1 Shape`** *(Custom Graph)*, `[3]` `LFO1 Freq` (`ID 120`, `0..99`)
  - `[7]` `LFO1 KeySync` (`ID 123`, `OFF/Timbre/Voice`), `[8]` `LFO1 FadeIn` (`ID 122`, `0..99`), `[9]` `LFO1 Offset` (`ID 121`, `-99..+99`)
- **LFO 2 (Right 3 Columns, Slots `4..6` & `10..12`):**
  - `[4]` `LFO2 Wave` (`ID 132`, `0..17`), `[5]` **`LFO2 Shape`** *(Custom Graph)*, `[6]` `LFO2 Freq` (`ID 133`, `0..99`)
  - `[10]` `LFO2 KeySync` (`ID 136`, `OFF/Timbre/Voice`), `[11]` `LFO2 FadeIn` (`ID 135`, `0..99`), `[12]` `LFO2 Offset` (`ID 134`, `-99..+99`)

### Control Set 2 — LFO 3 & LFO 4 Core + Waveform Visualizers (Rows 3–4)
- **LFO 3 (Left 3 Columns, Slots `13..15` & `19..21`):**
  - `[13]` `LFO3 Wave` (`ID 145`, `0..17`), `[14]` **`LFO3 Shape`** *(Custom Graph)*, `[15]` `LFO3 Freq` (`ID 146`, `0..99`)
  - `[19]` `LFO3 KeySync` (`ID 149`, `OFF/Timbre/Voice`), `[20]` `LFO3 FadeIn` (`ID 148`, `0..99`), `[21]` `LFO3 Offset` (`ID 147`, `-99..+99`)
- **LFO 4 (Right 3 Columns, Slots `16..18` & `22..24`):**
  - `[16]` `LFO4 Wave` (`ID 154`, `0..17`), `[17]` **`LFO4 Shape`** *(Custom Graph)*, `[18]` `LFO4 Freq` (`ID 155`, `0..99`)
  - `[22]` `LFO4 KeySync` (`ID 158`, `OFF/Timbre/Voice`), `[23]` `LFO4 FadeIn` (`ID 157`, `0..99`), `[24]` `LFO4 Offset` (`ID 156`, `-99..+99`)

### Control Set 3 — LFO Selector, MIDI Tempo Sync & Modulation (Rows 5–6)
- **Slot 25 (`LFO SELECT`):** Selects `LFO 1`, `LFO 2`, `LFO 3`, or `LFO 4` for the shared sync/modulation section.
- **Slots 26..28 (MIDI Sync):** `MIDI Sync` (`OFF/ON`), `Sync Base` (`r/32`..`r1`), `Sync Time` (`1..16`).
- **Slots 29..34 (Modulation):** `Freq Mod1 Src/Int` (all 4 LFOs), `Freq Mod2 Src/Int` & `Amp Mod Src/Int` (automatically shown for `LFO 1` and `LFO 2`, hidden for `LFO 3` and `LFO 4` which only have `Freq Mod1` in hardware).
