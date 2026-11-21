# Korg Z1 Electra One mk2 Scripts & Build Tools

Documentation for all build, verification, upgrade, and mock scripts in `/home/timbos/src/Z1/e1`.

---

## Quick Start (Build & Verify Workflow)

Never edit [preset.z1.json](file:///home/timbos/src/Z1/e1/preset.z1.json) or [main.z1.lua](file:///home/timbos/src/Z1/e1/main.z1.lua) directly—they are generated from the individual `z1-*` module folders.

```bash
cd /home/timbos/src/Z1/e1

# 1. Merge the 10 active z1-* modules into preset.z1.json + main.z1.lua
#    (the same two files are also copied to ../dist/ for download)
./merge_z1_presets.py

# 2. Check Lua 5.4 syntax of the generated script
luac5.4 -p main.z1.lua

# 3. Run full behavioral & SysEx verification against the Lua mock
./verify_merge.py -v

# 4. Validate preset JSON schema/structure (modules + merged preset)
./upgrade_presets_v3.py --check
./upgrade_presets_v3.py --check preset.z1.json
```

### Requirements
- **Python 3.6+** (standard library only)
- **Lua 5.4** (`lua5.4` and `luac5.4` in `PATH`—required for Lua 5.4 bitwise operators `&`, `|`, `<<`, `>>` used throughout the scripts; system Lua 5.1 will fail syntax checks)

---

## Repository Layout

### Active Merged Modules (12 Pages on Electra One mk2)

| Page(s) | Page Title(s) | Module Folder | Callback Prefix |
| :---: | :--- | :--- | :---: |
| `1` | `Utility` | `z1-base/` | `bs_` |
| `2` | `Common & Arp` | `z1-common-arp/` | `ca_` |
| `3–5` | `OSC common`, `OSC1: Standard OSC`, `OSC2: Standard OSC` | `z1-osc-common/` | `oc_` |
| `6` | `Sub, Noise & Common` | `z1-sub-noise/` | `sn_` |
| `7` | `Mixer` | `z1-mix/` | `mx_` |
| `8` | `Filters` | `z1-filter/` | `fl_` |
| `9` | `Amp & Mod` | `z1-mod/` | `md_` |
| `10` | `Envelopes` | `z1-eg/` | `eg_` |
| `11` | `LFO1-4` | `z1-lfo/` | `lf_` |
| `12` | `FX & EQ` | `z1-fx/` | `fx_` |

### Non-Merged / Reference Folders & Generated Artifacts
- `z1-osc1/`, `z1-osc2/` — Standalone single-page OSC1/OSC2 presets (excluded from the default 12-page merge because `z1-osc-common/` already hosts Pages `4` and `5`, and Electra One mk2 allows at most 12 pages).
- `z1-filterwidget/` — Electra One Editor widget reference (`preset.json`, `preset.lua`, `schemaVersion: 3`) whose custom graphical Cutoff/Resonance curve drawing logic was adapted into `z1-filter/`.
- [preset.z1.json](file:///home/timbos/src/Z1/e1/preset.z1.json) & [main.z1.lua](file:///home/timbos/src/Z1/e1/main.z1.lua) — Generated merged Electra One v3 preset and combined Lua 5.4 script.

---

## Script Reference

### 1. [merge_z1_presets.py](file:///home/timbos/src/Z1/e1/merge_z1_presets.py)

Merges the standalone `z1-*/preset.json` and `z1-*/main.lua` modules into a single Electra One mk2 preset ([preset.z1.json](file:///home/timbos/src/Z1/e1/preset.z1.json)) and Lua script ([main.z1.lua](file:///home/timbos/src/Z1/e1/main.z1.lua)) without modifying any module source files.

#### What it does
- **JSON Merging & ID Remapping**:
  - Assigns sequential page IDs (`1..12` max on mk2).
  - Renumbers controls and groups into one unified ID space (`1..864` max), ensuring no collisions.
  - Renumbers virtual parameters (`type: "virtual"`) uniquely per module so controls on different pages never alias in `parameterMap`.
  - Extracts both JSON overlays and runtime `overlays.create(...)` definitions (by probing each module's `main.lua` in `lua5.4`), deduplicates identical item lists, and emits only statically referenced overlays (`1..42`) in `preset.z1.json` (dynamic-only overlays are created at runtime in Lua only if `preset.getOverlay(gid)` returns `nil`).
  - Rewrites callback and formatter names with module prefixes (`mx_onMixParam`, etc.), truncating or aliasing names exceeding Electra One's 20-character limit (`bs_f3`, etc.) and deduplicating identical callback bodies across modules.
  - Enforces/warns on firmware v5.0 mk2 limits (`MAX_PAGE_ID = 12`, `MAX_CONTROL_GROUP_ID = 864`, `MAX_CONTROLS = 432` for Lua `controls.create`, `MAX_OVERLAY_ID = 255`, `MAX_PARAMETER_NUMBER = 16383`, `MAX_FUNCTION_NAME = 20`, `MAX_FUNCTION_NAMES = 255`, `MAX_FILE_SIZE = 1228800`).
- **Lua Environment Isolation & Runtime Integration**:
  - Wraps each module's `main.lua` inside its own Lua `_ENV` sandbox (`__makeEnv`) so module-local IDs and globals do not collide.
  - Translates local $\leftrightarrow$ merged IDs for `preset.getControl`, `preset.getGroup`, `controls.get`, `groups.get`, `overlays.get`, `overlays.create`, `pages.get`, `pages.display`, `:getId()`, and `:setOverlayId()`.
  - Promotes & deduplicates shared top-level tables (`MODSRC1`, `MODSRC2`, `NOTE_NAMES`) and identical global helpers (`buildParamChangeBody`).
  - Chains module lifecycle/event hooks (`preset.onLoad`, `preset.onReady`, `preset.onZ1Dump`, `preset.onZ1Param`, `midi.onSysex`, `midi.onProgramChange`, `timer.onTick`, etc.).
  - Wraps `preset.onLoad`, `preset.onReady`, and `preset.onZ1Dump` in ref-counted `window.stop()` / `window.resume()`, suppresses control callback SysEx echoes during `onZ1Dump`/`onZ1Param` via `__z1SyncDepth`, and intercepts outgoing `41H` SysEx parameter changes (`__trackOutgoingSysex`) to feed `z1-base`'s Undo/Redo tracker.

#### Usage & Options
```bash
# Default build -> writes preset.z1.json (minified) + main.z1.lua
./merge_z1_presets.py

# Write indented JSON (useful for inspecting diffs)
./merge_z1_presets.py --pretty

# Strip Lua comments from main.z1.lua (smaller file size)
./merge_z1_presets.py --strip-comments

# Dry-run: validate, print ID/callback summary table, write nothing
./merge_z1_presets.py --check

# Custom output paths, preset name, or module subset/order
./merge_z1_presets.py -o custom.json --lua-output custom.lua --name "Korg Z1" \
    --modules z1-base z1-common-arp z1-filter
```

| Flag | Default | Description |
| :--- | :--- | :--- |
| `--root DIR` | Script directory | Directory containing the `z1-*` module folders |
| `--modules M ...` | 10 default modules | Ordered list of module folders to merge |
| `-o`, `--output FILE` | `preset.z1.json` | Output merged JSON preset path |
| `--lua-output FILE` | `main.z1.lua` | Output merged Lua script path |
| `--name STR` | `"Korg Z1"` | Top-level preset name (max 20 chars) |
| `--project-id STR` | Hash from `--modules` | Custom Electra One `projectId` |
| `--pretty` | Off | Format output JSON with 2-space indentation |
| `--strip-comments` | Off | Strip Lua comments from merged `main.z1.lua` |
| `--check` | Off | Analyze and print summary without writing files |

---

### 2. [verify_merge.py](file:///home/timbos/src/Z1/e1/verify_merge.py)

Automated regression and behavioral equivalence test suite for [preset.z1.json](file:///home/timbos/src/Z1/e1/preset.z1.json) and [main.z1.lua](file:///home/timbos/src/Z1/e1/main.z1.lua). Run this after every `./merge_z1_presets.py` rebuild.

#### What it tests
1. **`overlays`**: Verifies sequential overlay IDs, zero empty/placeholder items, zero duplicate overlay item lists, and exact item matching for every control's `overlayId`.
2. **`lua-dedup`**: Confirms `MODSRC1`, `MODSRC2`, and `NOTE_NAMES` are emitted only once in `main.z1.lua` and duplicate callbacks are reused.
3. **Standalone vs. Merged Parity (all 10 modules)**:
   - Executes every module's standalone `preset.json` + `main.lua`, and then the merged `preset.z1.json` + `main.z1.lua`, inside `lua5.4` via [tools/electra_mock.lua](file:///home/timbos/src/Z1/e1/tools/electra_mock.lua).
   - Invokes every control's `function` and `formatter` callback across its value range (`min`, `max`, midpoint, `offValue`, `onValue`), plus `paint` callbacks, incoming SysEx (`z1-base`), and 20 timer ticks (`z1-base`).
   - Also tests with `overlayId` stripped from visible controls in JSON to verify `preset.onReady()` binds overlays at runtime even if the Web Preset Editor strips/renumbers them.
4. **`eg-filter-sync`**: Verifies bidirectional synchronization of `EG1..EG4` & `Amp EG` curves and Start Levels between Page 10 (`z1-eg`) and Page 8 (`z1-filter` Assigned Cutoff EG view).
5. **`prog-dump-parse`**: Feeds a full 576-byte Korg 7-to-8-bit packed `40H` Program Dump + `41H` Parameter Change via `midi.onSysex` and verifies controls/dynamic pages across all 12 pages update cleanly with 0 errors and 0 SysEx echoes.
6. **`backup-undo`**: Verifies knob coalescing, cross-page Undo/Redo SysEx & UI state reconstruction (including undoing back across preset dumps), 30-second preset-switch Backup hold across multiple switches, Recover Backup transmission, and 30-second auto-update expiration.

#### Usage & Options
```bash
# Run full suite (compact pass/fail output)
./verify_merge.py

# Verbose output (prints unified diffs on failures and mock-missing API notes)
./verify_merge.py -v

# Verify custom merged output files
./verify_merge.py --merged custom.json --lua custom.lua -v
```

| Flag | Default | Description |
| :--- | :--- | :--- |
| `-v`, `--verbose` | Off | Print unified trace diffs and missing-mock diagnostics |
| `--merged FILE` | `preset.z1.json` | Path to merged preset JSON (relative to repo root) |
| `--lua FILE` | `main.z1.lua` | Path to merged Lua script (relative to repo root) |
| `--modules M ...` | `mz.DEFAULT_MODULES` | Module list to compare against the merged preset |

---

### 3. [tools/electra_mock.lua](file:///home/timbos/src/Z1/e1/tools/electra_mock.lua)

Standalone minimal Electra One **firmware 5.x** Lua API runtime mock executed under `lua5.4` by `verify_merge.py`. It is not meant to be run directly with no globals—`verify_merge.py` prepends `PRESET`, `SCRIPT`, `TESTS`, `IDMAP`, `PAGEMAP`, `SYSEX_IN`, `TICKS`, and `CHECK_DUP_OV`, then calls `dofile("tools/electra_mock.lua")`.

#### What it emulates
- Preset DOM lookup & mutation: `preset`, `controls`, `groups`, `pages`, `devices`, `overlays` (including `getIndexByValue`, `getValueByIndex`, `getLabel`, `getLength`, and duplicate-overlay detection).
- Control, Value, and Message objects (`getValue`, `updateValue`, `setValue`, `isSet`, `setRange`, `setOverlayId`, `setVisible`, `setName`, `setColor`, `setBounds`, `setPaintCallback`, `setTouchCallback`, `setPotCallback`, `setSwitchCallback`).
- Hardware stubs & logging: `midi`, `timer`, `window`, `info`, `recall`/`recallJson`, and `graphics` (including `graphics.dim`), recording SysEx (`SX`), formatters (`FMT`), page switches (`PAGE`), and normalized control/group state snapshots (`STATE`).

---

### 4. [upgrade_presets_v3.py](file:///home/timbos/src/Z1/e1/upgrade_presets_v3.py)

Validates Electra One preset JSON structure and upgrades v2 `preset.json` files to v3 (changing `"version": 2` to `3` while keeping formatting/escaping intact and backing up originals to `preset.json.v2.bak`). Automatically skips non-preset folders (`z1-signalflow`, `z1-filterwidget`, `z1-mixerwidget`) and editor `schemaVersion` files. See [upgrade_presets_v3.md](file:///home/timbos/src/Z1/e1/upgrade_presets_v3.md) for full details.

#### Usage & Options
```bash
# Validate all z1-*/preset.json files without modifying anything (exit code 1 on error)
./upgrade_presets_v3.py --check

# Validate the merged preset as well
./upgrade_presets_v3.py --check preset.z1.json

# Preview upgrades without writing
./upgrade_presets_v3.py --dry-run

# Upgrade all v2 module presets (writes preset.json.v2.bak unless --no-backup)
./upgrade_presets_v3.py
```

| Flag | Default | Description |
| :--- | :--- | :--- |
| `files...` | `*/preset.json` under `--root` | Specific preset JSON files to check or upgrade |
| `--root DIR` | Script directory | Root directory scanned when no `files` are passed |
| `-n`, `--dry-run` | Off | Report status without modifying any files |
| `--check` | Off | Validation-only mode; exits `1` if errors are found |
| `--no-backup` | Off | Skip creating `.v2.bak` backup files |
| `--force` | Off | Upgrade `2 -> 3` even if validation errors occur |

---

### 5. [merge_presets.py](file:///home/timbos/src/Z1/e1/merge_presets.py) *(Legacy Prototype)*

Early JSON-only preset combiner kept in the repository for reference. **Do not use this to build the Z1 preset**: it does not merge or sandbox `main.lua`, handle runtime overlays (`overlays.create`), prefix callbacks, deduplicate tables/functions, or enforce the 12-page/ID limits. Always use [merge_z1_presets.py](file:///home/timbos/src/Z1/e1/merge_z1_presets.py) instead.

```bash
# Legacy syntax only (for reference)
python3 merge_presets.py <output.json> <input1.json> <input2.json> ...
```

---

### 6. Module Test Suites (`z1-*/main-tests.lua`)

Each `z1-*` module folder contains a `main-tests.lua` file written for Electra One's built-in unit test runner (`test.case`, `test.turn`, `test.sent`, `test.eq`). These cover module-level SysEx byte formatting and UI state behavior when running a single module in Electra One's preset test harness.
