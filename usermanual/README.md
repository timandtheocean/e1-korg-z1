# Korg Z1 Controller for Electra One mk2 — User Manual

Welcome to the user manual for the **Korg Z1 Controller Preset** on the **Electra One mk2**.

The Korg Z1 is one of the deepest polyphonic synthesizers ever built, combining 13 physical-modeling and MOSS synthesis algorithms with dual multi-mode filters, five multi-stage envelopes, four LFOs, a dual-bus mixer with post-amp feedback, five multi-target performance knobs, microtonal tuning scales, and dual stereo effects. On the hardware front panel, exploring that depth means navigating dozens of menu pages on a small LCD.

This Electra One mk2 preset brings the entire Korg Z1 voice architecture to your fingertips across **12 thoughtfully organized touchscreen and knob pages**—complete with live graphical visualizers, dynamic controls that morph to match your active oscillator and effect models, automatic patch synchronization, patch-loss protection, undo/redo, and built-in preset libraries for oscillators, effects, and microtonal scales.

---

## Quick Start Guide

### 1. Connecting Your Korg Z1
1. Connect **MIDI OUT 1** on the Electra One mk2 to **MIDI IN** on the Korg Z1.
2. Connect **MIDI OUT** on the Korg Z1 to **MIDI IN 1** on the Electra One mk2.
3. On the Korg Z1 (`GLOBAL` mode), make sure **System Exclusive (Exclusive)** reception and transmission are set to **ENA (Enabled)**, and write protection is turned off if you want to edit microtonal user scales.

### 2. Automatic Connection & MIDI Channel Discovery
You do not need to configure the Z1's MIDI channel manually:
- As soon as the preset loads, the Electra One **automatically searches for your Korg Z1** and retries every **5 seconds** until the Z1 responds.
- Once the Z1 replies, the controller automatically locks onto the Z1's global MIDI channel.
- You can also tap **Handshake ID** on the [Utility](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/01-base-utility.md) page at any time to re-verify the connection.

### 3. Syncing Patches with the Z1
- Tap **Patch Req** on the [Utility](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/01-base-utility.md) page to pull the currently active program from the Z1 onto the Electra One screen.
- Turn on **PC Patch Req** on the [Utility](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/01-base-utility.md) page if you want the Electra One to **automatically request and display the new patch every time you change programs on the Z1**.

---

## Key Features at a Glance

- **Automatic Handshake & Sync (`PC Patch Req`)**: Automatically connects to your Z1 on startup and optionally syncs the full patch display whenever you switch programs on the synth.
- **30-Second Patch Protection & One-Touch Recovery**: Switching patches on the Z1 accidentally before saving? The controller holds a protected backup of your edited patch for 30 seconds after any incoming patch load. The backup is kept in memory only and is lost at power-off; Electra snapshots are **disabled**. Tap **Recover Backup** on the [Utility](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/01-base-utility.md) page to restore your work and transmit it right back to the Z1.
- **16-Step Undo & Redo**: Experiment freely (history is kept in memory only; Electra snapshot slots are **disabled** because saving a snapshot freezes firmware 5.1.0 for several seconds) with **Undo** and **Redo** buttons on the [Utility](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/01-base-utility.md) page. Sweeping a knob smoothly groups into a single undo step.
- **Dynamic Morphing Oscillator & Effect Pages**: The [OSC 1](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/02-osc1.md), [OSC 2](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/03-osc2.md), and [FX & EQ](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/10-effects-eq.md) pages automatically relabel, re-range, and show or hide controls to match your active synthesis model or effect algorithm.
- **Visual Distinction for Modulation Depth**: Across every page, **modulation intensity (`Int`) controls use thin horizontal bars**, making it easy to distinguish modulation depths from core sound parameters at a glance.
- **Three Built-In Sub-Preset Libraries**:
  - **OSC Preset Library** ([OSC Common](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/03b-osc-common.md)): Save, rename, load, and delete up to **8 presets per oscillator model** (shared between OSC 1 and OSC 2) plus **25 Dual-Oscillator (`Both OSCs`) presets** that store complete two-oscillator combinations.
  - **FX Preset Library** ([FX & EQ](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/10-effects-eq.md)): Save and recall up to **8 presets per effect algorithm** (shared between FX 1 and FX 2) plus **25 full FX Chain presets** (FX 1 + FX 2 + Master Send + 2-Band EQ).
  - **Microtonal Tuning Preset Library** ([Utility](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/01-base-utility.md)): Store and recall up to **16 custom named microtonal scales** on the controller.
- **Rich Interactive Touch Visualizers**:
  - **5-Octave Microtonal Piano Keyboard** (`C2..C7`) with touch key selection and color-coded cent deviation bars on [Utility](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/01-base-utility.md).
  - **Live Dual-Bus Mixer Meters** with mute indicators on [Mixer](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/05-mixer.md).
  - **Interactive Filter Response Curves** and a linked **Cutoff Envelope Editor** on [Filters](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/06-filter.md).
  - **Five Touch-Editable 8-Stage Envelope Graphs** on [Envelopes](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/07-envelopes.md).
  - **Four Real-Time LFO Waveform Displays** illustrating all 18 Z1 wave shapes, DC offset, and fade-in ramps on [LFO 1–4](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/08-lfos.md).

---

## Complete Page Guide

The preset is organized into **12 pages** matching the natural signal flow and editing workflow of the Korg Z1:

| Page # | Page Name on Screen | Manual Guide | What You Can Control |
| :---: | :--- | :--- | :--- |
| **1** | `Utility` | [01 — Utility, Patch Sync & Microtonal Tuning](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/01-base-utility.md) | Handshake, Patch Request, Auto Program-Change Sync (`PC Patch Req`), Backup & Recovery, Undo/Redo, Patch Name Editor, 5-Octave Microtonal Scale Editor & Tuning Preset Library |
| **2** | `Common & Arp` | [11 — Voice Common, Key Scale & Arpeggiator](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/11-common-arp.md) | Poly/Mono Voice Assign, Unison & Detune, Patch Scale Type & Key, Random Pitch, Transpose, Arpeggiator Gate/Velocity, Category & Program Name banner |
| **3** | `OSC common` | [03b — OSC Common & Oscillator Preset Library](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/03b-osc-common.md) | Side-by-side OSC 1 & OSC 2 Pitch, Tune, Pitch Slope, Pitch EG/LFO/Mod routing, Quick Page Jumps, and the **OSC Preset Library** (`OSC 1`, `OSC 2`, and `Both OSCs`) |
| **4** | `OSC1` | [02 — Oscillator 1 (All 13 MOSS Models)](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/02-osc1.md) | Model selector and morphing parameters for all 13 OSC 1 synthesis models (Standard, Comb, VPM, Resonance, Ring/Cross/Sync, Organ, EP, Brass, Reed, Plucked, Bowed) |
| **5** | `OSC2` | [03 — Oscillator 2 (All 9 Models)](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/03-osc2.md) | Model selector and morphing parameters for all 9 OSC 2 synthesis models (Standard, Comb, VPM, Resonance, Ring/Cross/Sync, Organ, Reed) |
| **6** | `Sub, Noise & Common` | [04 — Sub Oscillator, Noise & Portamento](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/04-sub-noise.md) | Sub Oscillator wave, Noise Generator with dedicated multimode Noise Filter, Pitch Bend range, and Portamento settings |
| **7** | `Mixer` | [05 — 5-Channel Dual-Bus Mixer](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/05-mixer.md) | Dual-bus routing (Filter 1 & Filter 2 buses) for OSC 1, OSC 2, Sub, Noise, and Post-Amp Feedback with live level meters, mute toggles, and level modulation |
| **8** | `Filters` | [06 — Dual Multi-Mode Filters](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/06-filter.md) | Side-by-side Filter 1 & Filter 2 (`LPF`, `HPF`, `BPF`, `2BPF`, `BYP`), interactive response curves, linked Cutoff EG graph, and auto-appearing `2BPF` Band-B controls |
| **9** | `Amp & Mod` | [09 — Dual Amplifiers, Pan & Performance Knobs](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/09-amp-mod-pe.md) | Amp 1 & Amp 2 levels, distortion, stereo panning, OSC 1 Pitch/Pan Mod, and target assignments for **Performance Editor Knobs 1–5** |
| **10** | `Envelopes` | [07 — Five Interactive Envelopes (EG 1–4 & Amp EG)](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/07-envelopes.md) | Touch-editable 8-stage envelope graphs for Pitch/Filter/Mod EGs 1–4 and Amp EG, Start Level faders, and expandable **Reveal Modulations** drawer |
| **11** | `LFO1-4` | [08 — Quad LFOs (LFO 1–4)](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/08-lfos.md) | 4 independent LFO columns with live waveform visualizers (18 wave shapes), touch-to-select graph headers, MIDI Clock sync, key sync, and speed modulation |
| **12** | `FX & EQ` | [10 — Effects, 2-Band EQ & FX Preset Library](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/10-effects-eq.md) | FX 1 (15 algorithms), FX 2 (11 algorithms), Master Routing & 2-Band EQ, plus the **FX Preset Library** (per-algorithm presets & 25 full FX Chain presets) |
| **Ref** | *Signal Flow* | [12 — Complete Korg Z1 Signal Flow Diagram](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/12-signal-flow.md) | Visual signal path diagram showing how every oscillator, mixer bus, filter, amplifier, modulator, and effect block connects inside the Z1 |

---

## Tips for Daily Sound Design

1. **Keep `PC Patch Req` On While Browsing**: Enable **PC Patch Req** on the [Utility](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/01-base-utility.md) page so that every time you select a patch on the Z1's front panel or bank buttons, the Electra One immediately updates all 12 pages to match.
2. **Use `Backup Now` at Milestones**: Before trying a radical change—such as swapping oscillator models or loading a dual-oscillator preset—tap **Backup Now** on the [Utility](https://github.com/timandtheocean/e1-korg-z1/tree/main/usermanual/pages/01-base-utility.md) page. You can return to that exact state with a single tap on **Recover Backup**.
3. **Jump Between Oscillator Pages Instantly**: Use the **Jump OSC 1**, **Jump OSC 2**, and **OSC Common** pads on the top-right of the oscillator pages instead of opening the hardware page menu.
4. **Mix and Match Oscillator & Effect Building Blocks**: Build a personal library of favorite VPM bells, Brass models, Reed models, or stereo delay/reverb chains using the **OSC Presets** and **FX PRESETS** drawers, and drop them into any new patch in seconds.
