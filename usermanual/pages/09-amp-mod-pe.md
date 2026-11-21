# Page 9: Dual Amplifiers, Stereo Pan & Performance Knobs (`Amp & Mod`)

The **Amp & Mod** page combines two key expressive stages of the Korg Z1:
1. **Top Half (Rows 1–2)**: The dual voice amplifiers (**Amp 1** and **Amp 2**), including output volume, tremolo/level modulation, built-in analog-style **Distortion**, and stereo **Panning**.
2. **Bottom Half (Rows 3–6)**: A switchable modulation hub controlled by **MOD SELECT**, giving you complete access to **OSC 1 Pitch & Pan Modulation** and all five front-panel **Performance Editor Knobs (`PE Knob 1` – `PE Knob 5`)**.

> [!TIP]
> **Thin Faders for Modulation Depth:** All modulation intensity (`Int`) sliders across both the Amplifier section and the Performance Editor section use **thin horizontal faders** so you can visually distinguish modulation depths at a glance.

---

## Screen Layout Overview

```
+-------------------------------------------------+-------------------------------------------------+
|                AMP 1 (Cols 1-3)                 |                AMP 2 (Cols 4-6)                 |
+-------------------------------------------------+-------------------------------------------------+
| [ Amp1 Level ] [Amp1 ModSrc ] [Amp1 ModInt ]    | [ Amp2 Level ] [Amp2 ModSrc ] [Amp2 ModInt ]    |
| [Amp1 LFO1Int] [Amp1 Distort] [  Amp1 Pan  ]    | [Amp2 LFO1Int] [Amp2 Distort] [  Amp2 Pan  ]    |
+-------------------------------------------------+-------------------------------------------------+
|  ROW 3: LOWER SECTION MODE SELECTOR                                                               |
|  [  MOD SELECT  ]  (Switches Rows 4-6 between "OSC1 & Pan Mod" and "PE Knob 1" .. "PE Knob 5")    |
+---------------------------------------------------------------------------------------------------+
|  ROWS 4-6: DYNAMIC MODULATION OR PERFORMANCE KNOB ASSIGNMENTS                                     |
|  (Displays either OSC1 Pitch / Amp Pan Modulation OR the 4 target assignments of PE Knob 1..5)    |
+---------------------------------------------------------------------------------------------------+
```

---

## 1. Dual Amplifiers, Distortion & Stereo Pan (Rows 1–2)

Filter 1 feeds directly into **Amp 1** (Columns 1–3) and Filter 2 feeds directly into **Amp 2** (Columns 4–6). Each amplifier has its own set of controls:

| Control | Range / Options | Musical Function |
| :--- | :--- | :--- |
| **Amp1 / Amp2 Level** | `0` – `99` | Sets the overall volume of the Filter 1 / Amp 1 path and Filter 2 / Amp 2 path. |
| **ModSrc & ModInt** | Mod Source / `-99` to `+99` | Modulates amplifier volume from any controller or envelope. |
| **LFO1 Int** | `-99` to `+99` | Direct **LFO 1** tremolo depth on that amplifier. *(Tip: Set `Amp1 LFO1Int` to `+50` and `Amp2 LFO1Int` to `-50` with the two amps panned Left and Right for stereo auto-panning!)* |
| **Distort** | `OFF` / `ON` | Engages per-voice waveshaping distortion on that amplifier path for gritty leads, overdriven organs, and aggressive acid basses. |
| **Pan** | `L99` .. `Center` .. `R99` | Positions Amp 1 and Amp 2 independently across the stereo field before the signal enters the 2-Band EQ and Effects. |

---

## 2. Using `MOD SELECT` (Row 3)

Turn **MOD SELECT** in Row 3 to switch the lower half of the page (Rows 4–6) between six views:
1. **`OSC1 & Pan Mod`** *(Default)*
2. **`PE Knob 1`**
3. **`PE Knob 2`**
4. **`PE Knob 3`**
5. **`PE Knob 4`**
6. **`PE Knob 5`**

---

## 3. Mode A: `OSC1 & Pan Mod` View

When **MOD SELECT** is set to `OSC1 & Pan Mod`, Rows 4–6 provide direct hands-on control over:
- **Amp 1 & Amp 2 Dynamic Stereo Pan Modulation**:
  - **Amp1 PanModSrc & Amp1 PanModInt (`-99` to `+99`)**: Moves Amplifier 1 across the stereo field using an LFO, envelope, note number, or velocity.
  - **Amp2 PanModSrc & Amp2 PanModInt (`-99` to `+99`)**: Moves Amplifier 2 independently across the stereo field.
- **Additional Pitch & Voice Modulation Controls**: Quick access to oscillator pitch envelope and LFO modulation depths right alongside your amplifier and pan controls.

---

## 4. Mode B: `PE Knob 1` – `PE Knob 5` Views

The Korg Z1 has five physical **Performance Editor (`PE`) Knobs** on its front panel. Each physical knob can simultaneously control up to **4 different synthesis parameters** at once with independent positive or negative intensities!

When you select **`PE Knob 1`** through **`PE Knob 5`** with **MOD SELECT**, Rows 4–6 display the complete assignment matrix for that knob:

- **Knob Mode**: Configures the response curve and grouping behavior of the selected Performance Knob.
- **Target 1 – Target 4 Parameter Selectors**: Choose up to 4 destination parameters inside the patch for that knob to control (such as Filter Cutoff, Resonance, OSC Edge, LFO Speed, Envelope Release, or Effect Balance).
- **Target 1 – Target 4 Intensity Faders *(Thin Faders)* (`-99` to `+99`)**: Set how far and in which direction (`+` or `-`) each of the 4 assigned parameters moves when you turn that Performance Knob.
