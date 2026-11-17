#!/usr/bin/env python3
"""
merge_z1_presets.py - merge the Korg Z1 Electra One module presets into ONE preset.

Each z1-*/ folder is a stand-alone Electra One preset (preset.json + main.lua).
Simply concatenating the JSON arrays does not give a working preset, because
(see https://docs.electra.one/developers/presetformat.html):

  * controls and groups share ONE id space (1 .. 864). A duplicate id is
    dropped ("first object carrying an id keeps it", groups are read first).
  * page ids must be 1 .. 12 on an mk2, otherwise the page and everything on
    it is dropped.
  * overlay ids are one byte (0 .. 255) and a duplicate id replaces the earlier one.
  * the parameter map is keyed by (device, message type, parameterNumber).
    Every module uses "virtual" parameters starting at 1, so without
    renumbering, controls of different modules become the SAME parameter
    (turning one knob moves/fires a control on another page).
  * function / formatter names are max. 20 characters and max. 255 distinct.
  * a preset has only ONE main.lua. Every module's main.lua hard-codes its own
    control / group / overlay / page ids, defines the same global names
    (MODSRC1, onSlot, buildParamChangeBody, ...) and its own preset.onLoad /
    preset.onReady.

So this script merges BOTH files:

  preset.json  -> pages, groups, controls, overlays renumbered into one id space,
                  virtual parameterNumbers made unique, callbacks renamed with a
                  module prefix (e.g. "onMixParam" -> "mx_onMixParam").
  main.lua     -> every module's main.lua is wrapped in its own environment
                  (_ENV) so its globals cannot collide. Inside that environment
                  controls.get / preset.getControl / preset.getGroup /
                  overlays.get / overlays.create / pages.get / pages.display
                  translate the module's LOCAL ids to the merged ids, and
                  ":getId()" / ":setOverlayId()" are rewritten to translate back.
                  preset.onLoad / preset.onReady / midi.onSysex / timer.onTick ...
                  of all modules are chained.

The module sources are not modified; re-run the script after editing a module.

Usage:
  ./merge_z1_presets.py                     # writes preset.z1.json + main.z1.lua
  ./merge_z1_presets.py --pretty            # indented JSON (default: minified)
  ./merge_z1_presets.py --check             # only analyse, write nothing
  ./merge_z1_presets.py --modules z1-base z1-eg ...   # custom module list / order
"""

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
from collections import OrderedDict
from pathlib import Path

# --------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------

# Order = page order on the Electra and order in which the Lua hooks are run.
# z1-osc1 and z1-osc2 are NOT included: z1-osc-common already contains the
# OSC1 and OSC2 editor pages (its pages 2 and 3). Including them as well would
# give 14 pages (mk2 maximum is 12) and duplicate editors.
DEFAULT_MODULES = [
    "z1-base",
    "z1-common-arp",
    "z1-osc-common",
    "z1-sub-noise",
    "z1-mix",
    "z1-filter",
    "z1-mod",
    "z1-eg",
    "z1-lfo",
    "z1-fx",
]

# Short prefixes used for renamed Lua callbacks (function names max 20 chars).
PREFIXES = {
    "z1-base": "bs",
    "z1-common-arp": "ca",
    "z1-osc-common": "oc",
    "z1-osc1": "o1",
    "z1-osc2": "o2",
    "z1-sub-noise": "sn",
    "z1-mix": "mx",
    "z1-filter": "fl",
    "z1-mod": "md",
    "z1-eg": "eg",
    "z1-lfo": "lf",
    "z1-fx": "fx",
}

# Limits from the preset format description (firmware 5.0, Electra One mk2)
MAX_PAGE_ID = 12
MAX_CONTROL_GROUP_ID = 864
MAX_CONTROLS = 432
MAX_OVERLAY_ID = 255
MAX_PARAMETER_NUMBER = 16383
MAX_FUNCTION_NAME = 20
MAX_FUNCTION_NAMES = 255
MAX_NAME = 20
MAX_FILE_SIZE = 1228800

# Lua API tables whose id arguments are translated / whose hooks are chained
SHIMMED_TABLES = ["preset", "controls", "groups", "overlays", "pages", "window",
                  "midi", "timer", "events", "patch", "transport", "parameterMap"]


class MergeError(Exception):
    pass


# --------------------------------------------------------------------------
# Minimal Lua 5.4 tokenizer (enough to rewrite method calls safely, i.e.
# never inside strings or comments)
# --------------------------------------------------------------------------

LUA_KEYWORDS = {
    "and", "break", "do", "else", "elseif", "end", "false", "for", "function",
    "goto", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then",
    "true", "until", "while",
}

_long_bracket = re.compile(r"\[(=*)\[")
_name = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
_number = re.compile(
    r"0[xX](?:[0-9a-fA-F]*\.?[0-9a-fA-F]*)(?:[pP][+-]?[0-9]+)?"
    r"|(?:[0-9]+\.?[0-9]*|\.[0-9]+)(?:[eE][+-]?[0-9]+)?")
_ops = ["...", "..", "==", "~=", "<=", ">=", "<<", ">>", "//", "::"]


def lua_tokens(src):
    """Return list of (kind, text, start, end). kind: name, kw, num, str, op, comment."""
    toks = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c in " \t\r\n\f\v":
            i += 1
            continue
        if src.startswith("--", i):
            m = _long_bracket.match(src, i + 2)
            if m:
                close = "]" + m.group(1) + "]"
                j = src.find(close, m.end())
                j = n if j < 0 else j + len(close)
            else:
                j = src.find("\n", i)
                j = n if j < 0 else j
            toks.append(("comment", src[i:j], i, j))
            i = j
            continue
        if c == "[":
            m = _long_bracket.match(src, i)
            if m:
                close = "]" + m.group(1) + "]"
                j = src.find(close, m.end())
                if j < 0:
                    raise MergeError("unterminated long string at offset %d" % i)
                j += len(close)
                toks.append(("str", src[i:j], i, j))
                i = j
                continue
        if c in "\"'":
            j = i + 1
            while j < n and src[j] != c:
                if src[j] == "\\":
                    j += 1
                elif src[j] == "\n":
                    raise MergeError("unterminated string at offset %d" % i)
                j += 1
            j += 1
            toks.append(("str", src[i:j], i, j))
            i = j
            continue
        m = _name.match(src, i)
        if m:
            t = m.group(0)
            toks.append(("kw" if t in LUA_KEYWORDS else "name", t, i, m.end()))
            i = m.end()
            continue
        if c.isdigit() or (c == "." and i + 1 < n and src[i + 1].isdigit()):
            m = _number.match(src, i)
            toks.append(("num", m.group(0), i, m.end()))
            i = m.end()
            continue
        for op in _ops:
            if src.startswith(op, i):
                toks.append(("op", op, i, i + len(op)))
                i += len(op)
                break
        else:
            toks.append(("op", c, i, i + 1))
            i += 1
    return toks


def _match_forward(code, k):
    """code[k] is '(' / '[' / '{'; return index of the matching closer."""
    pairs = {"(": ")", "[": "]", "{": "}"}
    stack = [pairs[code[k][1]]]
    j = k + 1
    while j < len(code):
        t = code[j][1] if code[j][0] == "op" else None
        if t in pairs:
            stack.append(pairs[t])
        elif t in (")", "]", "}"):
            if t != stack[-1]:
                raise MergeError("unbalanced brackets near offset %d" % code[j][2])
            stack.pop()
            if not stack:
                return j
        j += 1
    raise MergeError("unbalanced brackets near offset %d" % code[k][2])


def _match_backward(code, k):
    """code[k] is ')' / ']' / '}'; return index of the matching opener."""
    pairs = {")": "(", "]": "[", "}": "{"}
    stack = [pairs[code[k][1]]]
    j = k - 1
    while j >= 0:
        t = code[j][1] if code[j][0] == "op" else None
        if t in pairs:
            stack.append(pairs[t])
        elif t in ("(", "[", "{"):
            if t != stack[-1]:
                raise MergeError("unbalanced brackets near offset %d" % code[j][2])
            stack.pop()
            if not stack:
                return j
        j -= 1
    raise MergeError("unbalanced brackets near offset %d" % code[k][2])


def _receiver_start(code, k):
    """code[k] is the last token of a suffixed expression (e.g. the ')' of
    'valueObject:getControl()'). Return the index of its first token."""
    j = k
    while True:
        kind, text = code[j][0], code[j][1]
        if kind == "op" and text in (")", "]"):
            o = _match_backward(code, j)
            prev = code[o - 1] if o > 0 else None
            if text == "]" or (prev and (prev[0] == "name" or
                                         (prev[0] == "op" and prev[1] in (")", "]")) or
                                         prev[0] == "str")):
                j = o - 1            # call / index suffix: continue with what precedes
                continue
            return o                 # parenthesised primary expression
        if kind == "str":            # f"..." call argument or string primary
            prev = code[j - 1] if j > 0 else None
            if prev and prev[0] == "name":
                j -= 1
                continue
            return j
        if kind == "name":
            prev = code[j - 1] if j > 0 else None
            if prev and prev[0] == "op" and prev[1] in (".", ":"):
                j -= 2
                continue
            return j
        raise MergeError("cannot find receiver of method call near offset %d" % code[k][2])


def find_global_func_spans(src):
    """Return dict name -> (start_offset, end_offset, normalized_body) for top-level global functions."""
    toks = [t for t in lua_tokens(src) if t[0] != "comment"]
    res = OrderedDict()
    i = 0
    depth = 0
    while i < len(toks):
        kind, text, s, e = toks[i]
        if kind == "kw" and text in ("function", "if", "for", "while", "do"):
            if text == "function" and depth == 0:
                is_local = (i > 0 and toks[i - 1][1] == "local")
                if not is_local and i + 2 < len(toks) and toks[i + 1][0] == "name" and toks[i + 2][1] == "(":
                    fname = toks[i + 1][1]
                    fstart = s
                    d = 1
                    j = i + 2
                    while j < len(toks) and d > 0:
                        k2, t2, _, _ = toks[j]
                        if k2 == "kw":
                            if t2 in ("function", "if", "do"):
                                d += 1
                            elif t2 == "end":
                                d -= 1
                        j += 1
                    fend = toks[j - 1][3]
                    norm = " ".join(t[1] for t in toks[i:j]).replace("_valueObject", "valueObject")
                    res[fname] = (fstart, fend, norm)
                    i = j
                    continue
            if text in ("function", "if", "do"):
                depth += 1
        elif kind == "kw" and text == "end":
            depth -= 1
        i += 1
    return res


def find_shared_table_spans(src, names=("MODSRC1", "MODSRC2", "NOTE_NAMES")):
    """Return dict name -> (start_offset, end_offset, normalized_body) for top-level table definitions."""
    toks = [t for t in lua_tokens(src) if t[0] != "comment"]
    res = OrderedDict()
    for k, (kind, text, s, e) in enumerate(toks):
        if kind == "name" and text in names and k + 2 < len(toks) and toks[k + 1][1] == "=" and toks[k + 2][1] == "{":
            start_tok = k - 1 if (k > 0 and toks[k - 1][1] == "local") else k
            close_tok = _match_forward(toks, k + 2)
            norm = " ".join(t[1] for t in toks[k + 2:close_tok + 1])
            res[text] = (toks[start_tok][2], toks[close_tok][3], norm)
    return res


def rewrite_module_lua(src, strip_comments=False, drop_spans=()):
    """Rewrite ':getId()'      -> '__LID(<recv>:getId())'
               ':setOverlayId(x)' -> ':setOverlayId(__OV(x))'
    and remove any byte ranges in drop_spans (duplicate functions / tables).
    Returns (new_source, stats)."""
    toks = lua_tokens(src)
    code = [t for t in toks if t[0] != "comment"]
    inserts = []  # (offset, text)
    stats = {"getId": 0, "setOverlayId": 0, "dedup": len(drop_spans)}

    def in_dropped(pos):
        return any(ds <= pos < de for ds, de in drop_spans)

    for k, (kind, text, s, e) in enumerate(code):
        if in_dropped(s):
            continue
        if kind != "name" or k == 0 or code[k - 1][1] != ":" or code[k - 1][0] != "op":
            continue
        if k + 1 >= len(code) or code[k + 1][1] != "(":
            continue
        if text == "getId":
            close = _match_forward(code, k + 1)
            start = _receiver_start(code, k - 2)
            inserts.append((code[start][2], "__LID("))
            inserts.append((code[close][3], ")"))
            stats["getId"] += 1
        elif text == "setOverlayId":
            close = _match_forward(code, k + 1)
            inserts.append((code[k + 1][3], "__OV("))
            inserts.append((code[close][2], ")"))
            stats["setOverlayId"] += 1
    for ds, de in drop_spans:
        inserts.append((ds, ("\0DEL", de)))
    if strip_comments:
        for kind, text, s, e in toks:
            if kind == "comment" and not in_dropped(s):
                inserts.append((s, ("\0DEL", e)))
    offs = [o for o, t in inserts if not isinstance(t, tuple)]
    if len(offs) != len(set(offs)):
        raise MergeError("nested getId()/setOverlayId() rewrite at the same position - "
                         "split the expression into a local variable")
    # apply from the back
    out = src
    for off, txt in sorted(inserts, key=lambda x: x[0], reverse=True):
        if isinstance(txt, tuple):
            out = out[:off] + out[txt[1]:]
        else:
            out = out[:off] + txt + out[off:]
    out = re.sub(r"[ \t]+(\r?\n)", r"\1", out)
    out = re.sub(r"(\r?\n){3,}", "\n\n", out)
    return out, stats


def lua_defined_globals(src):
    """Names defined as 'function NAME(' or 'NAME = function' at any level, not local."""
    names = set()
    code = [t for t in lua_tokens(src) if t[0] != "comment"]
    for k, t in enumerate(code):
        if t[0] == "kw" and t[1] == "function" and k + 1 < len(code) and code[k + 1][0] == "name":
            if k > 0 and code[k - 1][1] == "local":
                continue
            if k + 2 < len(code) and code[k + 2][1] in ("(",):
                names.add(code[k + 1][1])
        if t[0] == "name" and k + 2 < len(code) and code[k + 1][1] == "=" and \
                code[k + 2][1] == "function" and (k == 0 or code[k - 1][1] not in (".", ":", "local", ",")):
            names.add(t[1])
    return names


def lua_uses(src, table, field):
    code = [t for t in lua_tokens(src) if t[0] != "comment"]
    for k in range(len(code) - 2):
        if code[k][1] == table and code[k + 1][1] == "." and code[k + 2][1] == field:
            return True
    return False


# --------------------------------------------------------------------------
# JSON merge
# --------------------------------------------------------------------------

def extract_lua_overlays(lua_path):
    """Run the module's main.lua in a minimal sandbox with lua5.4 and capture
    every overlays.create(id, items) call made at load time or in preset.onLoad()."""
    if not lua_path.is_file():
        return OrderedDict()
    lua_bin = shutil.which("lua5.4") or shutil.which("lua")
    if not lua_bin:
        return OrderedDict()
    code = """
    local ovs, order = {}, {}
    local function noop() end
    local dummy = setmetatable({}, { __index = function() return noop end })
    _G.preset = { getControl = function() return dummy end, getGroup = function() return dummy end,
                  getDevice = function() return dummy end }
    _G.controls = { get = function() return dummy end }
    _G.groups = { get = function() return dummy end }
    _G.overlays = { get = function() return dummy end, create = function(id, items)
        if not ovs[id] then order[#order + 1] = id end
        ovs[id] = items
        return dummy
    end }
    _G.pages = { get = function() return dummy end, display = noop }
    _G.midi = { sendSysex = noop }
    _G.timer = { enable = noop, disable = noop, setPeriod = noop }
    _G.window = { stop = noop, resume = noop }
    _G.info = { setText = noop }
    dofile(%s)
    if type(preset.onLoad) == "function" then pcall(preset.onLoad) end
    for _, id in ipairs(order) do
        local items = ovs[id]
        local parts = {}
        for i, it in ipairs(items) do
            parts[i] = string.format("{\\"value\\":%%d,\\"label\\":%%q}", it.value, it.label)
        end
        print(id .. "\\t[" .. table.concat(parts, ",") .. "]")
    end
    """ % json.dumps(str(lua_path))
    r = subprocess.run([lua_bin, "-e", code], capture_output=True, text=True, timeout=10)
    if r.returncode != 0:
        raise MergeError("%s: failed to extract Lua overlays: %s" % (lua_path, r.stderr.strip()))
    out = OrderedDict()
    for line in r.stdout.splitlines():
        oid, raw = line.split("\t", 1)
        out[int(oid)] = json.loads(raw, object_pairs_hook=OrderedDict)
    return out


def load_module(root, name):
    d = root / name
    pj = d / "preset.json"
    ml = d / "main.lua"
    if not pj.is_file():
        raise MergeError("%s: preset.json not found" % d)
    with open(pj, encoding="utf-8") as f:
        data = json.load(f, object_pairs_hook=OrderedDict)
    lua = ml.read_text(encoding="utf-8") if ml.is_file() else ""
    lua_overlays = extract_lua_overlays(ml)
    return {"name": name, "dir": d, "json": data, "lua": lua, "lua_overlays": lua_overlays}


def validate_module(m, warnings):
    """Check a module on its own before merging."""
    p = m["json"]
    name = m["name"]
    errs = []
    if p.get("version") not in (2, 3):
        errs.append("version must be 2 or 3")
    page_ids = [pg.get("id") for pg in p.get("pages", [])]
    if len(set(page_ids)) != len(page_ids):
        errs.append("duplicate page ids %s" % page_ids)
    ids = {}
    for kind in ("groups", "controls"):
        for o in p.get(kind, []):
            i = o.get("id")
            if i in ids:
                errs.append("%s id %s already used by a %s (shared id space)" % (kind[:-1], i, ids[i]))
            ids[i] = kind[:-1]
            if o.get("pageId", 1) not in page_ids:
                errs.append("%s %s: pageId %s does not exist" % (kind[:-1], i, o.get("pageId")))
    ov_ids = [o.get("id") for o in p.get("overlays", [])]
    if len(set(ov_ids)) != len(ov_ids):
        errs.append("duplicate overlay ids")
    params = {}
    for c in p.get("controls", []):
        for v in c.get("values", []):
            if "overlayId" in v and v["overlayId"] not in ov_ids:
                warnings.append("%s: control %s refers to overlay %s which is only created in Lua"
                                % (name, c["id"], v["overlayId"]))
            msg = v.get("message", {})
            key = (msg.get("deviceId", 1), msg.get("type"), msg.get("parameterNumber"))
            if msg.get("type") in ("virtual", "none") and key in params:
                warnings.append("%s: controls %s and %s share virtual parameter %s (kept shared)"
                                % (name, params[key], c["id"], key[2]))
            params.setdefault(key, c["id"])
    if errs:
        raise MergeError("%s/preset.json:\n    " % name + "\n    ".join(errs))


def device_key(dev):
    return json.dumps({k: v for k, v in dev.items() if k != "id"}, sort_keys=True)


def make_project_id(seed):
    alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    h = int(hashlib.sha256(seed.encode()).hexdigest(), 16)
    out = []
    for _ in range(20):
        h, r = divmod(h, 62)
        out.append(alphabet[r])
    return "".join(out)


def callback_names(value):
    """Yield (container, key) pairs holding Lua function names inside a value."""
    for key in ("function", "formatter"):
        if isinstance(value.get(key), str) and value[key]:
            yield value, key


def merge(modules, name, project_id, warnings):
    merged = OrderedDict()
    merged["version"] = 3
    merged["name"] = name
    merged["projectId"] = project_id
    merged["pages"] = []
    merged["devices"] = []
    merged["overlays"] = []
    merged["groups"] = []
    merged["controls"] = []

    first = modules[0]["json"]
    for k, v in first.items():           # keep extra top-level keys (e.g. targetDevice)
        if k not in merged:
            merged[k] = v

    next_page = 1
    next_id = 1                          # shared control / group id counter
    next_ovl = 1
    next_param = {}                      # (deviceId, type) -> next free parameterNumber
    dev_by_key = {}
    ov_by_key = {}                       # canonical items JSON -> merged overlay id
    all_func_names = {}                  # new name -> (module, original)
    func_by_body = {}                    # normalized global function body -> exported callback name

    def register_overlay(items, in_json=True):
        nonlocal next_ovl
        key = json.dumps(items, sort_keys=True)
        if key not in ov_by_key:
            gid = next_ovl
            next_ovl += 1
            ov_by_key[key] = gid
            if in_json:
                no = OrderedDict()
                no["id"] = gid
                no["items"] = json.loads(json.dumps(items), object_pairs_hook=OrderedDict)
                merged["overlays"].append(no)
        return ov_by_key[key]

    for m in modules:
        p = m["json"]
        prefix = PREFIXES.get(m["name"]) or re.sub(r"[^a-z0-9]", "", m["name"].replace("z1-", ""))[:3]
        m["prefix"] = prefix
        m["func_spans"] = find_global_func_spans(m["lua"])
        m["table_spans"] = find_shared_table_spans(m["lua"])
        pmap, cmap, omap, dmap, fmap, parmap = {}, {}, {}, {}, OrderedDict(), {}
        reused_funcs = {}

        # Real overlay items: JSON overlays overridden by runtime overlays.create() from main.lua
        real_ov = OrderedDict()
        for o in p.get("overlays", []):
            real_ov[o["id"]] = o.get("items", [])
        for oid, items in m.get("lua_overlays", {}).items():
            real_ov[oid] = items
        m["real_overlays"] = real_ov

        # pages
        for pg in p.get("pages", []):
            pmap[pg["id"]] = next_page
            npg = OrderedDict(pg)
            npg["id"] = next_page
            merged["pages"].append(npg)
            next_page += 1

        # devices (identical definitions are shared)
        for dev in p.get("devices", []):
            key = device_key(dev)
            if key not in dev_by_key:
                gid = len(dev_by_key) + 1
                dev_by_key[key] = gid
                nd = OrderedDict(dev)
                nd["id"] = gid
                merged["devices"].append(nd)
            dmap[dev["id"]] = dev_by_key[key]

        # groups and controls share one id space
        for g in p.get("groups", []):
            cmap[g["id"]] = next_id
            ng = OrderedDict(g)
            ng["id"] = next_id
            ng["pageId"] = pmap[g.get("pageId", 1)]
            merged["groups"].append(ng)
            next_id += 1
        for c in p.get("controls", []):
            cmap[c["id"]] = next_id
            next_id += 1

        def rename(fn):
            if fn in fmap:
                return fmap[fn]
            if fn in reused_funcs:
                return reused_funcs[fn]
            span = m["func_spans"].get(fn)
            if span and span[2] in func_by_body:
                reused_funcs[fn] = func_by_body[span[2]]
                return reused_funcs[fn]
            new = "%s_%s" % (prefix, fn)
            if len(new) > MAX_FUNCTION_NAME:
                new = "%s_f%d" % (prefix, len(fmap) + 1)
            if new in all_func_names:
                raise MergeError("function name clash: %s" % new)
            fmap[fn] = new
            all_func_names[new] = (m["name"], fn)
            if span:
                func_by_body[span[2]] = new
            return new

        for c in p.get("controls", []):
            nc = json.loads(json.dumps(c), object_pairs_hook=OrderedDict)
            nc["id"] = cmap[c["id"]]
            nc["pageId"] = pmap[c.get("pageId", 1)]
            for v in nc.get("values", []):
                if "overlayId" in v:
                    lid = v["overlayId"]
                    if lid not in omap:
                        if lid not in real_ov:
                            raise MergeError("%s: control %s refers to unknown overlay %s"
                                             % (m["name"], c["id"], lid))
                        omap[lid] = register_overlay(real_ov[lid])
                    v["overlayId"] = omap[lid]
                for holder, key in callback_names(v):
                    holder[key] = rename(holder[key])
                msg = v.get("message")
                if isinstance(msg, dict):
                    if "deviceId" in msg and msg["deviceId"] in dmap:
                        msg["deviceId"] = dmap[msg["deviceId"]]
                    if msg.get("type") in ("virtual", "none") and isinstance(msg.get("parameterNumber"), int):
                        pk = (msg.get("deviceId", 1), msg["type"], msg["parameterNumber"])
                        if pk not in parmap:
                            nk = (pk[0], pk[1])
                            parmap[pk] = next_param.get(nk, 1)
                            next_param[nk] = parmap[pk] + 1
                        msg["parameterNumber"] = parmap[pk]
            for ev in nc.get("events", []) or []:
                for act in ev.get("actions", []) if isinstance(ev, dict) else []:
                    if act.get("type") == "lua" and act.get("function"):
                        act["function"] = rename(act["function"])
                    if isinstance(act.get("message"), dict) and isinstance(act["message"].get("value"), str):
                        act["message"]["value"] = rename(act["message"]["value"])
            if nc.get("type") == "custom" and nc.get("paintFunction"):
                nc["paintFunction"] = rename(nc["paintFunction"])
            merged["controls"].append(nc)

        m.update(pmap=pmap, cmap=cmap, omap=omap, fmap=fmap, reused_funcs=reused_funcs, parmap=parmap)

    # Second pass: assign ids for dynamic Lua-only overlays (not statically on any control in JSON).
    # We do NOT write unreferenced overlays into preset.z1.json (the Preset Editor strips them anyway);
    # instead main.z1.lua creates them once via overlays.create() in preset.onLoad().
    for m in modules:
        omap = m["omap"]
        for lid, items in m.get("lua_overlays", {}).items():
            if lid not in omap:
                omap[lid] = register_overlay(items, in_json=False)

    # ---- limits -------------------------------------------------------------
    errs = []
    if len(merged["pages"]) > MAX_PAGE_ID:
        errs.append("%d pages, the mk2 maximum page id is %d (pages above it are dropped)"
                    % (len(merged["pages"]), MAX_PAGE_ID))
    if next_id - 1 > MAX_CONTROL_GROUP_ID:
        errs.append("%d control+group ids, the Lua API / editor range is 1..%d"
                    % (next_id - 1, MAX_CONTROL_GROUP_ID))
    if next_ovl - 1 > MAX_OVERLAY_ID:
        errs.append("%d overlays, overlay ids are one byte (max %d)" % (next_ovl - 1, MAX_OVERLAY_ID))
    for (dev, typ), nxt in next_param.items():
        if nxt - 1 > MAX_PARAMETER_NUMBER:
            errs.append("virtual parameterNumber %d > %d" % (nxt - 1, MAX_PARAMETER_NUMBER))
    if len(all_func_names) > MAX_FUNCTION_NAMES:
        errs.append("%d distinct function names (max %d)" % (len(all_func_names), MAX_FUNCTION_NAMES))
    if len(merged["devices"]) > 32:
        errs.append("more than 32 devices")
    if len(name) > MAX_NAME:
        errs.append("preset name longer than %d characters" % MAX_NAME)
    if errs:
        raise MergeError("merged preset violates the preset format:\n    " + "\n    ".join(errs))
    if len(merged["controls"]) > MAX_CONTROLS:
        warnings.append("%d controls: more than %d (the limit of Lua controls.create). The reader "
                        "itself does not count controls, so the preset loads; just don't create "
                        "more controls from Lua." % (len(merged["controls"]), MAX_CONTROLS))
    # sanity: unique ids
    ids = [o["id"] for o in merged["groups"] + merged["controls"]]
    assert len(ids) == len(set(ids))
    return merged, next_ovl


# --------------------------------------------------------------------------
# Lua merge
# --------------------------------------------------------------------------

def lua_table(d):
    return "{" + ",".join("[%d]=%d" % (k, v) for k, v in sorted(d.items())) + "}"


LUA_PRELUDE = r'''-- ==========================================================================
-- Korg Z1 for Electra One mk2 - merged main.lua
-- AUTO-GENERATED by merge_z1_presets.py from: %(modules)s
-- Do not edit this file; edit the module main.lua files and re-run the script.
--
-- Every module runs in its own environment (_ENV), so module globals never
-- collide. Inside a module, ids are the module's own (local) ids: the API
-- functions below translate them to the ids of the merged preset.json.
-- ==========================================================================

local __REAL = {}
for _, n in ipairs({%(tables)s}) do __REAL[n] = _G[n] end
local __realRecall = _G.recall

local __ovPreloaded = %(ovnext)d - 1 -- overlays 1..__ovPreloaded are already in preset.z1.json
local __ovNext = %(ovnext)d          -- next free overlay id (overlays created only in Lua)
local __ovCreated = {}              -- runtime-created overlay ids
local __hookModules = {}            -- "table.key" -> list of module hook tables
local __hookList = {}               -- ordered list of { tableName, key }

local __winDepth = 0
local function __winStop()
    if __winDepth == 0 and __REAL.window and __REAL.window.stop then
        __REAL.window.stop()
    end
    __winDepth = __winDepth + 1
end
local function __winResume()
    if __winDepth > 0 then
        __winDepth = __winDepth - 1
        if __winDepth == 0 and __REAL.window and __REAL.window.resume then
            __REAL.window.resume()
        end
    end
end

local function __safeRecall(tbl)
    if type(__realRecall) == "function" then
        if type(_G.recallJson) == "function" and _G.recallJson() == nil then
            return
        end
        return __realRecall(tbl)
    end
end

local function __registerHook(tname, key, own)
    local hk = tname .. "." .. key
    local list = __hookModules[hk]
    if not list then
        list = {}
        __hookModules[hk] = list
        __hookList[#__hookList + 1] = { tname, key }
    end
    for _, o in ipairs(list) do
        if o == own then return end
    end
    list[#list + 1] = own
end

local __z1SyncDepth = 0

local function __trackOutgoingSysex(body)
    if type(body) == "table" and #body == 9
       and body[1] == 0x42 and (body[2] & 0xF0) == 0x30 and body[3] == 0x46
       and body[4] == 0x41 and body[5] == 0x01
       and not _G.__z1InUndoRedo and __z1SyncDepth == 0
       and type(_G.recordZ1ParamChange) == "function" then
        local id14 = (body[6] & 0x7F) | ((body[7] & 0x7F) << 7)
        local exId = (id14 >> 11) & 0x07
        local paramId = id14 & 0x07FF
        local val14 = (body[8] & 0x7F) | ((body[9] & 0x7F) << 7)
        local signedVal = (val14 >= 0x2000) and (val14 - 0x4000) or val14
        _G.recordZ1ParamChange(exId, paramId, signedVal)
    end
end

local function __makeEnv(modName, C, O, P)
    local RC = {}
    for l, g in pairs(C) do RC[g] = l end
    local function ctl(id) return C[id] end
    local function ov(id)
        if id == nil then return nil end
        local g = O[id]
        if g == nil then
            g = __ovNext
            __ovNext = __ovNext + 1
            O[id] = g
        end
        return g
    end
    local function page(id) return P[id] end

    local over = {
        preset = {
            getControl = function(id) local g = ctl(id); if g then return __REAL.preset.getControl(g) end end,
            getGroup   = function(id) local g = ctl(id); if g then return __REAL.preset.getGroup(g) end end,
            getDevice  = function(id)
                local d = __REAL.preset.getDevice(id)
                if not d then return nil end
                return setmetatable({
                    sendSysex = function(_, body)
                        __trackOutgoingSysex(body)
                        return d:sendSysex(body)
                    end
                }, { __index = function(_, k)
                    local v = d[k]
                    if type(v) == "function" then
                        return function(_, ...) return v(d, ...) end
                    end
                    return v
                end })
            end,
        },
        midi = {
            sendSysex = function(port, body)
                __trackOutgoingSysex(body)
                return __REAL.midi.sendSysex(port, body)
            end,
        },
        controls = {
            get = function(id) local g = ctl(id); if g then return __REAL.controls.get(g) end end,
        },
        groups = {
            get = function(id) local g = ctl(id); if g then return __REAL.groups.get(g) end end,
        },
        overlays = {
            get    = function(id) return __REAL.overlays.get(ov(id)) end,
            create = function(id, ...)
                local gid = ov(id)
                if gid then
                    if __REAL.preset and __REAL.preset.getOverlay then
                        local existing = __REAL.preset.getOverlay(gid)
                        if existing then return existing end
                    elseif __ovCreated[gid] then
                        local ok, existing = pcall(__REAL.overlays.get, gid)
                        if ok and existing then return existing end
                    end
                    __ovCreated[gid] = true
                end
                return __REAL.overlays.create(gid, ...)
            end,
        },
        pages = {
            get     = function(id) local g = page(id); if g then return __REAL.pages.get(g) end end,
            display = function(id) local g = page(id); if g then return __REAL.pages.display(g) end end,
        },
        window = {
            stop   = __winStop,
            resume = __winResume,
        },
    }

    local env = setmetatable({ recall = __safeRecall }, { __index = _G })
    for tname, real in pairs(__REAL) do
        if type(real) == "table" then
            local own, o = {}, over[tname] or {}
            env[tname] = setmetatable({}, {
                __index = function(_, k)
                    local v = own[k]
                    if v ~= nil then return v end
                    v = o[k]
                    if v ~= nil then return v end
                    return real[k]
                end,
                __newindex = function(_, k, v)
                    own[k] = v                         -- e.g. function preset.onLoad()
                    if type(v) == "function" then __registerHook(tname, k, own) end
                end,
            })
        end
    end
    env.__LID = function(id)            -- merged id -> module id (control:getId())
        local l = RC[id]
        if l ~= nil then return l end
        return id
    end
    env.__OV = ov                       -- module overlay id -> merged overlay id
    env.__MODULE = modName
    return env
end

local function __export(env, newName, oldName)
    local isFmt = (oldName:sub(1, 3) == "fmt")
    _G[newName] = function(...)
        if __z1SyncDepth > 0 and not isFmt then return end
        local f = env[oldName]
        if f then return f(...) end
    end
end

'''

LUA_POSTLUDE = r'''
-- ==========================================================================
-- Chain the lifecycle / event hooks of all modules
-- (preset.onLoad, preset.onReady, midi.onSysex, timer.onTick, ...)
-- ==========================================================================
for _, h in ipairs(__hookList) do
    local tname, key = h[1], h[2]
    local list = __hookModules[tname .. "." .. key]
    local batchWindow = (tname == "preset" and (key == "onLoad" or key == "onReady" or key == "onZ1Dump"))
    local syncGuard = (tname == "preset" and (key == "onZ1Dump" or key == "onZ1Param"))
    __REAL[tname][key] = function(...)
        if batchWindow then __winStop() end
        if syncGuard then __z1SyncDepth = __z1SyncDepth + 1 end
        local result
        for _, own in ipairs(list) do
            local f = own[key]
            if f then
                local ok, r = pcall(f, ...)
                if not ok then
                    print("Z1 merged: error in " .. tname .. "." .. key .. ": " .. tostring(r))
                elseif result == nil then
                    result = r
                end
            end
        end
        if syncGuard then __z1SyncDepth = __z1SyncDepth - 1 end
        if batchWindow then __winResume() end
        return result
    end
end
'''


def build_lua(modules, ov_next, strip_comments, warnings):
    parts = [LUA_PRELUDE % {
        "modules": ", ".join(m["name"] for m in modules),
        "tables": ", ".join('"%s"' % t for t in SHIMMED_TABLES),
        "ovnext": ov_next,
    }]
    seen_tables = {}      # name -> normalized_body
    seen_helper_funcs = {}  # (name, normalized_body) -> first_module_env_export
    for m in modules:
        src = m["lua"]
        if not src.strip():
            warnings.append("%s: no main.lua" % m["name"])
        if lua_uses(src, "parameterMap", "get") or lua_uses(src, "parameterMap", "set") \
                or lua_uses(src, "parameterMap", "onChange"):
            warnings.append("%s: uses parameterMap - virtual parameter numbers were renumbered, "
                            "check this code" % m["name"])
        defined = lua_defined_globals(src)
        for old, new in m["fmap"].items():
            if old not in defined:
                warnings.append("%s: callback '%s' used in preset.json is not defined in main.lua"
                                % (m["name"], old))

        drop_spans = []
        promote_globals = []
        # 1. Deduplicate shared top-level tables (MODSRC1, MODSRC2, NOTE_NAMES)
        for tname, (ts, te, tnorm) in m.get("table_spans", {}).items():
            if tname not in seen_tables:
                seen_tables[tname] = tnorm
                if src[ts:ts + 5] == "local":
                    drop_spans.append((ts, ts + 5))
                promote_globals.append((tname, tname))
            elif seen_tables[tname] == tnorm:
                drop_spans.append((ts, te))

        # 2. Deduplicate identical global functions across modules (callbacks & helpers like buildParamChangeBody)
        for fname, (fs, fe, fnorm) in m.get("func_spans", {}).items():
            if fname in m.get("reused_funcs", {}):
                drop_spans.append((fs, fe))
            elif fname not in m["fmap"]:
                key = (fname, fnorm)
                if key in seen_helper_funcs or (fname == "buildParamChangeBody" and "buildParamChangeBody" in seen_tables):
                    drop_spans.append((fs, fe))
                else:
                    seen_helper_funcs[key] = m["name"]
                    promote_globals.append((fname, fname))
                    if fname == "buildParamChangeBody" and "signedVal == nil" in fnorm:
                        seen_tables["buildParamChangeBody"] = True

        body, stats = rewrite_module_lua(src, strip_comments, drop_spans=drop_spans)
        m["lua_stats"] = stats
        fn = "__module_" + re.sub(r"[^A-Za-z0-9_]", "_", m["name"])
        parts.append("-- " + "=" * 74 + "\n-- module %s  (prefix %s_)\n-- " % (m["name"], m["prefix"])
                     + "=" * 74 + "\n")
        parts.append("local function %s(_ENV)\n%s\nend\n\n" % (fn, body.rstrip()))
        parts.append("do\n")
        parts.append("    local env = __makeEnv(%s,\n        %s,\n        %s,\n        %s)\n"
                     % (json.dumps(m["name"]), lua_table(m["cmap"]), lua_table(m["omap"]),
                        lua_table(m["pmap"])))
        for old, reused_new in m.get("reused_funcs", {}).items():
            parts.append('    env.%s = function(...) return _G["%s"](...) end\n' % (old, reused_new))
        parts.append("    local ok, err = pcall(%s, env)\n" % fn)
        parts.append('    if not ok then print("Z1 merged: error loading %s: " .. tostring(err)) end\n'
                     % m["name"])
        for gname, lkup in promote_globals:
            parts.append('    if rawget(_G, "%s") == nil then _G.%s = env.%s end\n' % (gname, gname, lkup))
        for old, new in m["fmap"].items():
            parts.append('    __export(env, "%s", "%s")\n' % (new, old))
        parts.append("end\n\n")
    parts.append(LUA_POSTLUDE)
    return "".join(parts)


# --------------------------------------------------------------------------
# main
# --------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", default=str(Path(__file__).resolve().parent),
                    help="folder containing the z1-* module folders")
    ap.add_argument("--modules", nargs="+", default=DEFAULT_MODULES, help="modules in page order")
    ap.add_argument("-o", "--output", default="preset.z1.json", help="merged preset (default preset.z1.json)")
    ap.add_argument("--lua-output", default="main.z1.lua", help="merged Lua script (default main.z1.lua)")
    ap.add_argument("--name", default="Korg Z1", help="preset name (max 20 chars)")
    ap.add_argument("--project-id", default=None, help="projectId (default: derived from module list)")
    ap.add_argument("--pretty", action="store_true", help="write indented JSON instead of minified")
    ap.add_argument("--strip-comments", action="store_true", help="remove Lua comments from main.z1.lua")
    ap.add_argument("--check", action="store_true", help="analyse only, write nothing")
    args = ap.parse_args()

    root = Path(args.root)
    warnings = []
    try:
        modules = [load_module(root, n.rstrip("/")) for n in args.modules]
        for m in modules:
            validate_module(m, warnings)
        project_id = args.project_id or make_project_id("korg-z1-merged:" + ",".join(args.modules))
        merged, ov_next = merge(modules, args.name, project_id, warnings)
        lua = build_lua(modules, ov_next, args.strip_comments, warnings)
    except MergeError as e:
        print("ERROR: %s" % e, file=sys.stderr)
        return 1

    if args.pretty:
        text = json.dumps(merged, indent=2, ensure_ascii=False) + "\n"
    else:
        text = json.dumps(merged, separators=(",", ":"), ensure_ascii=False)
    if len(text.encode("utf-8")) > MAX_FILE_SIZE:
        print("ERROR: merged preset is %d bytes, maximum is %d" % (len(text.encode()), MAX_FILE_SIZE),
              file=sys.stderr)
        return 1

    print("%-16s %-4s %-6s %-9s %-8s %-9s %-7s %s" %
          ("module", "pfx", "pages", "ctrl+grp", "overlay", "params", "funcs", "lua rewrites"))
    for m in modules:
        pr = sorted(m["parmap"].values())
        print("%-16s %-4s %-6s %-9s %-8s %-9s %-7d getId=%d setOverlayId=%d dedup=%d" % (
            m["name"], m["prefix"],
            "%d-%d" % (min(m["pmap"].values()), max(m["pmap"].values())),
            "%d-%d" % (min(m["cmap"].values()), max(m["cmap"].values())),
            "%d-%d" % (min(m["omap"].values()), max(m["omap"].values())) if m["omap"] else "-",
            "%d-%d" % (pr[0], pr[-1]) if pr else "-",
            len(m["fmap"]), m["lua_stats"]["getId"], m["lua_stats"]["setOverlayId"], m["lua_stats"]["dedup"]))
    print("total: %d pages, %d groups, %d controls, %d overlays, %d devices, %d bytes JSON, %d bytes Lua" % (
        len(merged["pages"]), len(merged["groups"]), len(merged["controls"]),
        len(merged["overlays"]), len(merged["devices"]), len(text.encode()), len(lua.encode())))
    for w in warnings:
        print("WARNING: " + w)

    if args.check:
        return 0
    out = Path(args.output)
    lout = Path(args.lua_output)
    out.write_text(text, encoding="utf-8")
    lout.write_text(lua, encoding="utf-8")
    print("wrote %s and %s" % (out, lout))
    return 0


if __name__ == "__main__":
    sys.exit(main())
