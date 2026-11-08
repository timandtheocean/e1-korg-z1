# Page 03b — OSC Common: OSC 1 & OSC 2 Pitch, Slope, Modulation & Model Navigation

[⬅ Back to User Manual Index](../README.md)

- **Source Folder:** [`e1/z1-osc-common/`](../../e1/z1-osc-common/)
- **Files:** [`preset.json`](../../e1/z1-osc-common/preset.json) | [`main.lua`](../../e1/z1-osc-common/main.lua) | [`main-tests.lua`](../../e1/z1-osc-common/main-tests.lua)
- **Z1 Parameters Covered:**
  - `ID 174` & `ID 188` (`ExID = 0`): Current selected **OSC 1 Model** (`0..12`) & **OSC 2 Model** (`0..8`) displays and selectors
  - `IDs 175..187` (`ExID = 0`): All **13** OSC 1 Core Pitch, Pitch Slope & Pitch Modulation 1/2 parameters
  - `IDs 189..201` (`ExID = 0`): All **13** OSC 2 Core Pitch, Pitch Slope & Pitch Modulation 1/2 parameters

> 📸 **[Screenshot Placeholder: `../media/03b-osc-common.png`]**
> *Add screenshot of the `OSC Common` page showing the `Jump OSC 1` / `Jump OSC 2` pads, the custom `OSC1 Model` / `OSC2 Model` displays, and symmetric OSC1/OSC2 tuning rows.*
>
> 🎬 **[Video Placeholder: `../media/03b-osc-common.mp4`]**
> *Add short video demonstrating two-Row OSC1 vs. OSC2 detuning and jumping to the OSC1/OSC2 pages.*

---

## 1. Overview

The **OSC Common** page pairs **OSC 1** (top row of each control set) and **OSC 2** (bottom row of each control set) so you can tune, key-scale, and modulate both oscillators side-by-side using the Electra One's two rows of physical encoders.

In **Control Set 1 (Rows 1–2)**:
- **Slots 1 & 7 (`Jump OSC 1` / `Jump OSC 2`):** Momentary pads that jump directly to the **OSC 1** (`Page 2`) or **OSC 2** (`Page 3`) dynamic model editor page via `pages.display()`. On **Page 2 (`OSC 1`)** and **Page 3 (`OSC 2`)**, **Slot 1 (top-left corner)** is the **`OSC Common`** button to jump right back to **Page 1**, and **Slot 2** is the **`OSC1 TYPE` / `OSC2 TYPE`** selector.
- **Slots 2 & 8 (`OSC1 Model` / `OSC2 Model`):** Custom-painted LCD widgets displaying the currently selected synthesis model for **OSC 1** (`[00] Standard OSC` .. `[12] Bowed String`) and **OSC 2** (`[00] Standard OSC` .. `[08] E.Piano Model`). Turning Pot 2 or Pot 8 also selects the model directly (`ID 174` / `ID 188`).

---

## 2. Control Layout (Symmetric OSC 1 / OSC 2 Rows)

### Control Set 1 — Navigation, Selected Model & Core Pitch (Rows 1–2)

| Osc | Col 1 (Jump) | Col 2 (Active Model) | Col 3 (`Octave`) | Col 4 (`Semi`) | Col 5 (`Fine`) | Col 6 (`Offset`) |
|:---:|---|---|---|---|---|---|
| **Row 1 (OSC 1)** | `[1]` **`Jump OSC 1`**<br>*(Pad $\rightarrow$ Page 2)* | `[2]` **`OSC1 Model`**<br>(`ID 174`, `0..12` LCD) | `[3]` `OSC1 Octave`<br>(`ID 175`, `32'..4'`) | `[4]` `OSC1 Semi`<br>(`ID 176`, `-12..+12`) | `[5]` `OSC1 Fine`<br>(`ID 177`, `-50..+50`) | `[6]` `OSC1 Offset`<br>(`ID 178`, `-10..+10Hz`) |
| **Row 2 (OSC 2)** | `[7]` **`Jump OSC 2`**<br>*(Pad $\rightarrow$ Page 3)* | `[8]` **`OSC2 Model`**<br>(`ID 188`, `0..8` LCD) | `[9]` `OSC2 Octave`<br>(`ID 189`, `32'..4'`) | `[10]` `OSC2 Semi`<br>(`ID 190`, `-12..+12`) | `[11]` `OSC2 Fine`<br>(`ID 191`, `-50..+50`) | `[12]` `OSC2 Offset`<br>(`ID 192`, `-10..+10Hz`) |

### Control Set 2 — Pitch Key Slope & Pitch Modulation 2 (Rows 3–4)

| Osc | Col 1 (`CtrKey`) | Col 2 (`LoSlp`) | Col 3 (`HiSlp`) | Col 4 (`Mod2Src`) | Col 5 (`Mod2Int`) |
|:---:|---|---|---|---|---|
| **Row 3 (OSC 1)** | `[13]` `OSC1 CtrKey`<br>(`ID 179`, `C-1..G9`) | `[14]` `OSC1 LoSlp`<br>(`ID 180`, `-1.0..+2.0`) | `[15]` `OSC1 HiSlp`<br>(`ID 181`, `-1.0..+2.0`) | `[16]` `OSC1 Mod2Src`<br>(`ID 186`, `MODSRC1`) | `[17]` `OSC1 Mod2Int`<br>(`ID 187`, `-99..+99`) |
| **Row 4 (OSC 2)** | `[19]` `OSC2 CtrKey`<br>(`ID 193`, `C-1..G9`) | `[20]` `OSC2 LoSlp`<br>(`ID 194`, `-1.0..+2.0`) | `[21]` `OSC2 HiSlp`<br>(`ID 195`, `-1.0..+2.0`) | `[22]` `OSC2 Mod2Src`<br>(`ID 200`, `MODSRC1`) | `[23]` `OSC2 Mod2Int`<br>(`ID 201`, `-99..+99`) |

### Control Set 3 — Pitch Modulation 1 & Dynamic Controller (Rows 5–6)

| Osc | Col 1 (`Mod1Src`) | Col 2 (`Mod1Int`) | Col 3 (`M1Ctrl`) | Col 4 (`M1CInt`) |
|:---:|---|---|---|---|
| **Row 5 (OSC 1)** | `[25]` `OSC1 Mod1Src`<br>(`ID 182`, `MODSRC1`) | `[26]` `OSC1 Mod1Int`<br>(`ID 183`, `-99..+99`) | `[27]` `OSC1 M1Ctrl`<br>(`ID 184`, `MODSRC1`) | `[28]` `OSC1 M1CInt`<br>(`ID 185`, `-99..+99`) |
| **Row 6 (OSC 2)** | `[31]` `OSC2 Mod1Src`<br>(`ID 196`, `MODSRC1`) | `[32]` `OSC2 Mod1Int`<br>(`ID 197`, `-99..+99`) | `[33]` `OSC2 M1Ctrl`<br>(`ID 198`, `MODSRC1`) | `[34]` `OSC2 M1CInt`<br>(`ID 199`, `-99..+99`) |
