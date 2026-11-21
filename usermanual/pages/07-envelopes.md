# Page 10: Five Interactive Envelopes (`Envelopes`)

The Korg Z1 provides **five multi-stage envelope generators** per voice:
- **EG 1 (Pitch / General EG)**
- **EG 2 (Filter 1 / General EG)**
- **EG 3 (Filter 2 / General EG)**
- **EG 4 (Auxiliary / General EG)**
- **Amp EG (Amplifier Volume Envelope — `Amp 1` & `Amp 2`)**

Unlike a standard 4-stage ADSR envelope, every Z1 envelope is an **8-parameter multi-stage contour** with bipolar levels (`-99` to `+99` on EGs 1–4, `0` to `99` on Amp EG), allowing complex double-decays, delayed rises, pitch blips, and evolving loops.

The **Envelopes** page displays all five envelopes at once as **interactive touch-editable graphs**, plus an expandable **Reveal Modulations** drawer for deep velocity and key-tracking dynamics.

---

## Screen Layout Overview (Default Graphical View)

```
+-------------------------------------------------+-------------------------------------------------+
|  ROW 1: EG 1 (Pitch / General)                  |  ROW 1: EG 2 (Filter 1 / General)               |
|  [  Interactive EG 1 Graph (2 Cols)  ] [Start1] |  [  Interactive EG 2 Graph (2 Cols)  ] [Start2] |
+-------------------------------------------------+-------------------------------------------------+
|  ROW 2: EG 3 (Filter 2 / General)               |  ROW 2: EG 4 (Auxiliary / General)              |
|  [  Interactive EG 3 Graph (2 Cols)  ] [Start3] |  [  Interactive EG 4 Graph (2 Cols)  ] [Start4] |
+-------------------------------------------------+-------------------------------------------------+
|  ROW 3: AMP EG & ENVELOPE MODULATION DRAWER CONTROLS                                              |
|  [ Interactive Amp EG Graph (2 Cols) ] [AmpSel] [   EG SELECT   ] [Reveal Modulatn]               |
+---------------------------------------------------------------------------------------------------+
```

---

## 1. Editing the 5 Interactive Envelope Graphs

Each of the five envelope widgets draws the complete multi-stage contour in real time:
1. **Start Level** *(Dedicated vertical fader immediately to the right of each graph)*: Sets the initial level where the envelope begins at note-on (`-99` to `+99`).
2. **Attack Time & Attack Level**: How fast the envelope rises (or falls) from the Start Level and the peak level it reaches.
3. **Decay Time & Break Point Level**: How fast the envelope moves from the Attack peak to the intermediate **Break Point** level.
4. **Slope Time & Sustain Level**: How fast the envelope travels from the Break Point to the held **Sustain Level** while a key remains pressed.
5. **Release Time & Release Level**: How fast the envelope finishes after you release the key, and the final target level it lands on (`-99` to `+99`).

### Touch & Knob Editing
- **Tap & Drag on Any Graph**: Touch any envelope graph on the screen to focus it and drag its stage handles directly, or use the hardware encoders beneath the active envelope to dial in exact stage times and levels.
- **Amp EG Selector (`Amp 1` / `Amp 2`)**: Selects whether the bottom-left **Amp EG** graph edits Amplifier 1's volume envelope or Amplifier 2's volume envelope.

---

## 2. The Envelope Modulation Drawer (`Reveal Modulations`)

Every Z1 envelope also has extensive expressive modulation parameters that scale its levels and stage times by keyboard velocity, key tracking, or external controllers.

1. Use **EG SELECT** (`EG 1`, `EG 2`, `EG 3`, `EG 4`, `Amp 1 EG`, or `Amp 2 EG`) to choose which envelope's dynamic modulations you want to inspect or edit.
2. Tap **Reveal Modulations** (Row 3, Column 5) to open the 3-row **Envelope Modulation Drawer** across the lower half of the screen:

| Modulation Row | Controls Revealed | Musical Function |
| :---: | :--- | :--- |
| **Row 4** | **Start Vel**, **Attack Vel**, **Break Vel**, **Sustain Vel** | Scales the envelope's Start, Attack, Break, and Sustain levels according to how hard you strike the keys. |
| **Row 5** | **AtkTm Vel**, **DecTm Vel**, **SlpTm Vel**, **RelTm Vel** | Speeds up or slows down the Attack, Decay, Slope, and Release stage times with keyboard velocity. |
| **Row 6** | **AtkTm KeyTrk**, **DecTm KeyTrk**, **SlpTm KeyTrk**, **RelTm KeyTrk**, **Time Mod Src & Int** | Makes higher notes decay faster like an acoustic piano (`KeyTrk`), or lets an external controller stretch/compress all envelope times at once. |

Tap **Reveal Modulations** again at any time to close the drawer and return to the full 5-graph view.
