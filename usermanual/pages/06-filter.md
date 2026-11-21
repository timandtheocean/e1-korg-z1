# Page 8: Dual Multi-Mode Filters (`Filters`)

[← Back to the manual index](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/README.md) · [All manual pages](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages)

The Korg Z1 contains two independent multi-mode resonant filters (**Filter 1** and **Filter 2**). The **Filters** page displays both filters side by side with live interactive frequency-response graphs, an intelligent **Assigned Cutoff Envelope** editor at the bottom of the screen, and an auto-appearing drawer for Dual Band-Pass (`2BPF`) controls.

---

## Screen Layout Overview

```
+-------------------------------------------------+-------------------------------------------------+
|               FILTER 1 (Cols 1-3)               |               FILTER 2 (Cols 4-6)               |
+-------------------------------------------------+-------------------------------------------------+
| [ Flt1 Type ] [  Flt1 Cutoff & Reso Graph   ]   | [ Flt2 Type ] [  Flt2 Cutoff & Reso Graph   ]   |
| [Fl1 Cutoff ] [ Fl1 Reso  ] [ Fl1 KeyTrk ]      | [Fl2 Cutoff ] [ Fl2 Reso  ] [ Fl2 KeyTrk ]      |
| [Fl1 EG Src ] [Fl1 EG Int ] [Fl1 EGVelInt]      | [Fl2 EG Src ] [Fl2 EG Int ] [Fl2 EGVelInt]      |
| [Fl1 Mod1Src] [Fl1 Mod1Int] [Fl1 Mod2Src ]      | [Fl2 Mod1Src] [Fl2 Mod1Int] [Fl2 Mod2Src ]      |
+-------------------------------------------------+-------------------------------------------------+
|  ROWS 5-6: ASSIGNED CUTOFF ENVELOPE & ACTIVE FILTER SELECTOR (Default View)                       |
|  [Fl1 Mod2Int] [  Interactive Assigned Cutoff EG Graph (Cols 2-4)  ] [FILTER SELECT] [Fl2 Mod2Int] |
|  [  Attack   ] [   Decay   ] [   Slope   ] [  Release  ] [EG StartLvl] [ Flt2 Link ]               |
+---------------------------------------------------------------------------------------------------+
```
*(When either Filter 1 or Filter 2 is set to **`2BPF` (Dual Band-Pass)** and selected with **FILTER SELECT**, Row 5 automatically reveals the **Band-B Offset, Resonance, and Modulation** controls.)*

---

## 1. Filter Types & Interactive Response Curves (Rows 1–2)

Each filter offers five operating modes via **Flt1 Type** and **Flt2 Type**:
- **`LPF` (Low-Pass Filter)**: Passes low frequencies and rolls off highs above the cutoff point; ideal for warm pads, basses, and classic subtractive sweeps.
- **`HPF` (High-Pass Filter)**: Passes high frequencies and removes low-end fundamental weight.
- **`BPF` (Band-Pass Filter)**: Focuses on a narrow frequency band around the cutoff frequency.
- **`2BPF` (Dual Band-Pass Filter)**: Splits the filter into **two parallel resonant bandpass peaks** (`Band A` and `Band B`) for rich vocal formants and phasing timbres.
- **`BYP` (Bypass)**: Passes the mixer bus straight to the amplifier without filtering.

### Live Frequency-Response Curve Displays
- Beside each filter's Type selector is a live graphical **Filter Response Curve** showing the exact filter slope (`LPF`, `HPF`, `BPF`, `2BPF`, or flat `BYP`), cutoff position, and resonance peak height.
- Turning **Cutoff** slides the curve horizontally across the frequency spectrum; turning **Reso** raises or lowers the resonant peak in real time.

---

## 2. Cutoff Modulation & Filter 2 Link (Rows 2–4 & Row 6)

Both Filter 1 and Filter 2 feature complete modulation routing:
- **Cutoff (`0`–`99`) & Reso (`0`–`99`)**: Base cutoff frequency and resonance peak.
- **KeyTrk (`-200%` to `+200%`)**: Keyboard tracking slope (`100%` tracks the keyboard chromatically).
- **EG Src, EG Int (`-99` to `+99`) & EG Vel Int (`-99` to `+99`)**: Chooses which envelope (`EG 1`–`EG 4` or `Amp EG`) sweeps the filter cutoff, sets the sweep depth/polarity, and scales the sweep by keyboard velocity.
- **Mod1 Src / Int & Mod2 Src / Int**: Two independent modulation slots per filter for LFO sweeps, Aftertouch, Joystick, or Performance Knobs.
- **Flt2 Link** *(Row 6, Column 6)*: Links Filter 2's cutoff movements to Filter 1 so you can sweep both filters together as a ganged stereo or dual-formant pair while maintaining a relative frequency offset.

---

## 3. Interactive Assigned Cutoff EG & `FILTER SELECT` (Rows 5–6)

Instead of making you flip back and forth between the Filters page and the Envelopes page while dialing in a filter sweep, the bottom center of the Filters page embeds a **live touch-editable Cutoff Envelope Graph**:

1. **FILTER SELECT (`Filter 1` / `Filter 2`)**: Selects which filter the bottom section focuses on.
2. **Automatic Envelope Following**: The embedded envelope graph automatically links to whichever envelope is currently chosen in **EG Src** (`EG 1`, `EG 2`, `EG 3`, `EG 4`, or `Amp EG`) for the selected filter!
3. **Touch-Drag or Knob Editing**: Drag the envelope stages directly on the touchscreen—or use the **Attack**, **Decay**, **Slope**, **Release**, and **EG StartLvl** controls in Row 6—to reshape the active filter envelope. Any edits you make here stay 100% synchronized with [Page 10: Envelopes](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/07-envelopes.md).

---

## 4. Dual Band-Pass (`2BPF`) Band-B Drawer

When you set the selected filter's type to **`2BPF` (Dual Band-Pass)**, the controller automatically reveals the secondary **Band-B** parameters in Row 5:
- **Band-B Cutoff Offset**: Sets the frequency distance between the first formant peak (`Band A`) and the second formant peak (`Band B`).
- **Band-B Resonance**: Sets the resonant peak height of the second bandpass filter.
- **Band-B Offset Modulation**: Modulates the spacing between the two bandpass peaks for animated vowel and talk-box effects.
