# `check-params.lua` — Korg Z1 MIDI Implementation Coverage Checker

[`check-params.lua`](check-params.lua) is a standalone Lua 5.4 verification script that audits Electra One (`preset.json` + `main.lua`) presets against the official Korg Z1 MIDI Implementation reference files in [`Z1_MIDIimp/`](Z1_MIDIimp/).

Instead of relying on static regex matching, `check-params.lua` runs a lightweight **Electra One mk2 runtime simulator**:
1. It parses every parameter table, footnote list, and MIDI message specification in `Z1_MIDIimp/*.TXT`.
2. It loads each target `preset.json` and executes its companion `main.lua` (`preset.onLoad()`, `preset.onReady()`, overlays, controls, and callbacks).
3. It exercises all controls, `dx7envelope` handles (`l1..l4`, `r1..r4`), and dynamic mode/model/type/tab selectors (OSC1/OSC2 synthesis models `0..12`, FX1/FX2/MasterFX effect types, Filter 1/2 & 2BPF mode, EG1..4 & Amp EG selectors, Pitch/Amp Mod banks, and ASCII character positions).
4. It intercepts every outbound Korg Z1 Parameter Change SysEx message (`F0 42 3g 46 41 <group> <pl> <pm> <vl> <vm> F7`) and overlay lookup (`overlay:getValueByIndex()`) to determine which parameters and parameter lists are implemented and which are still open.

---

## Requirements

- **Lua 5.4** (`lua5.4`)
- Standard Z1 MIDI implementation text files in `Z1_MIDIimp/`:
  - [`Z1_MIDIimp/PROG_PRM.TXT`](Z1_MIDIimp/PROG_PRM.TXT) — Program Parameters (`Group 01`, `ExID = 0..5`) & Parameter Lists (`[*1]`..`[*13]`, `Mod.Source List 1 & 2`)
  - [`Z1_MIDIimp/MULT_PRM.TXT`](Z1_MIDIimp/MULT_PRM.TXT) — Multi Set Parameters (`Group 03`, `ExID = 0`)
  - [`Z1_MIDIimp/PAT_PRM.TXT`](Z1_MIDIimp/PAT_PRM.TXT) — Arpeggio Pattern Parameters (`Group 02`, `ExID = 0`)
  - [`Z1_MIDIimp/GLBL_PRM.TXT`](Z1_MIDIimp/GLBL_PRM.TXT) — Global & MIDI Parameters (`Group 00`, `ExID = 0..3`)
  - [`Z1_MIDIimp/Z1_MIDIimp.TXT`](Z1_MIDIimp/Z1_MIDIimp.TXT) — MIDI Implementation (Channel CC, Arpeggio NRPNs `*1`, MixerSW CC#83 `*2`, and SysEx Function `41H`)

---

## Usage

```bash
lua5.4 check-params.lua [options] [preset.json | module-dir ...]
```

### 1. Check all presets across `e1/*/preset.json` (default)

When run with no path arguments, `check-params.lua` scans all `e1/*/preset.json` modules and reports combined coverage across the entire project:

```bash
lua5.4 check-params.lua
```

### 2. Check a single preset (or a specific set of presets)

Pass one or more `preset.json` paths (or module directories containing `preset.json`) to audit only those presets:

```bash
# Check only the Filter preset
lua5.4 check-params.lua e1/z1-filter/preset.json

# Or pass the module directory directly
lua5.4 check-params.lua e1/z1-filter

# Check OSC1 and OSC2 together
lua5.4 check-params.lua e1/z1-osc1/preset.json e1/z1-osc2/preset.json
```

### 3. Show all open (unimplemented) parameter IDs (`-v` / `--verbose`)

By default, `PROG_PRM.TXT` open parameters are always listed in full, while large unimplemented tables (`MULT_PRM.TXT`, `PAT_PRM.TXT`, `GLBL_PRM.TXT`) are summarized by section. Pass `-v` or `--verbose` to print every individual open parameter ID across all files:

```bash
lua5.4 check-params.lua --verbose
```

---

## Understanding the Report

### Section 1: `PROG_PRM.TXT` — Program Parameters (`Group = 01`)

Reports coverage in two ways:
1. **Table Parameter IDs (`1..1039`)**:
   - Counts the **`953` active parameter rows** in `PROG_PRM.TXT` (excluding `41` `[Reserved]` entries).
   - Shared tables in `PROG_PRM.TXT` (such as `OSC1/2 Model Parameters` `464..754` and `FX1/FX2 Parameters` `800..1003`) appear once in the document table.
2. **Breakdown by `ExID` (`0..5`, All Addressable Program Parameters)**:
   - Expands shared ranges across their hardware `ExID` namespaces:
     - `ExID 0` (`1..463`): Program Core (`459` active parameters)
     - `ExID 1` (`464..754`): OSC1 Models `0..12` (`254` active parameters)
     - `ExID 2` (`464..615`): OSC2 Models `0..8` (`152` active parameters)
     - `ExID 3` (`800..1003`): FX1 Algos `0..14` (`204` active parameters)
     - `ExID 4` (`800..951`): FX2 Algos `0..10` (`152` active parameters)
     - `ExID 5` (`1004..1039`): Master FX `0..2` (`36` active parameters)
   - Total addressable Program parameters = **`1257`**.

### Section 2: `PROG_PRM.TXT` — Parameter Lists & Footnote Tables

Audits all 15 enumerated lists defined in `PROG_PRM.TXT`:
- `[*1]` Program Category (`18` items: `0..17`)
- `[*2]` Scale Type (`11` items: `0..10`)
- `[*3]` LFO Wave Form (`18` items: `0..17`)
- `[*4]` Oscillator Type (`13` items for OSC1 `0..12`; `9` items for OSC2 `0..8`)
- `[*5]` Effect1&2 Type (`15` items for FX1 `0..14`; `11` items for FX2 `0..10`)
- `[*6]` Master Effect Type (`3` items: `0..2`)
- `[*7]` Assignable SW1 Function List (`8` items: `0..7`)
- `[*8]` Assignable SW2 Function List (`8` items: `0..7`)
- `[*9]` Assignable F.SW Function List (`13` items: `0..12`)
- `[*10]` Assignable Pedal Function List (`6` items: `0..5`)
- `[*11]` PE (Performance Editor) List (`231` items: `0..230`, mapped across `20` Knob 1..5 Dest parameters)
- `[*12]` Brass Model Instrument Types (`6` items: `0..5`)
- `[*13]` Reed Model Instrument Types (`17` items: `0..16`)
- `List1` Modulation Source List 1 (`49` items: `0..48`)
- `List2` Modulation Source List 2 (`36` non-contiguous items: `0`, `11..45`)

Each list is reported with one of four statuses:
- **`IMPL (List)`**: Implemented as an Electra One `list` overlay and wired to all target parameters.
- **`PARTIAL`**: Wired to only a subset of its target parameters.
- **`NUM FADER`**: All target parameters are implemented as numeric faders (`0..N`) rather than named `list` overlays (used for the 231-entry `[*11]` PE List to preserve Electra One memory).
- **`OPEN`**: Not yet implemented in the target preset(s).

### Sections 3–5: `MULT_PRM.TXT`, `PAT_PRM.TXT`, `GLBL_PRM.TXT`

Reports implemented vs. open parameters and footnote lists for:
- **`MULT_PRM.TXT`** (`Group = 03`, `ExID = 0`): `199` active (`12` reserved) Multi Set parameters and `6` footnote lists (`[*1]`..`[*6]`).
- **`PAT_PRM.TXT`** (`Group = 02`, `ExID = 0`): `241` active (`7` reserved) Arpeggio Pattern parameters and `2` footnote lists (`[*1]`..`[*2]`).
- **`GLBL_PRM.TXT`** (`Group = 00`, `ExID = 0..3`): `878` active (`1` reserved) Global & MIDI parameters and `1` footnote list (`[*1]`).

### Section 6: `Z1_MIDIimp.TXT` — Channel CC / NRPN / SysEx

Summarizes coverage of `Z1_MIDIimp.TXT`:
- **Recognized Channel CCs (Section 2-1)**: `61` defined CCs.
- **`[*1]` Arpeggio NRPNs (`00 01..00 06`)**: `6` defined NRPNs (and notes how many are covered via SysEx IDs `374..378`).
- **`[*2]` MixerSW Bitmask (`CC#83`)**: `4` switches (covered via SysEx IDs `254..257`).
