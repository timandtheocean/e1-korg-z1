# Page 2: Voice Common, Key Scale & Arpeggiator (`Common & Arp`)

[← Back to the manual index](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/README.md) · [All manual pages](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages)

The **Common & Arp** page brings together all patch-wide voice assignment, unison stacking, musical scale selection, tuning instabilities, arpeggiator feel, and patch category settings on a single clean overview screen.

---

## Screen Layout Overview

```
+---------------------------------------------------------------------------------------------------+
|  ROW 1: VOICE ASSIGN & UNISON STACKING                                                            |
|  [Voice Assign ] [   Unison    ] [Unison Detune]                                                  |
+---------------------------------------------------------------------------------------------------+
|  ROW 2: PATCH SCALE, KEY, RANDOM PITCH & TRANSPOSE                                                |
|  [ Scale Type  ] [  Scale Key  ] [Random Pitch ] [  Transpose  ]                                  |
+---------------------------------------------------------------------------------------------------+
|  ROW 3: ACTIVE PROGRAM NAME BANNER                                                                |
|  [         Program Name (Read-Only Live Display)         ]                                        |
+---------------------------------------------------------------------------------------------------+
|  ROW 4: ARPEGGIATOR & PATCH CATEGORY                                                              |
|  [  Arp Gate   ] [Arp Velocity ] [  Category   ]                                                  |
+---------------------------------------------------------------------------------------------------+
```

---

## 1. Voice Assign & Unison Stacking (Row 1)

Controls how the Korg Z1 allocates its polyphonic voices when you play the keyboard:

| Control | Options / Range | Musical Function |
| :--- | :--- | :--- |
| **Voice Assign** | `Poly` / `Mono` | Switches the patch between polyphonic chord playing (`Poly`) and monophonic solo lead/bass playing (`Mono`). |
| **Unison** | `OFF`, `2 Voices`, `4 Voices` | Stacks multiple Z1 voices on every note you play for massive stereo leads, thick unison basses, or rich chord stabs. |
| **Unison Detune** | `0` – `99 cents` | Spreads the pitch of stacked Unison voices apart for wide analog-style chorusing and supersaw thickness. |

---

## 2. Musical Scale, Random Pitch & Transpose (Row 2)

Selects which temperament or custom microtonal scale the current patch uses, along with organic analog pitch drift and global transposition:

| Control | Options / Range | Musical Function |
| :--- | :--- | :--- |
| **Scale Type** | `Equal Temp 1`, `Equal Temp 2`, `Pure Major`, `Pure Minor`, `Arabic`, `Pythagorean`, `Werckmeister`, `Kirnberger`, `Slendro`, `Pelog`, `UserOctave`, `UserAllNote` | Chooses the patch's musical tuning temperament. Select **`UserOctave`** to play **User Scale 1 (Octave)** or **`UserAllNote`** to play **User Scale 2 (128 Keys)** edited on the [Utility](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/01-base-utility.md) page. |
| **Scale Key** | `C` through `B` | Sets the root tonic key for historic and world temperaments (such as `Pure Major`, `Pure Minor`, or `Arabic`). |
| **Random Pitch** | `0` – `7` | Introduces subtle random per-note pitch variation on every key strike, recreating the organic tuning drift of vintage analog poly-synths. |
| **Transpose** | `-24` to `+24` semitones | Transposes the entire patch up or down by up to 2 octaves in semitone steps. |

---

## 3. Live Program Name Banner (Row 3)

- **Program Name**: Displays the current 16-character patch name across two large lines so you always know which patch is loaded while adjusting performance and scale settings. *(To rename the patch, use the interactive character editor on [Page 1: Utility](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/01-base-utility.md).)*

---

## 4. Arpeggiator & Patch Category (Row 4)

- **Arp Gate (`1%`–`100%` / `Step`)**: Controls the staccato-to-legato note duration of the Z1's built-in arpeggiator.
- **Arp Velocity (`1`–`127` / `Key` / `Step`)**: Sets a fixed output velocity for arpeggiated notes, or allows the arpeggiator to follow your live keyboard velocity (`Key`) or programmed step velocities (`Step`).
- **Category (`0`–`15`)**: Assigns the patch to one of the Z1's 16 sound categories (such as Synth Lead, Brass, Strings, Bass, Bell/Mallet, or SFX) for organized browsing on the synthesizer.
