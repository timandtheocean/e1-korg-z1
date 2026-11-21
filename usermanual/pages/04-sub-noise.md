# Page 6: Sub Oscillator, Noise Generator & Portamento (`Sub, Noise & Common`)

The **Sub, Noise & Common** page controls the Korg Z1's third pitched sound source (**Sub Oscillator**), its **Noise Generator** (which includes a dedicated multimode **Noise Filter** separate from the two main voice filters), and the patch-wide **Pitch Bend & Portamento** behavior.

---

## Screen Layout Overview

```
+---------------------------------------------------------------------------------------------------+
|  ROW 1: SUB OSCILLATOR                                                                            |
|  [  Sub Wave   ]                                                                                  |
+---------------------------------------------------------------------------------------------------+
|  ROWS 2-3: NOISE GENERATOR & DEDICATED NOISE FILTER                                               |
|  [ Noise FltTyp] [ Noise Cutoff] [ Noise Reso  ] [Noise KeyTrk ] [ Noise EG Src] [ Noise EG Int]  |
|  [Noise EGVelIn] [Noise Mod Src] [Noise Mod Int]                                                  |
+---------------------------------------------------------------------------------------------------+
|  ROWS 4-5: GLOBAL PITCH BEND & PORTAMENTO                                                         |
|  [ PitchBnd Up ] [PitchBnd Down] [Bnd+X ModSrc ] [Bnd-X ModSrc ]                                  |
|  [ Porta Enable] [Porta Fingerd] [ Porta Time  ] [Porta Mod Src] [Porta Mod Int]                  |
+---------------------------------------------------------------------------------------------------+
```

---

## 1. Sub Oscillator (Row 1)

The Sub Oscillator tracks the pitch of **Oscillator 1** one octave below to add weight and foundation—or can be used as a clean carrier input for OSC 1/OSC 2 Ring Modulation, Cross Modulation, Comb Filtering, or Hard Sync.

- **Sub Wave**: Selects the Sub Oscillator waveform:
  - `Sine`: Pure fundamental sub-bass weight.
  - `Triangle`: Warm low-end with gentle odd harmonics.
  - `Saw`: Bright sub-octave buzz.
  - `Pulse`: Hollow square-wave sub-octave punch.

*(Set the Sub Oscillator's level and routing into Filter 1 and Filter 2 on [Page 7: Mixer](file:///home/timbos/src/Z1/usermanual/pages/05-mixer.md).)*

---

## 2. Noise Generator & Dedicated Multimode Noise Filter (Rows 2–3)

Before the Z1's white noise generator even reaches the main Mixer or Main Filters 1 & 2, it passes through its own dedicated resonant **Noise Filter**. This allows you to sculpt tuned breath transients, wind sweeps, snare rattle, or bow rosin hiss independently of your main filter settings.

| Control | Range / Options | Musical Function |
| :--- | :--- | :--- |
| **Noise FltTyp** | `LPF`, `HPF`, `BPF`, `2BPF`, `BYP` | Selects Low-Pass, High-Pass, Band-Pass, Dual Band-Pass, or Bypass for the pre-mixer noise filter. |
| **Noise Cutoff** | `0` – `99` | Sets the center/cutoff frequency of the noise filter. |
| **Noise Reso** | `0` – `99` | Boosts resonance around the noise cutoff frequency; at high settings, the noise becomes pitched. |
| **Noise KeyTrk** | `-200%` to `+200%` | Causes the noise filter cutoff to track the note you play on the keyboard (`100%` = 1:1 chromatic tracking). |
| **Noise EG Src** | `EG1` – `EG4`, `Amp1 EG`, `Amp2 EG` | Selects which of the Z1's envelopes sweeps the noise filter cutoff. |
| **Noise EG Int** | `-99` to `+99` | Depth and polarity of the envelope sweep on the noise filter cutoff. |
| **Noise EGVelIn** | `-99` to `+99` | Scales the noise filter envelope sweep depth by keyboard velocity. |
| **Noise Mod Src** | Any Mod Source | Assigns an additional real-time modulator (such as an LFO, Joystick, or Aftertouch) to the noise cutoff. |
| **Noise Mod Int** | `-99` to `+99` | Depth of the secondary noise cutoff modulation. |

---

## 3. Pitch Bend & Portamento (Rows 4–5)

Controls how the entire voice glides between notes and responds to horizontal joystick (`±X`) pitch-bend gestures:

| Control | Range / Options | Musical Function |
| :--- | :--- | :--- |
| **PitchBnd Up** | `-48` to `+48` semitones | Pitch bend range when moving the Z1 joystick to the right (`+X`). |
| **PitchBnd Down** | `-48` to `+48` semitones | Pitch bend range when moving the Z1 joystick to the left (`-X`). |
| **Bnd+X ModSrc / Bnd-X ModSrc** | Mod Sources | Optional alternate modulation controllers routed to positive and negative pitch bend. |
| **Porta Enable** | `OFF` / `ON` | Turns pitch glide (Portamento) between notes on or off. |
| **Porta Fingerd** | `OFF` / `ON` | When **ON** (`Fingered`), portamento glides only when you play legato (overlapping notes) and jumps immediately when you play detached notes. |
| **Porta Time** | `0` – `99` | Sets the glide speed from instant (`0`) to long cinematic sweeps (`99`). |
| **Porta Mod Src & Int** | Mod Source / `-99` to `+99` | Modulates portamento speed dynamically (for example, using Velocity so hard strikes glide faster than soft notes). |
