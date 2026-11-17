#!/usr/bin/env python3
"""
Upgrade Electra One preset.json files from preset format version 2 to version 3.

Background
----------
Electra One preset format v3 is a superset of v2: the top-level structure
(pages, groups, devices, overlays, controls) and all keys used by v2 presets
are unchanged. v3 only *adds* optional features (control "variant",
control "events", group "variant"/"font", ...). So upgrading a v2 preset
means:

  1. validating that the preset is structurally sound (so the v3 parser on the
     device / in the editor will accept it), and
  2. changing the top-level "version" from 2 to 3.

The file is rewritten byte-for-byte identical except for the version number
(no re-formatting, no key re-ordering, escapes such as \\u0026 are kept), so
git diffs stay minimal.

Usage
-----
  ./upgrade_presets_v3.py                 # upgrade all presets under this folder
  ./upgrade_presets_v3.py --dry-run       # only report what would happen
  ./upgrade_presets_v3.py --check         # validate only, exit 1 on problems
  ./upgrade_presets_v3.py z1-eg/preset.json z1-lfo/preset.json
  ./upgrade_presets_v3.py --no-backup     # don't write preset.json.v2.bak files

Folders that are not presets (z1-signalflow, z1-filterwidget, z1-mixerwidget)
are skipped automatically when scanning.
"""

import argparse
import json
import re
import shutil
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
EXCLUDED_DIRS = {"z1-signalflow", "z1-filterwidget", "z1-mixerwidget"}

REQUIRED_TOP_LEVEL = ("version", "name", "projectId", "pages", "devices", "controls")
KNOWN_CONTROL_TYPES = {
    "fader", "list", "pad", "adsr", "adr", "dx7envelope", "custom", "text",
    "group",
}
KNOWN_PAD_MODES = {"", "momentary", "toggle"}

VERSION_RE = re.compile(r'^(\s*\{\s*"version"\s*:\s*)2(?=\s*[,}])')


class Report:
    def __init__(self, path):
        self.path = path
        self.errors = []
        self.warnings = []

    def err(self, msg):
        self.errors.append(msg)

    def warn(self, msg):
        self.warnings.append(msg)


def check_unique_ids(rep, items, what):
    ids = set()
    for i, item in enumerate(items):
        if not isinstance(item, dict) or "id" not in item:
            rep.err(f"{what}[{i}] has no 'id'")
            continue
        if item["id"] in ids:
            rep.err(f"duplicate {what} id {item['id']!r}")
        ids.add(item["id"])
    return ids


def check_bounds(rep, obj, where):
    b = obj.get("bounds")
    if b is None:
        return
    if not (isinstance(b, list) and len(b) == 4 and all(isinstance(n, int) for n in b)):
        rep.err(f"{where}: 'bounds' must be 4 integers, got {b!r}")


def validate(doc, rep):
    if not isinstance(doc, dict):
        rep.err("top level is not a JSON object")
        return

    for key in REQUIRED_TOP_LEVEL:
        if key not in doc:
            rep.err(f"missing top-level key '{key}'")
    if rep.errors:
        return

    if doc.get("targetDevice") not in (None, "mk1", "mk2", "mini"):
        rep.warn(f"unusual targetDevice {doc.get('targetDevice')!r}")

    page_ids = check_unique_ids(rep, doc.get("pages", []), "page")
    device_ids = check_unique_ids(rep, doc.get("devices", []), "device")
    overlay_ids = check_unique_ids(rep, doc.get("overlays", []), "overlay")
    check_unique_ids(rep, doc.get("groups", []), "group")
    check_unique_ids(rep, doc.get("controls", []), "control")

    for g in doc.get("groups", []):
        where = f"group {g.get('id')}"
        if g.get("pageId") not in page_ids:
            rep.err(f"{where}: pageId {g.get('pageId')!r} does not exist")
        check_bounds(rep, g, where)

    for ov in doc.get("overlays", []):
        values = [it.get("value") for it in ov.get("items", [])]
        if len(values) != len(set(values)):
            rep.warn(f"overlay {ov.get('id')}: duplicate item values")

    for c in doc.get("controls", []):
        where = f"control {c.get('id')} ({c.get('name', '')!r})"
        ctype = c.get("type")
        if ctype not in KNOWN_CONTROL_TYPES:
            rep.warn(f"{where}: unknown control type {ctype!r}")
        if c.get("pageId") not in page_ids:
            rep.err(f"{where}: pageId {c.get('pageId')!r} does not exist")
        cs = c.get("controlSetId")
        if cs is not None and cs not in (1, 2, 3):
            rep.err(f"{where}: controlSetId {cs!r} must be 1..3")
        check_bounds(rep, c, where)
        if ctype == "pad" and c.get("mode") not in (None, *KNOWN_PAD_MODES):
            rep.warn(f"{where}: unusual pad mode {c.get('mode')!r}")

        value_ids = set()
        for v in c.get("values", []):
            vid = v.get("id", "value")
            if vid in value_ids:
                rep.err(f"{where}: duplicate value id {vid!r}")
            value_ids.add(vid)
            if "overlayId" in v and v["overlayId"] not in overlay_ids:
                rep.err(f"{where}: value {vid!r} overlayId {v['overlayId']!r} does not exist")
            if "min" in v and "max" in v and v["min"] > v["max"]:
                rep.warn(f"{where}: value {vid!r} min > max")
            msg = v.get("message")
            if isinstance(msg, dict) and "deviceId" in msg and msg["deviceId"] not in device_ids:
                rep.err(f"{where}: value {vid!r} deviceId {msg['deviceId']!r} does not exist")

        for inp in c.get("inputs", []):
            pot = inp.get("potId")
            if not isinstance(pot, int) or not 1 <= pot <= 12:
                rep.err(f"{where}: input potId {pot!r} must be 1..12")
            if inp.get("valueId", "value") not in value_ids:
                rep.err(f"{where}: input valueId {inp.get('valueId')!r} has no matching value")


def process(path, args):
    rep = Report(path)
    text = path.read_text(encoding="utf-8")
    try:
        doc = json.loads(text)
    except json.JSONDecodeError as e:
        rep.err(f"invalid JSON: {e}")
        return rep, "error"

    if isinstance(doc, dict) and "schemaVersion" in doc:
        return rep, "skip (editor project/widget format, not a preset)"

    version = doc.get("version") if isinstance(doc, dict) else None
    if version == 3:
        validate(doc, rep)
        return rep, "already v3"
    if version != 2:
        rep.err(f"expected version 2, found {version!r}")
        return rep, "error"

    validate(doc, rep)
    if rep.errors and not args.force:
        return rep, "not upgraded (fix errors or use --force)"
    if args.check:
        return rep, "v2, ok to upgrade"

    new_text, n = VERSION_RE.subn(r"\g<1>3", text, count=1)
    if n != 1:
        # "version" is not the first key: fall back to a full re-serialise.
        doc["version"] = 3
        new_text = json.dumps(doc, ensure_ascii=False, separators=(",", ":"))

    # Sanity check: only the version changed.
    new_doc = json.loads(new_text)
    doc["version"] = 3
    if new_doc != doc:
        rep.err("internal error: upgraded document differs beyond the version field")
        return rep, "error"

    if args.dry_run:
        return rep, "would upgrade 2 -> 3"

    if not args.no_backup:
        shutil.copy2(path, path.with_name(path.name + ".v2.bak"))
    path.write_text(new_text, encoding="utf-8")
    return rep, "upgraded 2 -> 3"


def find_presets(root):
    for p in sorted(root.glob("*/preset.json")):
        if p.parent.name not in EXCLUDED_DIRS:
            yield p


def main():
    ap = argparse.ArgumentParser(description="Upgrade Electra One presets from version 2 to 3.")
    ap.add_argument("files", nargs="*", type=Path,
                    help="preset.json files (default: all */preset.json next to this script)")
    ap.add_argument("--root", type=Path, default=SCRIPT_DIR,
                    help="folder to scan when no files are given (default: script folder)")
    ap.add_argument("-n", "--dry-run", action="store_true", help="don't write anything")
    ap.add_argument("--check", action="store_true", help="validate only; exit 1 if any errors")
    ap.add_argument("--no-backup", action="store_true", help="don't create preset.json.v2.bak")
    ap.add_argument("--force", action="store_true", help="upgrade even if validation errors were found")
    args = ap.parse_args()

    files = args.files or list(find_presets(args.root))
    if not files:
        print("no preset.json files found", file=sys.stderr)
        return 1

    total_errors = 0
    for f in files:
        rep, status = process(f, args)
        try:
            shown = f.resolve().relative_to(args.root.resolve())
        except ValueError:
            shown = f
        print(f"{str(shown):35s} {status}")
        for w in rep.warnings:
            print(f"    warning: {w}")
        for e in rep.errors:
            print(f"    ERROR:   {e}")
        total_errors += len(rep.errors)

    return 1 if total_errors else 0


if __name__ == "__main__":
    sys.exit(main())
