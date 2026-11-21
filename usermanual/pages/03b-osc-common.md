# Page 3: OSC Common & Oscillator Preset Library (`OSC common`)

The **OSC Common** page puts the pitch, fine-tuning, pitch key-tracking slope, and pitch modulation routing for **Oscillator 1** and **Oscillator 2** side by side on a single screen. It also hosts quick navigation links to the individual oscillator pages and the on-board **OSC Preset Library**.

> [!TIP]
> **Thin Modulation Faders:** Every pitch modulation depth control (`Pitch EG Int`, `Mod1 Int`, `Mod2 Int`, `LFO1 Int`, and `LFO1 Mod Int`) is rendered as a **thin horizontal fader**, visually separating modulation intensities from core pitch and tuning sliders.

---

## Screen Layout Overview

Columns 1–2 control **OSC 1**, Columns 3–4 control **OSC 2**, and Columns 5–6 provide quick page navigation, active synthesis model readouts, and the **OSC Presets** toggle button.

```
+------------------------------------+------------------------------------+------------------------------------+
|           OSC 1 (Cols 1-2)         |           OSC 2 (Cols 3-4)         |      NAVIGATION & PRESETS (5-6)    |
+------------------------------------+------------------------------------+------------------------------------+
| [OSC1 SemiPitch] [  OSC1 Tune   ]  | [OSC2 SemiPitch] [  OSC2 Tune   ]  | [ Jump OSC 1  ] [ Jump OSC 2  ]    |
| [OSC1 PitchSlpe] [OSC1 PitchEGIn]  | [OSC2 PitchSlpe] [OSC2 PitchEGIn]  | [ OSC1 Model  ] [ OSC2 Model  ]    |
| [OSC1 PchEGModS] [OSC1 PchEGModI]  | [OSC2 PchEGModS] [OSC2 PchEGModI]  |                 [ OSC Presets ]    |
| [OSC1 PchMod2Sr] [OSC1 PchMod2In]  | [OSC2 PchMod2Sr] [OSC2 PchMod2In]  |                                    |
| [OSC1 PchLFO1In] [OSC1 PchLFO1MS]  | [OSC2 PchLFO1In] [OSC2 PchLFO1MS]  |   (Rows 5-6 morph into the         |
| [OSC1 PchLFO1MI]                   | [OSC2 PchLFO1MI]                   |    OSC Preset Library when         |
|                                    |                                    |    "OSC Presets" is turned ON)     |
+------------------------------------+------------------------------------+------------------------------------+
```

---

## 1. Pitch & Pitch Modulation Controls (OSC 1 & OSC 2)

Each oscillator has an identical 2-column control strip:

| Row | Left Control | Right Control | Musical Function |
| :-: | :--- | :--- | :--- |
| **1** | **SemiPitch (`-48` to `+48`)** | **Tune (`-50` to `+50` cents)** | Coarse transposition in semitones (`±4 octaves`) and fine detuning in cents. |
| **2** | **PitchSlope (`-100%` to `+200%`)** | **PitchEG Int (`-48` to `+48`)** | Keyboard pitch scaling (`100%` = normal chromatic scale, `0%` = fixed pitch across all keys) and dedicated Pitch Envelope (`EG 1`) depth. |
| **3** | **PchEG ModSrc** | **PchEG ModInt (`-48` to `+48`)** | Assigns a controller (such as Velocity or a Performance Knob) to scale the depth of the Pitch Envelope. |
| **4** | **PchMod2 Src** | **PchMod2 Int (`-48` to `+48`)** | Direct pitch modulation from any Z1 modulation source (LFOs, envelopes, aftertouch, wheel, key track). |
| **5** | **PchLFO1 Int (`-48` to `+48`)** | **PchLFO1 ModSrc** | Base vibrato depth from **LFO 1** and a secondary controller source (such as Joystick `+Y` or Aftertouch) to bring in extra vibrato. |
| **6** | **PchLFO1 ModInt (`-48` to `+48`)** | — | Maximum additional LFO 1 vibrato depth added by the `PchLFO1 ModSrc` controller. |

---

## 2. Navigation & Model Displays (Columns 5–6)

- **Jump OSC 1**: Switches immediately to [Page 4: Oscillator 1](file:///home/timbos/src/Z1/usermanual/pages/02-osc1.md).
- **Jump OSC 2**: Switches immediately to [Page 5: Oscillator 2](file:///home/timbos/src/Z1/usermanual/pages/03-osc2.md).
- **OSC1 Model / OSC2 Model**: Read-only status boxes showing which synthesis algorithms are currently active on OSC 1 and OSC 2 (for example, `VPM` and `Reed Model`).
- **OSC Presets**: Toggles the **OSC Preset Library** drawer open or closed across Rows 5–6.

---

## 3. The OSC Preset Library (`OSC Presets` Drawer)

When you tap **OSC Presets** (Row 3, Column 6), Rows 5 and 6 transform into the **OSC Preset Library**, allowing you to save, rename, load, and delete single-oscillator or dual-oscillator presets directly on the Electra One.

```
+---------------------------------------------------------------------------------------------------+
|  ROW 5 (WHEN "OSC PRESETS" IS ON):                                                                |
|  [ Preset List (Cols 1-2, Rows 5-6) ] [   Target    ] [  Name Pos   ] [    Save     ] [    Load     ] |
+---------------------------------------------------------------------------------------------------+
|  ROW 6 (WHEN "OSC PRESETS" IS ON):                                                                |
|  [  (Black text on teal highlight)  ] [             ] [  Name Char  ] [   Rename    ] [   Delete    ] |
+---------------------------------------------------------------------------------------------------+
```

### Selecting the Preset Target (`Target` Control)

The **Target** knob in Column 3 chooses between three library modes:

1. **`OSC 1` (8 Slots per OSC 1 Model)**:
   - Displays **8 preset slots specifically for the currently active OSC 1 synthesis model** (e.g., 8 presets for `VPM`, 8 presets for `Brass Model`, 8 presets for `Plucked String`).
   - Saving stores all parameters of the [OSC 1](file:///home/timbos/src/Z1/usermanual/pages/02-osc1.md) page. Loading applies those parameters to OSC 1 and transmits them to the Z1.
2. **`OSC 2` (8 Slots per OSC 2 Model — Shared with OSC 1)**:
   - Displays **8 preset slots for the currently active OSC 2 synthesis model**.
   - **Shared Model Pool**: For the 9 synthesis models available on both oscillators (`Standard`, `Comb Filter`, `VPM`, `Resonance`, `Ring Mod`, `Cross Mod`, `Sync`, `Organ Model`, and `Reed Model`), OSC 1 and OSC 2 share the exact same 8-slot model pool. A great `VPM` or `Organ Model` preset saved from OSC 1 can be loaded straight into OSC 2!
3. **`Both OSCs` (25 Dual-Oscillator Slots)**:
   - Displays **25 universal dual-oscillator slots (`01`–`25`)** regardless of which oscillator models are currently active.
   - Each slot stores a complete dual-oscillator setup: **both OSC 1 and OSC 2 synthesis model selections**, **all OSC 1 parameters**, **all OSC 2 parameters**, and **all OSC Common tuning and pitch modulation settings**.
   - For example, a single `Both OSCs` preset can load **two VPM oscillators** together with their detuning and pitch envelopes, or a **Plucked String + Comb Filter** acoustic body layer, in one tap.

### Managing Presets
- **Preset List (Columns 1–2)**: Turn the encoder or drag across the list to select a slot. The active slot is highlighted with a **teal bar and dark black text** for crisp legibility. In `Both OSCs` mode, occupied slots also display a compact tag showing which models are stored inside.
- **Name Pos (`1`–`12`) & Name Char**: Position the cursor and dial in a custom 12-character preset name.
- **Save**: Saves the current oscillator settings (and your custom name) into the selected slot.
- **Rename**: Updates only the name of an existing preset without changing its stored sound parameters.
- **Load**: Recalls the selected preset onto the Electra One and transmits every parameter smoothly to the Korg Z1.
- **Delete**: Clears the selected preset slot back to `(Empty)`.
