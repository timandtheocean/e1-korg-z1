# Page 12: Effects, 2-Band EQ & FX Preset Library (`FX & EQ`)

At the end of the Korg Z1 voice signal chain, the stereo output passes through a dedicated **2-Band Master EQ**, a versatile **Modulation / Delay / Multi-Effect Processor (`FX 1`)**, and a **Master Reverb / Delay / Spatial Processor (`FX 2`)**.

The **FX & EQ** page dynamically reconfigures its controls to match whichever effect algorithms are active on **FX 1** and **FX 2**, and includes a built-in **FX Preset Library** that stores both individual algorithm presets and complete **FX Chain** setups.

---

## Screen Layout Overview

```
+---------------------------------------------------------------------------------------------------+
|  ROW 1: EFFECT SWITCHES, ALGORITHM SELECTORS, ACTIVE EDITOR TAB & PRESET DRAWER TOGGLE            |
|  [  FX1 Switch ] [ FX1 Select  ] [  FX2 Switch ] [ FX2 Select* ] [   EDIT FX   ] [ FX PRESETS  ]  |
+---------------------------------------------------------------------------------------------------+
|  ROWS 2-4: DYNAMIC PARAMETERS FOR THE CURRENTLY SELECTED "EDIT FX" SECTION                        |
|  - When EDIT FX = "FX 1": Displays up to 13 tailored controls for the active FX1 algorithm        |
|  - When EDIT FX = "FX 2": Displays up to 9 tailored controls for the active FX2 algorithm         |
|  - When EDIT FX = "Master / EQ": Displays FX Send Routing & 2-Band Master Equalizer               |
+---------------------------------------------------------------------------------------------------+
|  ROWS 5-6: FX PRESET LIBRARY (Visible when "FX PRESETS" is turned ON)                             |
|  [ Preset List (Cols 1-2, Rows 5-6) ] [   Target    ] [  Name Pos   ] [    Save     ] [    Load     ] |
|  [  (Black text on teal highlight)  ] [             ] [  Name Char  ] [   Rename    ] [   Delete    ] |
+---------------------------------------------------------------------------------------------------+
```
*(\*`FX2 Select` automatically hides whenever an FX1-only double-size algorithm is active.)*

---

## 1. Selecting & Switching Effects (Row 1)

- **FX1 Switch (`OFF` / `ON`)**: Bypasses or engages Effect Processor 1.
- **FX1 Select**: Chooses one of the **15 FX 1 algorithms**:
  - *Standard Algorithms (1–11)*: `Overdrive`, `Compressor`, `Parametric EQ`, `Chorus`, `Flanger`, `Phaser`, `Tremolo`, `Auto Pan`, `Stereo Delay`, `L/C/R Delay`, `Auto Wah`.
  - *Double-Size FX1-Only Algorithms (12–15)*: `Talking Modulator`, `Multitap Delay`, `Ensemble`, `Rotary Speaker`.
- **Automatic FX 2 Hiding for Double-Size Algorithms**: On the Korg Z1 hardware, algorithms 12–15 (`Talking Modulator`, `Multitap Delay`, `Ensemble`, and `Rotary Speaker`) use the full DSP power of both effect blocks and disable FX 2. Whenever you select one of these four algorithms on **FX 1**, the Electra One **automatically hides `FX2 Select`** (and if you were viewing FX 2, switches your view back to FX 1) so you never edit inactive controls.
- **FX2 Switch (`OFF` / `ON`) & FX2 Select**: Bypasses or engages Effect Processor 2 and chooses from **11 FX 2 algorithms** (`Overdrive` through `Auto Wah`, plus the Z1's lush `Hall Reverb`, `Room Reverb`, and `Stage Reverb` algorithms).

---

## 2. Switching Between `FX 1`, `FX 2` & `Master / EQ` (`EDIT FX`)

Use the **EDIT FX** control (Row 1, Column 5) to choose which section fills the center of the screen (Rows 2–4):

1. **`FX 1`**: Dynamically labels and ranges Rows 2–4 for the currently selected **FX 1** algorithm (for example, showing Vowel combinations and Formant Modulation for `Talking Modulator`, Horn/Rotor speeds for `Rotary Speaker`, or Tap delays and feedback for `Stereo Delay`), including wet/dry **FX1 Balance** and real-time **FX1 Mod Source & Int** (rendered with thin faders for modulation depths).
2. **`FX 2`**: Dynamically reconfigures Rows 2–4 for the active **FX 2** algorithm (for example, Reverb Time, High Damp, Pre-Delay, ER Level, and wet/dry Balance).
3. **`Master / EQ`**: Displays the global post-amp routing and master tone shaping controls:
   - **FX Send**: Routes how the dry/wet voice output feeds into the effect chain.
   - **2-Band Master EQ**: Adjusts **Low EQ Frequency**, **Low EQ Gain (`-18` to `+18 dB`)**, **High EQ Frequency**, and **High EQ Gain (`-18` to `+18 dB`)** to sculpt the final warmth and air of the patch.

---

## 3. The FX Preset Library (`FX PRESETS` Drawer)

Tap the **FX PRESETS** button in the top-right corner (Row 1, Column 6) to open or close the **FX Preset Library** across Rows 5 and 6.

### Selecting the Preset Target (`Target` Control)

The **Target** selector in Column 3 offers three powerful storage modes:

1. **`FX 1` (8 Slots per FX Algorithm)**:
   - Displays **8 preset slots specifically for the currently active FX 1 algorithm** (e.g., 8 presets for `Chorus`, 8 presets for `Rotary Speaker`, 8 presets for `Stereo Delay`).
2. **`FX 2` (8 Slots per FX Algorithm — Shared with FX 1)**:
   - Displays **8 preset slots for the currently active FX 2 algorithm**.
   - **Shared Algorithm Pool**: For all 11 algorithms available on both FX 1 and FX 2, the two units share the same 8-slot per-algorithm pool—so a favorite `Chorus`, `Phaser`, or `Stereo Delay` preset saved on FX 1 can be loaded directly onto FX 2!
3. **`FX Chain` (25 Full-Chain Slots)**:
   - Displays **25 complete Effect Chain slots (`01`–`25`)**.
   - Saving an `FX Chain` preset captures **both FX 1 and FX 2 algorithm selections**, **their ON/OFF switches**, **all FX 1 parameters**, **all FX 2 parameters**, **Master FX Send**, and **all 2-Band EQ settings** together in a single slot.
   - Loading an `FX Chain` preset instantly drops your entire signature production chain (EQ + Modulation/Delay + Reverb) onto any patch you are editing.

### Managing FX Presets
- **Preset List (Columns 1–2)**: Scroll through the available slots. The active slot is highlighted with a **teal selection bar and black text** for effortless reading.
- **Name Pos (`1`–`12`) & Name Char**: Select a character position and dial in a custom name for your effect preset.
- **Save / Rename / Load / Delete**: Save new settings into the selected slot, rename an existing preset, load it directly to the Korg Z1, or clear the slot back to `(Empty)`.
