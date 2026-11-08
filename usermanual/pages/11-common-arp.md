# Page 11 — Program Common, Unison, Scale, Assignable Controllers, Link Arpeggiator & Patch Name

[⬅ Back to User Manual Index](../README.md)

- **Source Folder:** [`e1/z1-common-arp/`](../../e1/z1-common-arp/)
- **Files:** [`preset.json`](../../e1/z1-common-arp/preset.json) | [`main.lua`](../../e1/z1-common-arp/main.lua) | [`main-tests.lua`](../../e1/z1-common-arp/main-tests.lua)
- **Z1 Parameters Covered:** All **48** parameters across `[Program Name]` (`IDs 1..16`), `[Program Common]` (`IDs 17..30`), `[Controller]` (`IDs 366..373`), and `[Link Arpeggio]` (`IDs 374..383`), all with `ExID = 0`.

> 📸 **[Screenshot Placeholder: `../media/11-common-arp.png`]**
> *Add screenshot of the Program Common, Link Arpeggiator, Assignable Controllers, and Program Name LCD widget.*
>
> 🎬 **[Video Placeholder: `../media/11-common-arp.mp4`]**
> *Add short video demonstrating Unison Voice/Detune, Link Arpeggiator controls, and the 2-slot Program Name LCD display.*

---

## 1. Overview

This page provides complete control over the Korg Z1's voice architecture and performance controls:
- **Program Common & Unison (`IDs 17..30`):** Program Category (`0..17`), Sound Group (`A..D`), Assign Mode (`Poly` / `Mono`), Trigger Mode & Priority, Retrigger Source (`MODSRC2`) & Threshold, Unison SW / Voice Count (`2..6`) / Detune (`0..99`), Random Pitch Intensity, and Scale Type (`Equal Temp`..`User Scale`) & Key (`C..B`).
- **Link Arpeggiator (`IDs 374..383`):** Pattern Select (`Preset00..User19`), Speed (`40..240 BPM`), Resolution, Octave (`1..4`), Latch, Key Sync, Velocity (`Key` or `1..127`), Gate (`Step` or `1..100%`), Intensity, and Timbre (`Common`).
- **Assignable Controllers (`IDs 366..373`):** `SW1`/`SW2` Assign & Mode (`Toggle`/`Moment`), `Foot SW` Assign & Polarity, `Foot Pedal` Assign, and `X/Y Pad Hold`.
- **Program Name Editor & Custom LCD Widget (`IDs 1..16`, `Controls 33..35`):** 2-slot custom graphical LCD display showing the 16-character patch name and active cursor position.

---

## 2. Control Layout (35 Controls across 3 Control Sets)

### Control Set 1 — Program Common & Unison (Rows 1–2)
- **Row 1 (Slots `1..6`):** `[1]` `Category` (`17`), `[2]` `Group` (`18`), `[3]` `Voice Mode` (`19: Poly/Mono`), `[4]` `Trig Mode` (`20: Single/Multi`), `[5]` `Trig Prio` (`21: Last/Low/High`), `[6]` `Rnd Pitch` (`30: 0..7`).
- **Row 2 (Slots `7..12`):** `[7]` `Retrig Src` (`22: MODSRC2`), `[8]` `Retrig Thr` (`23: 1..99`), `[9]` `Unison SW` (`24: OFF/ON`), `[10]` `Uni Voice` (`25: 2..6`), `[11]` `Uni Detune` (`26: 0..99`), `[12]` `OSC Phase` (`27: 0..100`).

### Control Set 2 — Scale & Link Arpeggiator (Rows 3–4)
- **Row 3 (Slots `13..18`):** `[13]` `Scale Type` (`28: 0..10`), `[14]` `Scale Key` (`29: C..B`), `[15]` `Arp Pattern` (`374: 0..34`), `[16]` `Arp Speed` (`375: 40..240`), `[17]` `Arp Reso` (`376: 0..5`), `[18]` `Arp Octave` (`377: 1..4`).
- **Row 4 (Slots `19..24`):** `[19]` `Arp Latch` (`378: OFF/ON`), `[20]` `Arp KeySync` (`379: OFF/ON`), `[21]` `Arp Vel` (`380: 0=Key, 1..127`), `[22]` `Arp Gate` (`381: 0=Step, 1..100%`), `[23]` `Arp Int` (`382: -99..+99`), `[24]` `Arp Timbre` (`383`).

### Control Set 3 — Assignable Controllers & Program Name Editor (Rows 5–6)
- **Row 5 (Slots `25..30`):** `[25]` `SW1 Assign` (`366`), `[26]` `SW1 Mode` (`367`), `[27]` `SW2 Assign` (`368`), `[28]` `SW2 Mode` (`369`), `[29]` `FootSW Asgn` (`370`), `[30]` `FootSW Pol` (`371`).
- **Row 6 (Slots `31..36`):** `[31]` `Pedal Asgn` (`372`), `[32]` `Pad Hold` (`373`), `[33]` `Name Pos` (`1..16`), `[34]` `Name Char` (`32..127`), `[35–36]` **`Program Name`** *(2-Slot Custom LCD Widget)*.
