# Page 07 — Envelopes (EG1–EG4 & Amp EG) with Interactive `dx7envelope` Curves

[⬅ Back to User Manual Index](../README.md)

- **Source Folder:** [`e1/z1-eg/`](../../e1/z1-eg/)
- **Files:** [`preset.json`](../../e1/z1-eg/preset.json) | [`main.lua`](../../e1/z1-eg/main.lua) | [`main-tests.lua`](../../e1/z1-eg/main-tests.lua)
- **Z1 Parameters Covered:** All **95** active Envelope parameters (`IDs 31..118` for `EG1..EG4` and `IDs 333..351` for `Amp EG`, `ExID = 0`).

> 📸 **[Screenshot Placeholder: `../media/07-envelopes.png`]**
> *Add screenshots showing the 5 `dx7envelope` graphical displays and the `Reveal Modulations` bottom drawer.*
>
> 🎬 **[Video Placeholder: `../media/07-envelopes.mp4`]**
> *Add short video showing touch-editing the 8-stage envelope curves and toggling `Reveal Modulations`.*

---

## 1. Overview

The Korg Z1 provides five 9-parameter multi-stage Envelope Generators (**EG 1**, **EG 2**, **EG 3**, **EG 4**, and **Amp EG**), each with:
- **9 Envelope Shape Parameters:** `Start Level`, `Attack Time`, `Attack Level`, `Decay 1 Time`, `Break Point Level`, `Decay 2 Time`, `Sustain Level`, `Release Time`, and `Release Level` (for `EG1..4`).
- **10 Envelope Modulation Parameters:** `Level Mod Source`, `Start/Attack/Break Lvl Mod Int`, `Time Mod1 Src`, `Time Mod2 Src`, and `Attack/Decay1/Decay2/Release Time Mod Int`.

On the Electra One mk2, each of the 5 EGs is rendered using an interactive 2-slot **`dx7envelope` graphical widget** paired with its `Start Level` fader:
- **Control Set 1 (Rows 1–2):** `EG 1`, `EG 2`, and `EG 3` curve widgets + `Start Level` faders.
- **Control Set 2 (Rows 3–4):** `EG 4` and `Amp EG` curve widgets + persistent **`Amp EG` Modulation controls** (`Amp Lvl Src`, `Amp Atk/Brk LInt`, `Amp Tm Src1/2`, `Amp Atk/Dc1/Dc2/Rel TInt`).
- **Control Set 3 (Rows 5–6):** **`Reveal Modulations` Toggle Pad** (`Control 25`) + **`EG Target` Selector** (`Control 26: EG 1..EG 4`) and the 10 dynamic modulation controls (`Controls 27..36`) for the selected `EG 1..4`.

---

## 2. Z1 Envelope Parameter Mapping (`ExID = 0`)

| Envelope | Shape IDs (`Start..RelLvl`) | Level Mod IDs | Time Mod IDs | Notes |
|---|---|---|---|---|
| **EG 1** | `31..39` (9 params) | `40..43` (4 params) | `44..49` (6 params) | Default Filter 1 / Pitch / Model EG. |
| **EG 2** | `53..61` (9 params) | `62..65` (4 params) | `66..71` (6 params) | Default Filter 2 / Model EG. |
| **EG 3** | `75..83` (9 params) | `84..87` (4 params) | `88..93` (6 params) | General-purpose Modulation EG. |
| **EG 4** | `97..105` (9 params) | `106..109` (4 params) | `110..115` (6 params) | General-purpose Modulation EG. |
| **Amp EG** | `333..340` (8 params; Release Level fixed at `0`) | `342..345` (4 params) | `346..351` (6 params) | Dedicated Amplifier Envelope. |
