# design a preset for the Korg Z1 MOSS synthesizer for the E1 (electraone)
Debian linux and vcode, lua, luacheck, sendmidi, recievemidi

[https://docs.electra.one/developers]
[https://docs.electra.one/developers/midiimplementation.html] 

the json preset format: [https://docs.electra.one/developers/presetformat.html]


A preset is text. preset.json is the preset, main.lua is its script, router.lua is the router's, and the rest of the slot is a few more JSON files. There is no build, no binary, no project database: a diff is readable, a change is a file write, and git handles the history.

[https://docs.electra.one/luacourse/chapters/2-lua/index.html]
[https://docs.electra.one/luacourse/chapters/1-midi/6-sysex.html]

Preset Lua API (E1 runs Lua 5.4, 32-bit numbers): [https://docs.electra.one/developers/luaext.html]

## Tools and references

Our tool to send presets and Lua to the E1:
https://github.com/electraone/electraone-cli

Useful widgets and Lua code:
- https://github.com/roomi-fields/electraone-widgets
- https://github.com/electraone
- https://github.com/martinpavlas/electra.lua

Local: `lua5.4` is installed (syntax check with `luac5.4 -p` and `luacheck`, offline tests of data tables and SysEx builders).
Z1 SysEx reference: [Z1_SysEx.md](Z1_SysEx.md), parameter lists in [Z1_MIDIimp/](Z1_MIDIimp/).
Example presets: [Electrone/](Electrone/) (Toraiz AS-1 = show/hide/rename controls per FX type).

---

# Plan: Z1 SysEx hardware test + E1 OSC1 model page

Phase 1 verifies the Z1 SysEx on hardware. Phase 2 builds an E1 mk2 preset: an OSC1 Type selector plus one page of controls that Lua relabels, re-ranges and re-addresses per OSC model.
Scope: send-only (no dump parsing), no Go yet, OSC1 common params skipped except the Type selector.

## Key facts

- Header `F0 42 3g 46` (46 = Z1, `g` = global MIDI channel − 1).
- Parameter Change: `F0 42 3g 46 41 01 pl pm vl vm F7` (group `01` = Program, ID and value LSB first).
- Parameter ID is 14-bit: `ExID << 11 | ID`.
  - OSC1 Type 174 (ExID 0) → `pl 2E pm 01`.
  - OSC1 model params 464–754 use ExID 1 → `id14 = 2048 + ID`.
- Largest model is Resonance OSC (32 params) → Type selector + 32 fits one mk2 page (36 slots).
- E1 SysEx API (CTRL port, Linux "PORT 3"): `14 08 bank slot` select slot, `01 01 <json>` preset, `01 0C <lua>` script, `08 08` reload. Prefer `electraone-cli` for this.

## Mod source lists (kept as Lua arrays in memory)

| List | Entries | Values | Used by |
|---|---|---|---|
| Mod.Source List 1 | 49 | 0–48, contiguous | All OSC models, EGs, LFOs, mixer, filters, amp |
| Mod.Source List 2 | 36 | 0, 11–45 (gap) | Retrigger Controller (22), all effect params |

- Arrays of `{value, label}` in `main.lua` are the single source of truth; E1 overlays are built from them in `preset.onLoad`.
- A List control reports an index, not a value. Always convert with `overlay:getValueByIndex(index)` (required for List 2, LFO1–4 = 6–9, EG1–4/A.EG = 1–5).
- OSC models only use List 1. List 2 is prepared now for the effect pages later.

## Phase 1: Hardware SysEx tests

Setup: Z1 Global → SysEx Receive = ENABLE, SysEx Transmit = ON. Note channel `g`. Find ports with `sendmidi list`.
Send with `sendmidi dev "<Z1>" hex syx …`, watch with `receivemidi dev "<Z1>"`, capture long dumps with `amidi -p <port> -r file.syx`.

| Test | Send (after `F0`, without `F7`) | Expect |
|---|---|---|
| T1 Device inquiry | `7E 7F 06 01`, then `7E 0g 06 01` | `… 42 46 00 01 00 …` |
| T2 Current program dump | `42 3g 46 10 00` | `40 01 [data]`, about 666 bytes total, record actual |
| T3 OSC1 Type = Comb | `42 3g 46 41 01 2E 01 01 00` | `23`, Z1 shows Comb |
| T4 Standard Wave (464) = PULSE | `42 3g 46 41 01 50 13 01 00` | `23`, Wave = PULSE (confirms ExID 1) |
| T5 Standard WF Mod Source (473) = 20 | `42 3g 46 41 01 59 13 14 00` | `23`, source = Mod Wheel |
| T6 Standard WF Mod Int (474) = −50 | `42 3g 46 41 01 5A 13 4E 7F` | `23`, shows −50 (14-bit two's complement) |
| T7 Invalid parameter ID | any unused ID | `24` |
| T8 Fast knob burst | many T4-style messages quickly | no errors, no drops |

For T6 also edit a negative value on the Z1 panel and read the transmitted `41` message to confirm the encoding.
Record results in a "Verified on hardware" section of [Z1_SysEx.md](Z1_SysEx.md).

## Phase 2: E1 preset (after Phase 1)

Files:
- `e1/z1-osc1/preset.json`
- `e1/z1-osc1/main.lua`
- `e1/z1-osc1/main-tests.lua`

Steps:
1. Lua data arrays in `main.lua`:
   - `MODSRC1`, `MODSRC2`, `OSC_TYPES`.
   - Small enums: SAW/PULSE, SAW/SQU/TRI/SIN, SIN1/SIN2/SIN3/TRI, CLIP/RESO, LFO1–4 (6–9), EG1–4/A.EG (1–5), input selects, Brass types (6), Reed types (17), OFF/ON, Smooth/Jump, 1/2, SINGLE/MULTI.
   - `MODELS[0..12]`: ordered params `{id, name, min, max, kind, enum, fmt}`; reserved IDs skipped.
2. `preset.json`:
   - Device 1 "Korg Z1", port 1, channel from Phase 1.
   - Control 1: OSC1 TYPE list (13 models), value function `onOscType`.
   - Slots 2–36: a fader (id 100+s) and a list (id 200+s) stacked per slot, virtual messages, value function `onSlot`, formatter `fmtSlot`.
   - Only a placeholder overlay is needed; the rest is built in Lua.
3. `main.lua` logic:
   - `preset.onLoad`: build overlays from the arrays (List 1 = id 2, List 2 = id 3, enums id 10+).
   - `onOscType`: send param 174; per slot show fader or list, set name, range or overlay, neutral value via `updateValue`; hide unused slots.
   - `onSlot`: look up the param, convert list index to value, `v14 = v & 0x3FFF`, send `{0x42, 0x30|ch, 0x46, 0x41, 0x01, id & 0x7F, id >> 7, v14 & 0x7F, v14 >> 7}` via the device.
   - `fmtSlot`: +1 display (1–16), note names (C-1–G9), coarse (0.5/1–16), −1 = OFF.
4. Upload with `electraone-cli` (preset, then Lua) and read the E1 log.

## Verification

1. `luac5.4 -p e1/z1-osc1/main.lua` and offline checks of `MODELS` and the SysEx builder with local `lua5.4`.
2. `main-tests.lua` on the E1: exact bytes per slot for each model, including a List 2 index → value case.
3. E1 log after each upload (an empty log means "unknown", not "clean").
4. Z1 display: all 13 models switch, 2–3 params per model change.
5. A hidden control must not react to its knob.

## Open points

- Common pitch-mod sources 182/184/186 as fixed controls (Phase 2b).
- Dump parsing so the E1 shows the Z1's real values (later phase).

 
