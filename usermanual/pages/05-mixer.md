# Page 05 — Mixer, Dual Filter Buses, Feedback & Bus Bar-Graph Visualizers

[⬅ Back to User Manual Index](../README.md)

- **Source Folder:** [`e1/z1-mix/`](../../e1/z1-mix/)
- **Files:** [`preset.json`](../../e1/z1-mix/preset.json) | [`main.lua`](../../e1/z1-mix/main.lua) | [`main-tests.lua`](../../e1/z1-mix/main-tests.lua)
- **Z1 Parameters Covered:** All **34** `[Mixer]` parameters (`IDs 224..257`, `ExID = 0`) + 2 custom Mixer Bus Bar-Graph widgets (`Out 1 -> F1` and `Out 2 -> F2`).

> 📸 **[Screenshot Placeholder: `../media/05-mixer.png`]**
> *Add screenshot of the 5-column Mixer layout and the `Out 1 Bus` / `Out 2 Bus` custom bar-graph visualizers in Column 6.*
>
> 🎬 **[Video Placeholder: `../media/05-mixer.mp4`]**
> *Add short video showing real-time bar-graph updates when adjusting `Out 1` / `Out 2` levels and toggling `OSC1..Noise Out SW`.*

---

## 1. Overview

The Korg Z1 Mixer blends five audio sources (**OSC 1**, **OSC 2**, **Sub OSC**, **Noise**, and post-amp **Feedback**) into two independent filter buses:
- **Output 1 Bus (`Out 1`)** $\rightarrow$ feeds **Filter 1**
- **Output 2 Bus (`Out 2`)** $\rightarrow$ feeds **Filter 2**

The page is arranged as **5 vertical channel strips** in Columns 1–5 (`OSC1`, `OSC2`, `SUB`, `NOISE`, `FBK`), while Column 6 houses the four **Source Output On/Off switches** (`IDs 254..257`) and two live **Custom Bus Bar-Graph Visualizers** (`Controls 30 & 36`) that render the relative levels and mute states of all 5 channels feeding `Out 1` and `Out 2`.

---

## 2. Control Layout (36 Controls across 3 Control Sets)

| Row | Col 1 (`OSC1`) | Col 2 (`OSC2`) | Col 3 (`SUB`) | Col 4 (`NOISE`) | Col 5 (`FBK`) | Col 6 (`SW / Meters`) |
|:---:|---|---|---|---|---|---|
| **Row 1**<br>*(Out 1 Level)* | `[1]` `OSC1 Out1`<br>(`ID 224`, `0..99`) | `[2]` `OSC2 Out1`<br>(`ID 230`, `0..99`) | `[3]` `SUB Out1`<br>(`ID 236`, `0..99`) | `[4]` `Noise Out1`<br>(`ID 242`, `0..99`) | `[5]` `Fbk Out1`<br>(`ID 248`, `0..99`) | `[6]` `OSC1 Out SW`<br>(`ID 254`, `OFF/ON`) |
| **Row 2**<br>*(Out 2 Level)* | `[7]` `OSC1 Out2`<br>(`ID 227`, `0..99`) | `[8]` `OSC2 Out2`<br>(`ID 233`, `0..99`) | `[9]` `SUB Out2`<br>(`ID 239`, `0..99`) | `[10]` `Noise Out2`<br>(`ID 245`, `0..99`) | `[11]` `Fbk Out2`<br>(`ID 251`, `0..99`) | `[12]` `OSC2 Out SW`<br>(`ID 255`, `OFF/ON`) |
| **Row 3**<br>*(Out 1 Mod Src)* | `[13]` `O1 M.Src1`<br>(`ID 225`, `MODSRC1`) | `[14]` `O2 M.Src1`<br>(`ID 231`, `MODSRC1`) | `[15]` `SB M.Src1`<br>(`ID 237`, `MODSRC1`) | `[16]` `NS M.Src1`<br>(`ID 243`, `MODSRC1`) | `[17]` `FB M.Src1`<br>(`ID 249`, `MODSRC1`) | `[18]` `SUB Out SW`<br>(`ID 256`, `OFF/ON`) |
| **Row 4**<br>*(Out 1 Mod Int)* | `[19]` `O1 M.Int1`<br>(`ID 226`, `-99..+99`) | `[20]` `O2 M.Int1`<br>(`ID 232`, `-99..+99`) | `[21]` `SB M.Int1`<br>(`ID 238`, `-99..+99`) | `[22]` `NS M.Int1`<br>(`ID 244`, `-99..+99`) | `[23]` `FB M.Int1`<br>(`ID 250`, `-99..+99`) | `[24]` `Noise Out SW`<br>(`ID 257`, `OFF/ON`) |
| **Row 5**<br>*(Out 2 Mod Src)* | `[25]` `O1 M.Src2`<br>(`ID 228`, `MODSRC1`) | `[26]` `O2 M.Src2`<br>(`ID 234`, `MODSRC1`) | `[27]` `SB M.Src2`<br>(`ID 240`, `MODSRC1`) | `[28]` `NS M.Src2`<br>(`ID 246`, `MODSRC1`) | `[29]` `FB M.Src2`<br>(`ID 252`, `MODSRC1`) | `[30]` **`Out 1 Bus`**<br>*(Custom Graph)* |
| **Row 6**<br>*(Out 2 Mod Int)* | `[31]` `O1 M.Int2`<br>(`ID 229`, `-99..+99`) | `[32]` `O2 M.Int2`<br>(`ID 235`, `-99..+99`) | `[33]` `SB M.Int2`<br>(`ID 241`, `-99..+99`) | `[34]` `NS M.Int2`<br>(`ID 247`, `-99..+99`) | `[35]` `FB M.Int2`<br>(`ID 253`, `-99..+99`) | `[36]` **`Out 2 Bus`**<br>*(Custom Graph)* |
