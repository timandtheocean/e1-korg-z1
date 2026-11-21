# Page 7: 5-Channel Dual-Bus Mixer (`Mixer`)

The Korg Z1 features a dual-bus voice mixer that lets you route five distinct audio sources independently into **Filter 1 Bus (`F1`)** and **Filter 2 Bus (`F2`)**:
1. **OSC 1**
2. **OSC 2**
3. **Sub OSC**
4. **Noise Generator**
5. **Post-Amp Feedback** (loops the output of the voice back into the filters for warm saturation or self-oscillating growl)

The **Mixer** page gives you hands-on faders, mute buttons, modulation routings, and a **live graphical dual-bus level meter** for all five channels simultaneously.

---

## Screen Layout Overview

Columns 1–5 represent the five sound sources side by side, while Column 6 displays the live visual mixer meters:

```
+----------------+----------------+----------------+----------------+----------------+----------------+
|     OSC 1      |     OSC 2      |    SUB OSC     |     NOISE      |    FEEDBACK    |  LIVE METERS   |
|    (Col 1)     |    (Col 2)     |    (Col 3)     |    (Col 4)     |    (Col 5)     |    (Col 6)     |
+----------------+----------------+----------------+----------------+----------------+----------------+
| [ OSC1 -> F1 ] | [ OSC2 -> F1 ] | [ Sub  -> F1 ] | [Noise -> F1 ] | [ Fdbk -> F1 ] | +------------+ |
| [ OSC1 -> F2 ] | [ OSC2 -> F2 ] | [ Sub  -> F2 ] | [Noise -> F2 ] | [ Fdbk -> F2 ] | | F1/F2 Bars | |
| [OSC1 F1 ModS] | [OSC2 F1 ModS] | [Sub F1 ModS ] | [Nois F1 ModS] | [FdbkMod Src ] | | for all 5  | |
| [OSC1 F1 ModI] | [OSC2 F1 ModI] | [Sub F1 ModI ] | [Nois F1 ModI] | [FdbkF1 ModI ] | | channels   | |
| [OSC1 F2 ModS] | [OSC2 F2 ModS] | [Sub F2 ModS ] | [Nois F2 ModS] | [FdbkF2 ModI ] | +------------+ |
| [OSC1 F1 Mute] | [OSC2 F1 Mute] | [Sub F1 Mute ] | [Nois F1 Mute] | [Fdbk F1 Mute] | [All F2 Mute ] |
+----------------+----------------+----------------+----------------+----------------+----------------+
```

---

## 1. Dual-Bus Send Levels (`-> F1` & `-> F2`, Rows 1–2)

- **Row 1 (`-> F1`, `0`–`99`)**: Controls how much of each sound source is sent into **Filter 1**.
- **Row 2 (`-> F2`, `0`–`99`)**: Controls how much of each sound source is sent into **Filter 2**.

> [!TIP]
> **Parallel vs. Split Filtering:**
> - To process a source through both filters in parallel, raise both its `-> F1` and `-> F2` faders.
> - To split oscillators into completely separate signal chains (for example, sending **OSC 1** through a Low-Pass Filter panned left and **OSC 2** through a Band-Pass Filter panned right), raise `OSC1 -> F1` (`F2 = 0`) and `OSC2 -> F2` (`F1 = 0`).

---

## 2. Dynamic Level Modulation (Rows 3–5)

Every channel can have its Filter 1 and Filter 2 send levels animated in real time by envelopes, LFOs, velocity, key tracking, or performance knobs:

- **OSC 1, OSC 2, Sub OSC & Noise (Cols 1–4)**:
  - **Row 3 (`F1 ModSrc`) & Row 4 (`F1 ModInt`)**: Selects a modulation source and depth (`-99` to `+99`) for the channel's **Filter 1** send level.
  - **Row 5 (`F2 ModSrc` / `F2 ModInt`)**: Controls modulation for the channel's **Filter 2** send level.
- **Post-Amp Feedback (Col 5)**:
  - Uses a shared **Fdbk Mod Src** (Row 3) with independent modulation intensities for **Filter 1 (`FdbkF1 ModInt`, Row 4)** and **Filter 2 (`FdbkF2 ModInt`, Row 5)**.

---

## 3. Channel Bus Mute Buttons (Row 6)

Want to solo an oscillator or hear what Filter 2 sounds like by itself without losing your carefully balanced fader levels?

- **Channel Mute Buttons**: Temporarily mute any channel bus send (`0` to the Z1) while remembering your original fader value in memory. Tap the mute button again to restore the exact previous level.
- **Visual Mute Dimming**: When a bus send is muted, its corresponding bar in the **Live Meters** graphic dims automatically so you can see at a glance which buses are active.

---

## 4. Live Graphical Mixer Meters (Column 6)

The custom visualizer in Column 6 displays paired side-by-side vertical bar meters (`F1` and `F2`) for all five channels (`OSC 1`, `OSC 2`, `Sub`, `Noise`, and `Feedback`). As you move any level fader, toggle any mute button, or load a patch from the Z1, the bar graphs update immediately to give you a clear visual mix balance.
