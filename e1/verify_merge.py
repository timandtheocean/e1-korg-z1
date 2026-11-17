#!/usr/bin/env python3
"""
verify_merge.py - behavioural check of preset.z1.json + main.z1.lua.

For every module it runs the module's own preset.json + main.lua in a mock
Electra One Lua runtime (tools/electra_mock.lua) and then the merged preset,
calls every function/formatter callback of every control with a range of
values, and compares what happens: SysEx sent, formatter output, control /
group visibility, names, ranges, overlays, Lua errors.

Usage:  ./verify_merge.py            (run ./merge_z1_presets.py first)
        ./verify_merge.py -v         show the diff for failing modules
"""
import argparse
import difflib
import json
import subprocess
import sys
import tempfile
from pathlib import Path

import merge_z1_presets as mz

ROOT = Path(__file__).resolve().parent
MOCK = ROOT / "tools" / "electra_mock.lua"
LUA = "lua5.4"

SYSEX_IN = [
    # Universal identity reply from a Korg Z1 (family 0x46)
    [0xF0, 0x7E, 0x00, 0x06, 0x02, 0x42, 0x46, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0xF7],
    # Z1 parameter change (func 0x41) echo
    [0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x10, 0x00, 0x05, 0x00, 0xF7],
]


def lua_lit(o):
    if o is None:
        return "nil"
    if isinstance(o, bool):
        return "true" if o else "false"
    if isinstance(o, (int, float)):
        return repr(o)
    if isinstance(o, str):
        return json.dumps(o)  # JSON string escapes are valid Lua (\uXXXX handled below)
    if isinstance(o, list):
        return "{" + ",".join(lua_lit(x) for x in o) + "}"
    if isinstance(o, dict):
        return "{" + ",".join("[%s]=%s" % (lua_lit(k), lua_lit(v)) for k, v in o.items()) + "}"
    raise TypeError(type(o))


def lua_str(s):
    out = []
    for ch in s:
        if ch in '\\"':
            out.append("\\" + ch)
        elif ch == "\n":
            out.append("\\n")
        elif ord(ch) < 32 or ord(ch) > 126:
            out.append("".join("\\%d" % b for b in ch.encode("utf-8")))
        else:
            out.append(ch)
    return '"' + "".join(out) + '"'


def to_lua(o):
    if isinstance(o, str):
        return lua_str(o)
    if isinstance(o, list):
        return "{" + ",".join(to_lua(x) for x in o) + "}"
    if isinstance(o, dict):
        return "{" + ",".join("[%s]=%s" % (to_lua(k), to_lua(v)) for k, v in o.items()) + "}"
    return lua_lit(o)


def sample_values(v):
    lo = v.get("min", v.get("message", {}).get("min", 0))
    hi = v.get("max", v.get("message", {}).get("max", 127))
    msg = v.get("message", {})
    vals = [lo, hi, (lo + hi) // 2, min(lo + 1, hi), lo]
    for k in ("offValue", "onValue"):
        if k in msg:
            vals.append(msg[k])
    seen, res = set(), []
    for x in vals:
        if x not in seen:
            seen.add(x)
            res.append(x)
    return res


def tests_for(preset, idmap_fn, name_fn):
    tests = []
    for c in preset["controls"]:
        for v in c.get("values", []):
            for kind in ("function", "formatter"):
                if v.get(kind):
                    tests.append({"ctrl": idmap_fn(c["id"]), "valueId": v.get("id", "value"),
                                  "fn": name_fn(v[kind]), "kind": kind, "values": sample_values(v)})
    return tests


def pack_korg_7bit(unpacked):
    """Pack 8-bit bytes into Korg 7-to-8-bit MIDI format (7 data bytes -> 8 MIDI bytes)."""
    packed = []
    for i in range(0, len(unpacked), 7):
        chunk = unpacked[i:i + 7]
        msb = 0
        for b_idx, val in enumerate(chunk):
            if val & 0x80:
                msb |= (1 << b_idx)
        packed.append(msb)
        for val in chunk:
            packed.append(val & 0x7F)
    return packed


def run(preset, script, tests, idmap=None, pagemap=None, with_sysex=False, check_dup_ov=False, sysex_list=None):
    sx_payload = sysex_list if sysex_list is not None else (SYSEX_IN if with_sysex else None)
    prog = "PRESET=%s\nSCRIPT=%s\nTESTS=%s\nIDMAP=%s\nPAGEMAP=%s\nSYSEX_IN=%s\nTICKS=%s\nCHECK_DUP_OV=%s\n" % (
        to_lua(preset), lua_str(str(script)), to_lua(tests),
        ("{" + ",".join("[%d]=%d" % (g, l) for g, l in idmap.items()) + "}") if idmap else "nil",
        ("{" + ",".join("[%d]=%d" % (g, l) for g, l in pagemap.items()) + "}") if pagemap else "nil",
        to_lua(sx_payload) if sx_payload is not None else "nil",
        "20" if with_sysex else "nil",
        "true" if check_dup_ov else "false")
    with tempfile.NamedTemporaryFile("w", suffix=".lua", delete=False, encoding="utf-8") as f:
        f.write(prog)
        f.write("dofile(%s)\n" % lua_str(str(MOCK)))
        path = f.name
    r = subprocess.run([LUA, path], capture_output=True, text=True, timeout=120)
    Path(path).unlink()
    if r.returncode != 0:
        return ["LUA CRASH: " + r.stderr]
    return r.stdout.splitlines()


def verify_overlays(merged, modules):
    errs = []
    ov_by_id = {o["id"]: o["items"] for o in merged.get("overlays", [])}
    seen_items = {}
    for idx, o in enumerate(merged.get("overlays", []), 1):
        oid = o["id"]
        items = o.get("items", [])
        if oid != idx:
            errs.append(f"overlay id {oid} is not sequential (expected {idx})")
        if len(items) < 2:
            errs.append(f"overlay {oid} has only {len(items)} item(s) (placeholder stub?)")
        key = json.dumps(items, sort_keys=True)
        if key in seen_items:
            errs.append(f"overlay {oid} duplicates overlay {seen_items[key]} (Editor will renumber!)")
        seen_items[key] = oid

    merged_ctrl_by_id = {c["id"]: c for c in merged.get("controls", [])}
    for m in modules:
        cmap = m["cmap"]
        real_ov = m["real_overlays"]
        for c in m["json"].get("controls", []):
            mc = merged_ctrl_by_id[cmap[c["id"]]]
            for v, mv in zip(c.get("values", []), mc.get("values", [])):
                if "overlayId" in v:
                    exp_items = real_ov.get(v["overlayId"])
                    act_items = ov_by_id.get(mv.get("overlayId"))
                    if exp_items != act_items:
                        errs.append(f"{m['name']} ctrl {c['id']} ({c['name']}): merged overlay {mv.get('overlayId')} "
                                    f"does not match expected items")
    return errs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-v", "--verbose", action="store_true")
    ap.add_argument("--merged", default="preset.z1.json")
    ap.add_argument("--lua", default="main.z1.lua")
    ap.add_argument("--modules", nargs="+", default=mz.DEFAULT_MODULES)
    args = ap.parse_args()

    merged = json.loads((ROOT / args.merged).read_text(encoding="utf-8"))
    # recompute the id maps exactly like the merge script
    warnings = []
    modules = [mz.load_module(ROOT, n) for n in args.modules]
    mz.merge(modules, merged["name"], merged["projectId"], warnings)

    ov_errs = verify_overlays(merged, modules)
    if ov_errs:
        for e in ov_errs:
            print("OVERLAY ERROR: " + e)
    else:
        print("OK   overlays        %4d unique full overlays in %s (0 stubs, 0 duplicates)"
              % (len(merged.get("overlays", [])), args.merged))

    lua_src = (ROOT / args.lua).read_text(encoding="utf-8")
    modsrc1_defs = len(mz.re.findall(r"\bMODSRC1\s*=\s*\{", lua_src))
    modsrc2_defs = len(mz.re.findall(r"\bMODSRC2\s*=\s*\{", lua_src))
    notenames_defs = len(mz.re.findall(r"\bNOTE_NAMES\s*=\s*\{", lua_src))
    reused_total = sum(len(m.get("reused_funcs", {})) for m in modules)
    dup_lua_errs = []
    if modsrc1_defs > 1 or modsrc2_defs > 1 or notenames_defs > 1:
        dup_lua_errs.append(f"duplicate shared tables in {args.lua}: MODSRC1={modsrc1_defs}, MODSRC2={modsrc2_defs}, NOTE_NAMES={notenames_defs}")
    if dup_lua_errs:
        for e in dup_lua_errs:
            print("LUA DEDUP ERROR: " + e)
    else:
        print("OK   lua-dedup       %4d duplicate callbacks reused, MODSRC1=%d, MODSRC2=%d, NOTE_NAMES=%d in %s"
              % (reused_total, modsrc1_defs, modsrc2_defs, notenames_defs, args.lua))

    # Also test with JSON overlayIds stripped on visible controls, to ensure preset.onReady()
    # binds every visible list control at runtime even if an external editor renumbers overlays.
    stripped = json.loads(json.dumps(merged))
    for c in stripped["controls"]:
        if c.get("visible", True):
            for v in c.get("values", []):
                v.pop("overlayId", None)

    failed = 0 if not (ov_errs or dup_lua_errs) else 1
    for m in modules:
        own = m["json"]
        cmap, pmap, fmap = m["cmap"], m["pmap"], m["fmap"]
        reused = m.get("reused_funcs", {})
        ws = m["name"] == "z1-base"
        base = run(own, m["dir"] / "main.lua", tests_for(own, lambda i: i, lambda f: f), with_sysex=ws)
        mrg = run(merged, ROOT / args.lua,
                  tests_for(own, lambda i: cmap[i], lambda f: fmap.get(f) or reused[f]),
                  idmap={g: l for l, g in cmap.items()}, pagemap={g: l for l, g in pmap.items()},
                  with_sysex=ws, check_dup_ov=True)
        mrg_strip = run(stripped, ROOT / args.lua, [],
                        idmap={g: l for l, g in cmap.items()}, pagemap={g: l for l, g in pmap.items()}, with_sysex=False)
        init_state = [l for l in mrg[:mrg.index("---- callbacks")] if l.startswith("STATE C")]
        strip_state = [l for l in mrg_strip[:mrg_strip.index("---- callbacks")] if l.startswith("STATE C")]
        # Compare visible controls' state after onReady() even when JSON overlayIds were stripped
        vis_ids = {f"C{c['id']} " for c in own["controls"] if c.get("visible", True)}
        init_vis = [l for l in init_state if any(v in l for v in vis_ids)]
        strip_vis = [l for l in strip_state if any(v in l for v in vis_ids)]
        calls = sum(1 for l in base if l.startswith("CALL"))
        sx = sum(1 for l in base if l.startswith("SX"))
        errs = [l for l in mrg if l.startswith(("ERROR", "LUA CRASH"))]
        same = (base == mrg) and (init_vis == strip_vis)
        status = "OK  " if same else "DIFF"
        if not same:
            failed += 1
        print("%s %-15s %4d callback calls, %4d sysex, %d errors in merged run" % (status, m["name"], calls, sx, len(errs)))
        if init_vis != strip_vis:
            print("     WARNING: some visible controls do not call setOverlayId() in preset.onReady()!")
            if args.verbose:
                for line in list(difflib.unified_diff(init_vis, strip_vis, "with_json_ov", "stripped_json_ov", lineterm="", n=0))[:20]:
                    print("     " + line)
        missing = [l for l in base if l.startswith("MOCK-MISSING")]
        if missing and args.verbose:
            print("     " + missing[0])
        if not same and args.verbose:
            for line in list(difflib.unified_diff(base, mrg, "standalone", "merged", lineterm="", n=2))[:60]:
                print("     " + line)
        orig_errs = [l for l in base if l.startswith("ERROR")]
        if orig_errs and args.verbose:
            print("     (standalone module itself reports %d errors, e.g. %s)" % (len(orig_errs), orig_errs[0][:150]))
    if not failed:
        # Cross-page sync check: editing EG1..EG4 / Amp EG on z1-eg updates F1/F2 Assigned EG on z1-filter (and vice versa)
        mod_by_name = {m["name"]: m for m in modules}
        if "z1-eg" in mod_by_name and "z1-filter" in mod_by_name:
            eg_cmap = mod_by_name["z1-eg"]["cmap"]
            fl_cmap = mod_by_name["z1-filter"]["cmap"]
            sync_tests = [
                # 1. Edit EG3 (default F1 Cut ModEG) on Envelopes page -> F1 EG3 on Filter page updates immediately
                {"ctrl": eg_cmap[3],  "valueId": "r1",    "fn": "eg_onEnvHandle",   "kind": "function", "values": [63]},
                {"ctrl": eg_cmap[13], "valueId": "value", "fn": "eg_onStartLevel",  "kind": "function", "values": [-30]},
                # 2. Edit EG1 on Envelopes page, then select EG1 on Filter page -> F1 EG1 shows edited curve
                {"ctrl": eg_cmap[1],  "valueId": "l1",    "fn": "eg_onEnvHandle",   "kind": "function", "values": [-45]},
                {"ctrl": eg_cmap[1],  "valueId": "r1",    "fn": "eg_onEnvHandle",   "kind": "function", "values": [77]},
                {"ctrl": eg_cmap[11], "valueId": "value", "fn": "eg_onStartLevel",  "kind": "function", "values": [-20]},
                {"ctrl": fl_cmap[21], "valueId": "value", "fn": "fl_onDynFilter",   "kind": "function", "values": [0]},
                # 3. Edit F1 EG1 on Filter page -> EG 1 on Envelopes page updates immediately
                {"ctrl": fl_cmap[4],  "valueId": "r2",    "fn": "fl_onEg3Handle",   "kind": "function", "values": [55]},
                {"ctrl": fl_cmap[5],  "valueId": "value", "fn": "fl_onEgStartLevel","kind": "function", "values": [15]},
            ]
            sync_out = "\n".join(run(merged, ROOT / args.lua, sync_tests, idmap=None, check_dup_ov=True))
            ok_sync = (
                f"STATE C{fl_cmap[4]} true|F1 EG3|255|l1:-99..99:0..198:0:nil|r1:0..99:0..99:63:nil" in sync_out
                and f"STATE C{fl_cmap[5]} true|EG3 StartLvl|529DEC|value:-99..99:0..198:-30:nil" in sync_out
                and f"STATE C{fl_cmap[4]} true|F1 EG1|255|l1:-99..99:0..198:-45:nil|r1:0..99:0..99:77:nil" in sync_out
                and f"STATE C{eg_cmap[1]} true|EG 1|529DEC|l1:-99..99:0..198:-45:nil|r1:0..99:0..99:77:nil|l2:-99..99:0..198:nil:nil|r2:0..99:0..99:55:nil" in sync_out
                and f"STATE C{eg_cmap[11]} true|EG1 StartLvl|529DEC|value:-99..99:0..198:15:nil" in sync_out
            )
            if ok_sync:
                print("OK   eg-filter-sync  bidirectional EG1..EG4 & Amp EG curve sync verified")
            else:
                print("DIFF eg-filter-sync  cross-page EG <-> Filter sync failed!")
                failed += 1

        # Full 576-byte Program Dump (40H / 4CH) and Parameter Change (41H) parsing check across all 10 modules
        raw_576 = [0] * 576
        for i, ch in enumerate(b"KORG Z1 TEST    "):
            raw_576[i] = ch
        raw_576[17 - 1] = 5                                  # ID 17: Category = 5
        raw_576[18 - 1] = 3                                  # ID 18: User Group = 3
        raw_576[19 - 1] = 1 | (2 << 1) | (1 << 3)            # IDs 19..21: Hold=1, KeyPrio=2, VoiceMode=1
        raw_576[20 - 1] = 4                                  # ID 22: Common Pitch Mod Src = 4
        raw_576[21 - 1] = 42                                 # ID 23: Common Pitch Mod Int = 42
        raw_576[22 - 1] = 2 | (1 << 2) | (1 << 3)            # IDs 24..26: UniType=2, UniSw=1, UniMode=1
        raw_576[23 - 1] = 77                                 # ID 27: Unison Detune = 77
        raw_576[24 - 1] = 5 | (3 << 4)                       # IDs 28, 29: Scale Key = 5, Scale Type = 3
        raw_576[25 - 1] = 12                                 # ID 30: Pure Type = 12
        raw_576[26 - 1] = (-25) & 0xFF                       # ID 31: EG1 Start Level = -25
        raw_576[27 - 1] = 40                                 # ID 32: EG1 Attack Time (r1) = 40
        raw_576[28 - 1] = 88                                 # ID 33: EG1 Attack Level (l1) = 88
        raw_576[64 - 1] = (-33) & 0xFF                       # ID 69: EG3 Start Level = -33
        raw_576[65 - 1] = 62                                 # ID 70: EG3 Attack Time (r1) = 62
        raw_576[102 - 1] = 3 | (1 << 6)                      # IDs 107..108: LFO1 Wave=3, KeySync=1
        raw_576[103 - 1] = 145                               # ID 109: LFO1 Freq = 145
        raw_576[112 - 1] = 4 | (2 << 4) | (1 << 7)           # IDs 118..120: LFO1 MidiSync=1, SyncBase=2, SyncTime=4
        raw_576[146 - 1] = 7                                 # ID 163: Pitch Bend + = 7
        raw_576[147 - 1] = (-12) & 0xFF                      # ID 164: Pitch Bend - = -12
        raw_576[152 - 1] = 55                                # ID 171: Portamento Time = 55
        raw_576[155 - 1] = 2                                 # ID 174: OSC1 Type = 2 (VPM)
        raw_576[156 - 1] = 2                                 # ID 175: OSC1 Octave = 2 (8')
        raw_576[157 - 1] = (-5) & 0xFF                       # ID 176: OSC1 Semitone = -5
        raw_576[169 - 1] = 12                                # ExID 1 ID 500: VPM Carrier Level = 12
        raw_576[207 - 1] = 4                                 # ID 188: OSC2 Type = 4 (Ring Mod)
        raw_576[272 - 1] = 2                                 # ID 215: Sub OSC Wave = 2
        raw_576[273 - 1] = 2                                 # ID 216: Noise Filter Type = 2
        raw_576[281 - 1] = 85                                # ID 224: Mixer OSC1 Out1 Level = 85
        raw_576[311 - 1] = 0x05                              # IDs 254..257: Mixer Out SW = 1, 0, 1, 0
        raw_576[312 - 1] = 2 | (1 << 2) | (2 << 4)           # IDs 258..260: Filter Routing=2, F2 Link=1, EG Target=2
        raw_576[313 - 1] = 3                                 # ID 261: Filter1 Type = 3 (BPF -> idx 2)
        raw_576[315 - 1] = 74                                # ID 263: Filter1 Cutoff = 74
        raw_576[320 - 1] = 3                                 # ID 268: Filter1 Cut ModEG = 3 (EG3 -> idx 2)
        raw_576[367 - 1] = 91                                # ID 315: Amp1 Level = 91
        raw_576[386 - 1] = 28                                # ID 334: Amp EG Attack Time (r1) = 28
        raw_576[408 - 1] = 80                                # ID 356: FX Send1 = 80
        raw_576[411 - 1] = 6                                 # ID 359: FX1 Select = 6 (Chorus)
        raw_576[412 - 1] = 150                               # ExID 3 ID 882: Chorus L Pre Delay = 150
        raw_576[417 - 1] = 4 | (3 << 4) | (1 << 7)           # ExID 3 IDs 887..889: Chorus MidiSync=1, Base=3, Time=4
        raw_576[476 - 1] = 14                                # ID 362: Low EQ Freq = 14
        raw_576[480 - 1] = 2 | (1 << 7)                      # IDs 366..367: SW1 Func=2, Latch=1
        raw_576[484 - 1] = 3                                 # ID 374: Arp Pattern = 3
        raw_576[489 - 1] = 180                               # ID 383: Arp Speed = 180
        raw_576[497 - 1] = 64                                # ID 384: Knob 1 Target 1 Param = 64

        packed_659 = pack_korg_7bit(raw_576)
        dump_40h = [0xF0, 0x42, 0x30, 0x46, 0x40, 0x01] + packed_659 + [0xF7]
        # Follow with a 41H single parameter change: Filter1 Cutoff (ExID=0, ID=263=0x0107) -> 93
        param_41h = [0xF0, 0x42, 0x30, 0x46, 0x41, 0x01, 0x07, 0x02, 93, 0x00, 0xF7]
        dump_lines = run(merged, ROOT / args.lua, [], idmap=None, sysex_list=[dump_40h, param_41h])
        dump_out = "\n".join(dump_lines)

        ca_cmap = mod_by_name["z1-common-arp"]["cmap"]
        oc_cmap = mod_by_name["z1-osc-common"]["cmap"]
        sn_cmap = mod_by_name["z1-sub-noise"]["cmap"]
        mx_cmap = mod_by_name["z1-mix"]["cmap"]
        fl_cmap = mod_by_name["z1-filter"]["cmap"]
        md_cmap = mod_by_name["z1-mod"]["cmap"]
        eg_cmap = mod_by_name["z1-eg"]["cmap"]
        lf_cmap = mod_by_name["z1-lfo"]["cmap"]
        fx_cmap = mod_by_name["z1-fx"]["cmap"]

        dump_checks = [
            ("Common Category",       f"STATE C{ca_cmap[1]} " in dump_out and ":5:" in dump_out),
            ("Common Unison Detune",  f"STATE C{ca_cmap[11]} " in dump_out and ":77:" in dump_out),
            ("Arp Speed",             f"STATE C{ca_cmap[16]} " in dump_out and ":180:" in dump_out),
            ("OSC1 Type VPM",         f"STATE C{oc_cmap[2]} " in dump_out and ":2:" in dump_out),
            ("OSC1 Semitone -5",      f"STATE C{oc_cmap[4]} " in dump_out and ":-5:" in dump_out),
            ("OSC1 VPM Carrier Lvl",  f"STATE C{oc_cmap[403]} " in dump_out and ":12:" in dump_out),
            ("OSC2 Type RingMod",     f"STATE C{oc_cmap[8]} " in dump_out and ":4:" in dump_out),
            ("Sub OSC Wave",          f"STATE C{sn_cmap[1]} " in dump_out and ":2:" in dump_out),
            ("Portamento Time",       f"STATE C{sn_cmap[33]} " in dump_out and ":55:" in dump_out),
            ("Mixer OSC1 Level",      f"STATE C{mx_cmap[1]} " in dump_out and ":85:" in dump_out),
            ("Filter1 Cutoff 40H",    f"STATE C{fl_cmap[8]} " in dump_out and ":74:" in dump_out),
            ("Filter1 Cutoff 41H",    f"STATE C{fl_cmap[8]} " in dump_out and ":93:" in dump_out),
            ("Filter1 Assigned EG3",  f"STATE C{fl_cmap[4]} true|F1 EG3|255|l1:-99..99:0..198:0:nil|r1:0..99:0..99:62:nil" in dump_out),
            ("Amp1 Level",            f"STATE C{md_cmap[1]} " in dump_out and ":91:" in dump_out),
            ("Mod O1 Semi",           f"STATE C{md_cmap[102]} " in dump_out and ":-5:" in dump_out),
            ("EG1 Curve",             f"STATE C{eg_cmap[1]} true|EG 1|529DEC|l1:-99..99:0..198:88:nil|r1:0..99:0..99:40:nil" in dump_out),
            ("EG1 StartLvl",          f"STATE C{eg_cmap[11]} true|EG1 StartLvl|529DEC|value:-99..99:0..198:-25:nil" in dump_out),
            ("Amp EG Attack",         f"STATE C{eg_cmap[5]} " in dump_out and "|r1:0..99:0..99:28:nil" in dump_out),
            ("LFO1 Freq",             f"STATE C{lf_cmap[3]} " in dump_out and ":145:" in dump_out),
            ("FX1 Chorus PreDelay",   f"STATE C{fx_cmap[101]} " in dump_out and ":150:" in dump_out),
            ("No SysEx Echo on Dump", not any(l.startswith("SX ") for l in dump_lines[dump_lines.index("---- callbacks"):])),
            ("No Lua Errors on Dump", not any(l.startswith(("ERROR", "LUA CRASH")) for l in dump_lines)),
        ]
        failed_checks = [name for name, ok in dump_checks if not ok]
        if not failed_checks:
            print("OK   prog-dump-parse 576-byte 40H dump + 41H param change parsed across all 12 pages")
        else:
            print("DIFF prog-dump-parse failed checks: " + ", ".join(failed_checks))
            failed += 1

        # 30-second Backup Hold on Preset Change + Recover + Cross-page Undo / Redo check
        bs_cmap = mod_by_name["z1-base"]["cmap"]
        bs_fmap = mod_by_name["z1-base"]["fmap"]
        rec_fn  = bs_fmap["onRecoverBackupBtn"]
        undo_fn = bs_fmap["onUndoBtn"]
        redo_fn = bs_fmap["onRedoBtn"]

        raw_b = list(raw_576)
        for i, ch in enumerate(b"SECOND PATCH    "):
            raw_b[i] = ch
        raw_b[315 - 1] = 15  # Filter1 Cutoff = 15
        raw_b[157 - 1] = 9   # OSC1 Semitone = +9
        dump_b = [0xF0, 0x42, 0x30, 0x46, 0x40, 0x01] + pack_korg_7bit(raw_b) + [0xF7]

        raw_c = list(raw_576)
        for i, ch in enumerate(b"THIRD PATCH     "):
            raw_c[i] = ch
        raw_c[315 - 1] = 33  # Filter1 Cutoff = 33
        raw_c[157 - 1] = 4   # OSC1 Semitone = +4
        dump_c = [0xF0, 0x42, 0x30, 0x46, 0x40, 0x01] + pack_korg_7bit(raw_c) + [0xF7]

        bk_undo_tests = [
            # 1. Load Patch A (F1 Cutoff = 74, OSC1 Semi = -5)
            {"sysex": dump_40h},
            # 2. User edits F1 Cutoff (74 -> 81 -> 88) and OSC1 Semi (-5 -> +7) on Patch A
            {"ctrl": fl_cmap[8], "valueId": "cutoff", "fn": "fl_onStaticFilter", "kind": "function", "values": [81, 88]},
            {"ctrl": oc_cmap[4], "valueId": "value", "fn": "oc_onParam",        "kind": "function", "values": [7]},
            # 3. Undo OSC1 Semi (+7 -> -5), Undo F1 Cutoff (88 -> 74), then Redo F1 Cutoff (74 -> 88)
            {"ctrl": bs_cmap[5], "valueId": "value", "fn": undo_fn,             "kind": "function", "values": [1]},
            {"ctrl": bs_cmap[5], "valueId": "value", "fn": undo_fn,             "kind": "function", "values": [1]},
            {"ctrl": bs_cmap[6], "valueId": "value", "fn": redo_fn,             "kind": "function", "values": [1]},
            # 4. Switch preset to Patch B, wait 10s, switch to Patch C (10s more = 20s < 30s)
            {"sysex": dump_b},
            {"ticks": 10},
            {"sysex": dump_c},
            {"ticks": 10},
            # 5. Press Recover Backup within 30s -> restores Patch A (Cutoff=88, Semi=-5)
            {"ctrl": bs_cmap[4], "valueId": "value", "fn": rec_fn,              "kind": "function", "values": [1]},
            # 6. Switch preset to Patch B and let 30s expire -> Auto backup updates to Patch B
            {"sysex": dump_b},
            {"ticks": 30},
            # Edit Cutoff on Patch B (15 -> 20), switch to Patch C, Undo back to Patch B -> Cutoff is 20
            {"ctrl": fl_cmap[8], "valueId": "cutoff", "fn": "fl_onStaticFilter", "kind": "function", "values": [20]},
            {"sysex": dump_c},
            {"ctrl": bs_cmap[5], "valueId": "value", "fn": undo_fn,             "kind": "function", "values": [1]},
        ]
        bk_lines = run(merged, ROOT / args.lua, bk_undo_tests, idmap=None)
        bk_out = "\n".join(bk_lines)
        after_recover = bk_out.split(f"CALL C{bs_cmap[4]}.value function(1)", 1)[1]
        after_cross_undo = bk_out.rsplit(f"CALL C{bs_cmap[5]}.value function(1)", 1)[1]
        ok_bk_undo = (
            not any(l.startswith(("ERROR", "LUA CRASH")) for l in bk_lines)
            # Undo reverted OSC1 Semi to -5 and sent 41H (ID 176 = 0x00B0, val -5 = 0x3FFB -> 7B 7F)
            and "SX 42 30 46 41 01 30 01 7B 7F" in bk_out
            # Undo reverted F1 Cutoff to 74 and sent 41H (ID 263 = 0x0107, val 74 = 0x4A)
            and "SX 42 30 46 41 01 07 02 4A 00" in bk_out
            # Redo restored F1 Cutoff to 88 and sent 41H (ID 263 = 0x0107, val 88 = 0x58)
            and "SX 42 30 46 41 01 07 02 58 00" in bk_out
            # After switching through Patch B and Patch C (20s elapsed < 30s), Recover restored Patch A (Cutoff=88, Semi=-5)
            and f"STATE C{fl_cmap[8]} true|F1 Filter|F45C51|cutoff:0..99:0..99:88:nil|resonance:0..99:0..99:0:nil" in after_recover
            and f"STATE C{oc_cmap[4]} true|OSC1 Semi|F49500|value:-12..12:0..24:-5:nil" in after_recover
            # Cross-patch Undo from Patch C back to edited Patch B reconstructed Cutoff=20 & Semi=+9
            and f"STATE C{fl_cmap[8]} true|F1 Filter|F45C51|cutoff:0..99:0..99:20:nil|resonance:0..99:0..99:0:nil" in after_cross_undo
            and f"STATE C{oc_cmap[4]} true|OSC1 Semi|F49500|value:-12..12:0..24:9:nil" in after_cross_undo
        )
        if ok_bk_undo:
            print("OK   backup-undo     30s backup hold/recover + cross-page Undo/Redo verified")
        else:
            print("DIFF backup-undo     30s backup hold/recover or Undo/Redo failed!")
            failed += 1

    print("all modules behave identically" if not failed else "%d module(s) differ" % failed)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
