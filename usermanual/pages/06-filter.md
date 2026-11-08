# Page 06 — Dual Multi-Mode Filters (Filter 1 & 2), Assigned Cutoff EG & 2BPF Band-B

[⬅ Back to User Manual Index](../README.md)

- **Source Folder:** [`e1/z1-filter/`](../../e1/z1-filter/)
- **Files:** [`preset.json`](../../e1/z1-filter/preset.json) | [`main.lua`](../../e1/z1-filter/main.lua) | [`main-tests.lua`](../../e1/z1-filter/main-tests.lua)
- **Z1 Parameters Covered:** All **57** `[Filter]` parameters (`IDs 258..314`, `ExID = 0`, including `Filter Routing 258`, `Filter Link SW 259`, `Filter EG Knob's Target 260`, `Filter 1 IDs 261..287`, and `Filter 2 IDs 288..314`), plus dynamic access to the **Assigned Cutoff EG** (`EG1..EG4` / `Amp EG`).

> 📸 **[Screenshot Placeholder: `../media/06-filter.png`]**
> *Add screenshots showing Filter 1 with standard LPF (Row 5-6 hidden) vs. `2BPF` selected (Row 5-6 Dual-Bandpass Band-B controls revealed).*
>
> 🎬 **[Video Placeholder: `../media/06-filter.mp4`]**
> *Add short video demonstrating the Assigned Cutoff EG widget tracking `Cutoff EG Src` and the `2BPF` Band-B conditional drawer.*

---

## 1. Overview

The Korg Z1 features two multi-mode filters (**Filter 1** and **Filter 2**) that can be routed in `Serial`, `Parallel`, or `Indiv` (Individual), with six filter modes (`LPF24`, `LPF12`, `HPF`, `BPF`, `BRF`, and `2BPF` Dual-Bandpass).

Key workflow features on this page:
1. **Top Overview & Side-by-Side Filter 1 / Filter 2 Controls (Control Set 1):**
   - `Filter Routing` (`ID 258`), `Filter Link` (`ID 259`), `EG Knob Tgt` (`ID 260: Filter1 / Filter2 / Filter1&2`), and core `Type`, `Input Trim`, `Cutoff`, and `Resonance` for both Filter 1 and Filter 2.
2. **Dynamic Assigned Cutoff EG Widget (`Controls 4 & 6`):**
   - A live `dx7envelope` curve editor (`Control 4`) + `EG Start Lvl` fader (`Control 6`) that automatically binds to whichever Envelope (`EG1`–`EG4` or `Amp EG`) is selected as the active filter's `Cutoff EG Src` (`ID 266` / `ID 293`)! If a non-EG source is chosen, it defaults to `EG1` (`Filter 1`) or `EG2` (`Filter 2`).
3. **Filter Selector (`Control 13`, `FILTER SELECT: Filter 1 / Filter 2`):**
   - Switches Control Sets 2 and 3 between **Filter 1** (`IDs 265..287`) and **Filter 2** (`IDs 292..314`).
4. **Conditional Dual-Bandpass (`2BPF`) Band-B Drawer (Control Set 3, Slots `26..36`):**
   - Parameters for **Filter-B** (`Cutoff-B`, `Cutoff-B Key Track`, `Cutoff-B EG/Mod1/Mod2`) are **automatically shown only when the selected filter's Type is set to `2BPF` (`5`)**, keeping the interface clean for standard filter modes.

---

## 2. Control Layout

### Control Set 1 — Routing, Assigned Cutoff EG & Filter 1/2 Core (Rows 1–2)

| Slot(s) | Control ID | Parameter ID | Label | Type | Range / Values |
|:---:|:---:|:---:|---|---|---|
| **1** | `1` | `258` | `Filter Routing` | List | `0..2` (`Serial`, `Parallel`, `Indiv`) |
| **2** | `2` | `259` | `Filter Link` | Toggle Pad | `0..1` (`OFF` / `ON`) |
| **3** | `3` | `260` | `EG Knob Tgt` | List | `1..3` (`Filter1`, `Filter2`, `Filter1&2`) |
| **4–5** | `4` | *Dynamic EG* | `Cutoff EG` | `dx7envelope` | 8-parameter interactive envelope curve for the assigned Cutoff EG. |
| **6** | `6` | *Dynamic EG* | `EG Start Lvl` | Fader | `-99..+99` (`Start Level` of the assigned Cutoff EG). |
| **7** | `7` | `261` | `F1 Type` | List | `0..5` (`LPF24`, `LPF12`, `HPF`, `BPF`, `BRF`, `2BPF`) |
| **8** | `8` | `262` | `F1 Trim` | Fader | `0..99` |
| **9** | `9` | `263` | `F1 Cutoff` | Fader | `0..99` |
| **10** | `10` | `282` | `F1 Reso` | Fader | `0..99` |
| **11** | `11` | `288` | `F2 Type` | List | `0..6` (`LPF24`, `LPF12`, `HPF`, `BPF`, `BRF`, `2BPF`, `THRU`) |
| **12** | `12` | `290` / `309` | `F2 Cutoff` / `F2 Reso` / `F2 Trim` | Faders (`12`, `24`, `25`) | `0..99` |

### Control Set 2 — Selected Filter Cutoff/Resonance Mod & Key Track (Rows 3–4)
- **Slot 13 (`FILTER SELECT`):** Selects `Filter 1` or `Filter 2`.
- **Slots 14..23:** `Cutoff EG Src` (`266/293`), `Cutoff EG Int` (`267/294`), `EG Vel Int` (`268/295`), `Cut Mod1 Src/Int/Ctrl/CtrlInt` (`269..272 / 296..299`), `Cut Mod2 Src/Int` (`273..274 / 300..301`), `KeyTrk CtrKey/LoSlp/HiSlp` (`279..281 / 306..308`), and `Reso Mod1/Mod2` (`283..286 / 310..313`).

### Control Set 3 — Conditional `2BPF` Filter-B Drawer (Rows 5–6, Visible Only When `Type == 2BPF`)
- **Slots 29..36:** `Cutoff-B` (`264/291`), `EG Int-B` (`275/302`), `EG Vel Int-B` (`276/303`), `Mod1 Int-B` (`277/304`), `Mod2 Int-B` (`278/305`), `KeyTrk LoSlp-B` (`287/314`), `KeyTrk HiSlp-B` (`265/292`).
