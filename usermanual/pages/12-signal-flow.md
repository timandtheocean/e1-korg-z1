# Page 12 — Interactive Signal Flow Diagram & Routing Visualizer

[⬅ Back to User Manual Index](../README.md)

- **Source Folder:** [`e1/z1-signalflow/`](../../e1/z1-signalflow/)
- **Files:** [`README.md`](../../e1/z1-signalflow/README.md) | [`draw-signal-flow.lua`](../../e1/z1-signalflow/draw-signal-flow.lua) | [`signalflow.png`](../../e1/z1-signalflow/signalflow.png)

> 📸 **[Reference Diagram: `../../e1/z1-signalflow/signalflow.png`]**
> ![Korg Z1 Signal Flow Reference](../../e1/z1-signalflow/signalflow.png)
>
> 🎬 **[Video Placeholder: `../media/12-signal-flow.mp4`]**
> *Add short video showing the Signal Flow diagram updating when toggling OSC/Sub/Noise switches, Filter Serial/Parallel routing, and Feedback.*

---

## 1. Overview

The **Signal Flow Visualizer** ([`draw-signal-flow.lua`](../../e1/z1-signalflow/draw-signal-flow.lua)) renders a `508 × 152 px` graphical block diagram of the current Korg Z1 Program architecture directly on the Electra One mk2 screen.

---

## 2. Visualized Signal Path Blocks

```mermaid
flowchart LR
    subgraph OSC["1. OSC SECTION"]
        O1["OSC 1"]
        O2["OSC 2"]
        SUB["SUB"]
        NS["NOISE"]
    end
    subgraph MIX["2. MIXER"]
        M["MIX\n(Out 1 / Out 2)"]
    end
    subgraph FLT["3. FILTER SECTION"]
        F1["Filter 1\n(LPF/HPF/BPF/2BPF)"]
        F2["Filter 2\n(LPF/HPF/BPF/THRU)"]
    end
    subgraph AMP["4. AMP SECTION"]
        A1["AMP 1"]
        A2["AMP 2"]
    end
    PAN["5. PAN"]
    subgraph FX["6. FX SECTION"]
        FX1["FX 1"]
        FX2["FX 2"]
        MFX["M.FX / EQ"]
    end

    O1 & O2 & SUB & NS --> M
    M --> F1 & F2
    F1 --> A1
    F2 --> A2
    A1 & A2 --> PAN
    PAN --> FX1 --> FX2 --> MFX
    PAN -. "7. Global Feedback Loop" .-> M
```

### Dynamic Visual States
1. **OSC Section (`OSC 1`, `OSC 2`, `SUB`, `NOISE`):** Highlighted when the corresponding Mixer Output Switch (`IDs 254..257`) is `ON`; dimmed (`light grey`) when muted.
2. **Filter 1 & Filter 2 (`Serial` / `Parallel` / `Indiv`):** Displays the active filter topology and highlights the selected filter mode (`LPF24`, `LPF12`, `HPF`, `BPF`, `BRF`, `2BPF`, `THRU`).
3. **Amp 1 & Amp 2:** Reflects serial vs. parallel/individual routing from Filter 1 and Filter 2.
4. **Global Post-Amp Feedback Loop:** Drawn in amber along the bottom return path (`PAN` $\rightarrow$ `MIX`); solid when Feedback Out 1/2 (`ID 248` / `ID 251`) is active, dimmed when `0`.
5. **FX Chain (`FX1` $\rightarrow$ `FX2` $\rightarrow$ `M.EQ / Master FX`):** Highlights active effect processors and dims bypassed (`Off`) blocks.
