# design a preset for the Korg Z1 MOSS synthesizer for the E1 (electraone)
Debian Linux and VS Code; Lua 5.4 and `luacheck` for development. Z1 hardware tests use `amidi` via Electra One Port 1; preset/script transfers and E1 Lua tests use `electraone-cli` on the CTRL port. `sendmidi` and `receivemidi` were not used for these tests.

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

## Protocol and Test Status

- Z1 header: `F0 42 3g 46`, where `46` is the Z1 model ID and `g` is the global MIDI channel minus one.
- Parameter Change: `F0 42 3g 46 41 01 pl pm vl vm F7`; Program group is `01`; parameter ID and 14-bit value bytes are LSB first.
- Parameter ID: `ExID << 11 | ID`. OSC1 Type is parameter 174; OSC1 model parameters 464–754 use ExID 1.
- Mod.Source List 1 has 49 values (`0–48`). List 2 has 36 values (`0`, `11–45`, non-contiguous). E1 list controls expose indexes, so convert indexes with `overlay:getValueByIndex()` before sending Z1 values.
- The Current Program dump observed on hardware was 666 SysEx bytes and 576 unpacked data bytes. Negative parameter values use 14-bit two's complement.
- Individual `41` Parameter Change messages modified the Z1 edit buffer but did not produce `23`/`24` replies. Those replies are expected for data dump operations, not individual Parameter Changes.
- Physical Z1 checks confirmed device inquiry, Current Program dump, OSC1 type/model writes, and negative-value encoding. Invalid-ID response behavior and fast-burst testing remain unverified. See [Z1_SysEx.md](Z1_SysEx.md) for the recorded details.
- Test counts below are Electra One Lua tests, not evidence that each module has been fully exercised against the physical Z1.

## Implemented Modules

Each module remains in its own `e1/<module>/` folder with its preset, Lua script, and E1 Lua tests.

| Module | Status | Notes |
|---|---|---|
| `e1/z1-osc1/` | Implemented; E1 tests passed 5/5 | Dynamic OSC1 model controls, enum/list mapping, and model-specific visibility. |
| `e1/z1-eg/` | Implemented; E1 tests passed 5/5 | Five `dx7envelope` controls and Start Level faders. Amp EG modulation controls stay visible in the middle control set; EG1–EG4 modulation controls and selector are in the bottom set, with values retained per EG. |
| `e1/z1-lfo/` | Implemented; E1 tests passed 3/3 | Four LFO sections with custom waveform displays. This is the current custom-widget example. |
| `e1/z1-filter/` | Implemented, latest behavior needs revalidation | Filter 1/2 controls, assigned cutoff EG display, and Band-B controls conditional on 2BPF. Earlier tests passed; the latest assigned-EG/visibility changes were not confirmed cleanly. |

The E1 modules have been uploaded individually. Recorded slots: OSC1 Bank 1 Slot 5; EG Bank 2 Slot 1; Filter Bank 2 Slot 2; LFO Bank 2 Slot 3.

## Memory and Storage Notes

Do not describe the Electra One mk2 as having 36 MB RAM. The previously observed value of roughly 31.7 MB was runtime free-heap telemetry, not total physical RAM.

The Electra One runtime-information SysEx query is `F0 00 21 45 02 7E F7`; the response is a JSON dump on resource `7E`. Its fields distinguish free heap (`freeRam`; also `stats.mem.heap`), peak heap use (`stats.mem.peak`), and Lua heap use across active presets (`stats.mem.lua`). In preset Lua, `controller.memory()` reports the current preset's Lua heap in KB and bytes. These fields do not establish total physical RAM capacity.

Electra One preset Lua supports `persist(table)` / `recall(table)` for data in the preset slot's `data.json` file on the controller's card. Writes are explicit; nothing is automatically saved on preset exit. Confirm practical capacity and behavior on the target firmware before choosing this mechanism for FX libraries.

## Incremental Roadmap

Build and test each section in its own `e1/<module>/` folder. This is a working module roadmap, not a final page-number commitment; combine or split modules after control density and hardware behavior are known.

| Priority | Module | Scope | Status |
|---:|---|---|---|
| 1 | `e1/z1-mix/` | Mixer controls and Mix Mod parameters on a dedicated MIX page | Next; requested, not implemented |
| 2 | `e1/z1-osc2/` | OSC2 core and dynamic model controls | Planned |
| 3 | `e1/z1-sub-noise/` | Sub oscillator and noise generator | Planned |
| 4 | `e1/z1-mod/` | Dynamic modulation-source/intensity sections | Planned |
| 5 | `e1/z1-fx/` | FX1, FX2, Master FX, EQ/output, and FX preset save/recall | Planned; storage design open |
| 6 | `e1/z1-common-arp/` | Program common, controllers, arpeggiator, and name display/editing | Planned |
| 7 | `e1/z1-full/` | Consolidated multi-page preset, dump parsing, and bidirectional synchronization | Final integration |

Continue maintaining `e1/z1-filter/`; re-run its E1 tests before treating the latest dynamic EG and 2BPF behavior as complete. OSC1, EG, LFO, Filter, MIX, and other modules may ultimately be arranged across up to 12 mk2 pages.

## Open Investigations and Completion Criteria

1. **Filter validation:** Run the current `e1/z1-filter/main-tests.lua` on the E1 and check assigned cutoff EG switching, per-filter state, and 2BPF-only Band-B visibility. Keep any failing behavior marked partial until resolved.
2. **Memory telemetry:** Capture runtime-info before and after loading/using modules, identify what `freeRam`, `stats.mem.heap`, `stats.mem.peak`, and `stats.mem.lua` show on this firmware, and measure practical headroom. Do not infer total physical RAM from free heap.
3. **Patch names:** Program Name, Multi Set Name, and Pattern Name each occupy parameter IDs 1–16 in the respective parameter tables, with 16 printable characters. Confirm packed-dump offsets and character decoding for Program, Multi, and Arpeggio Pattern dumps; then display names with a text box/value override. Name fields are listed in [PROG_PRM.TXT](Z1_MIDIimp/PROG_PRM.TXT), [MULT_PRM.TXT](Z1_MIDIimp/MULT_PRM.TXT), and [PAT_PRM.TXT](Z1_MIDIimp/PAT_PRM.TXT).
4. **CC/NRPN suitability:** Cross-reference `Z1_MIDIimp.TXT` CC and NRPN assignments with the parameter tables. Identify which controls accept these messages, compare resolution and message traffic with Parameter Change SysEx, and verify on hardware before using CC as an optimization. Do not assume CC covers every parameter or is faster in practice.
5. **Custom widgets:** Document the E1 custom-control paint and gesture callback APIs and the existing LFO waveform implementation. Use [roomi-fields/electraone-widgets](https://github.com/roomi-fields/electraone-widgets) as a reference where relevant; keep paint callbacks short and validate behavior on the mk2.
6. **FX preset persistence:** Define separate saved data for individual effect presets and complete FX-chain presets. Decide how users select, name, save, overwrite, and recall them; test `persist`/`recall` or another supported storage route on the controller, including capacity, reboot persistence, and compatibility when FX types differ.
7. **Full dump synchronization:** Parse Program/Multi/Pattern dumps, populate the corresponding controls without echoing received data back to the Z1, and verify outbound edits and incoming dump updates remain consistent.
8. **Remaining protocol tests:** Verify Z1 invalid-parameter responses and fast Parameter Change bursts. There is rate throtle available and we might need to use it. But needs to be tested and verified. Go transport/shared-library work remains deferred until the preset protocol and editor scope are stable.

## Working and Verification Practices

- Keep modulation source arrays and overlays in preset memory. Use the overlay item's Z1 value, not its display index.
- Keep dynamically changing controls on their page and use visibility changes rather than repeatedly moving controls between pages. Batch visible UI updates where appropriate.
- For each module, syntax-check Lua with `luac5.4 -p`, run focused local checks where useful, run `main-tests.lua` on the E1, and record separately any physical-Z1 checks. An empty log means unknown, not clean.
- Z1 is routed through Electra One Port 1 for hardware tests; Electra One management and file transfer use `electraone-cli` on the CTRL port. Large preset files may require the chunked `electraone files upload` path.
