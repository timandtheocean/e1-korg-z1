# Page 11: Quad LFOs (`LFO1-4`)

[← Back to the manual index](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/README.md) · [All manual pages](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages)

The Korg Z1 features four independent Low Frequency Oscillators (**LFO 1**, **LFO 2**, **LFO 3**, and **LFO 4**) with 18 waveform shapes, variable starting phase, vertical DC offset, fade-in delay/ramp, key sync, and MIDI clock synchronization.

The **LFO1-4** page arranges all four LFOs side by side in vertical columns topped by **live custom waveform visualizers**, with a shared **MIDI Sync & Frequency Modulation** inspector at the bottom of the screen.

---

## Screen Layout Overview

```
+------------------------+------------------------+------------------------+------------------------+
|     LFO 1 (Col 1)      |     LFO 2 (Col 2)      |     LFO 3 (Col 3)      |     LFO 4 (Col 4)      |
+------------------------+------------------------+------------------------+------------------------+
| [ Live LFO 1 Graph  ]  | [ Live LFO 2 Graph  ]  | [ Live LFO 3 Graph  ]  | [ Live LFO 4 Graph  ]  |
|   (Tap to select!)     |   (Tap to select!)     |   (Tap to select!)     |   (Tap to select!)     |
| [   LFO1 Waveform   ]  | [   LFO2 Waveform   ]  | [   LFO3 Waveform   ]  | [   LFO4 Waveform   ]  |
| [   LFO1 Freq/Spd   ]  | [   LFO2 Freq/Spd   ]  | [   LFO3 Freq/Spd   ]  | [   LFO4 Freq/Spd   ]  |
| [    LFO1 Offset    ]  | [    LFO2 Offset    ]  | [    LFO3 Offset    ]  | [    LFO4 Offset    ]  |
| [LFO1 FadeIn Delay  ]  | [LFO2 FadeIn Delay  ]  | [LFO3 FadeIn Delay  ]  | [LFO4 FadeIn Delay  ]  |
+------------------------+------------------------+------------------------+------------------------+
|                                                 |  COL 5 (Row 2):        |  COL 5 (Row 4):        |
|                                                 |  [    LFO SELECT    ]  |  [  LFO FadeInTime  ]  |
+-------------------------------------------------+------------------------+------------------------+
|  ROW 6: SELECTED LFO SYNC, PHASE & SPEED MODULATION                                               |
|  [  MIDI Sync  ] [  Sync Note  ] [Key SyncMode ] [Freq Mod1Src ] [Freq Mod1Int ] [Freq Mod2Int*] |
+---------------------------------------------------------------------------------------------------+
```

---

## 1. Live LFO Waveform Visualizers (Row 1)

At the top of each LFO column is a real-time graphical display that draws the exact shape of that LFO:
- **All 18 Z1 Wave Shapes Drawn Accurately**: Smoothly renders `Triangle`, `Saw Up`, `Saw Down`, `Square 1`, `Square 2`, `Sine`, `Guitar`, `Exponential Triangle`, `Exp Saw Down`, `Step Triangle 4`, `Step Triangle 6`, `Step Saw 4`, `Step Saw 6`, `Random 1 (S&H)`, `Random 2`, `Random 3`, `Random 4`, and `Random 5`.
- **Live Vertical Offset Preview**: Adjusting **Offset** (`-99` to `+99`) shifts the waveform vertically above or below the zero-crossing center line on the display, showing whether the LFO modulates symmetrically (`±`) or unipolar-positive/negative.
- **Live Fade-In Envelope Overlay**: Raising **FadeIn Delay** or **FadeIn Time** draws the gradual amplitude ramp directly over the beginning of the LFO wave so you can see how delayed vibrato or tremolo builds up after a note is played.
- **Tap Any Graph to Select That LFO**: Simply tap the waveform display at the top of **LFO 1**, **LFO 2**, **LFO 3**, or **LFO 4** to highlight that LFO in bright teal and load its advanced Sync & Speed Modulation controls into Row 6.

---

## 2. Core Per-LFO Controls (Columns 1–4, Rows 2–5)

Each of the four LFOs has immediate dedicated controls for its primary parameters:
- **Waveform**: Selects one of the 18 LFO waveform shapes.
- **Freq (`0`–`99`)**: Sets the LFO speed from ultra-slow multi-bar sweeps to audio-rate modulation buzz.
- **Offset (`-99` to `+99`)**: Biases the LFO cycle upward or downward relative to the base parameter value.
- **FadeIn Delay (`0`–`99`)**: Holds the LFO silent for a set pause after note-on before the LFO modulation begins to swell in.

---

## 3. Selected LFO Inspector: Fade-In Time, Sync & Speed Modulation (Column 5 & Row 6)

When you tap any LFO's waveform display (or turn **LFO SELECT** in Column 5), the controls in Column 5 and Row 6 automatically bind to the selected LFO:

| Control | Options / Range | Musical Function |
| :--- | :--- | :--- |
| **LFO SELECT** | `LFO 1` – `LFO 4` | Selects which LFO is edited by the controls below (synchronized with tapping the 4 LFO graphs). |
| **LFO FadeInTime** | `0` – `99` | Controls how gradually the selected LFO swells from zero up to full depth after the **FadeIn Delay** expires. |
| **MIDI Sync** | `OFF` / `ON` | Locks the selected LFO's speed to incoming MIDI Clock tempo *(available on LFO 1 & LFO 2)*. |
| **Sync Note** | `1/32` to `4/1` (incl. triplets/dotted) | Sets the musical note division when **MIDI Sync** is turned ON. |
| **Key SyncMode** | `OFF`, `Timbre` (All Voices), `Voice` (Per Key), `0°`, `180°` | Determines whether all notes share one free-running LFO (`OFF`/`Timbre`) or each new note restarts its own LFO phase (`Voice`). |
| **Freq Mod1Src & Int** | Mod Source / `-99` to `+99` | Dynamically speeds up or slows down the LFO using an envelope, aftertouch, velocity, or performance knob. |
| **Freq Mod2Src & Int** | Mod Source / `-99` to `+99` | Secondary speed modulation routing *(available on LFO 1 & LFO 2)*. |
