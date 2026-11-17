# upgrade_presets_v3.py

Upgrades the Electra One `preset.json` files in this folder from preset format
**version 2** to **version 3**.

## Background

Preset format v3 is a superset of v2. The top-level structure (`pages`, `groups`,
`devices`, `overlays`, `controls`) and all keys used by v2 presets are unchanged.
v3 only adds optional features, for example:

| Object  | New in v3 (optional)                                              |
|---------|-------------------------------------------------------------------|
| control | `variant` (`thin`, `dial`, `valueOnly`, …), `events` (touch / switch actions) |
| group   | `variant` (`highlighted`, …), `font`                              |

So upgrading a v2 preset means:

1. checking that the preset is structurally valid, and
2. changing the top-level `"version": 2` to `"version": 3`.

The reference v3 file used for comparison is `../HARP2.4_mk2.epr`.

## What the script does

- Scans every `*/preset.json` next to the script.
- Skips folders that are not presets: `z1-signalflow`, `z1-filterwidget`,
  `z1-mixerwidget`. It also skips any file that has `schemaVersion` (editor
  project or widget format).
- Validates each preset:
  - required top-level keys: `version`, `name`, `projectId`, `pages`, `devices`, `controls`
  - unique ids for pages, groups, devices, overlays, controls and the values within a control
  - every `pageId`, `overlayId`, `deviceId` and input `valueId` refers to something that exists
  - `potId` is 1–12, `controlSetId` is 1–3, `bounds` is 4 integers
  - warnings for unknown control types, unusual pad modes, `min > max` and duplicate overlay values
- Changes **only** the version number. The rest of the file stays byte-for-byte
  identical: no re-formatting, no key re-ordering, and escapes like `\u0026` are kept,
  so git diffs stay minimal.
- Checks after the change that the parsed document differs only in `version`.
- Writes a backup `preset.json.v2.bak` before overwriting (unless `--no-backup`).
- Leaves files that fail validation unchanged (unless `--force`).
- Can be run again safely: files that are already v3 are reported as `already v3`.

## Usage

```bash
cd ~/src/Z1/e1

./upgrade_presets_v3.py --dry-run           # preview, writes nothing
./upgrade_presets_v3.py                     # upgrade all presets (with .v2.bak backups)
./upgrade_presets_v3.py --check             # validate only, exit code 1 on errors
./upgrade_presets_v3.py z1-eg/preset.json   # upgrade specific files only
./upgrade_presets_v3.py --no-backup         # don't create .v2.bak files
./upgrade_presets_v3.py --root /other/dir   # scan another folder
```

### Options

| Option            | Description                                                    |
|-------------------|----------------------------------------------------------------|
| `files…`          | Specific preset files. Default: all `*/preset.json` under `--root` |
| `--root DIR`      | Folder to scan when no files are given (default: script folder) |
| `-n`, `--dry-run` | Report what would happen, write nothing                         |
| `--check`         | Validate only; exit code 1 if any errors are found              |
| `--no-backup`     | Don't write `preset.json.v2.bak`                                |
| `--force`         | Upgrade even if validation errors were found                    |

### Example output

```
z1-base/preset.json                 upgraded 2 -> 3
z1-common-arp/preset.json           upgraded 2 -> 3
z1-eg/preset.json                   already v3
z1-fx/preset.json                   not upgraded (fix errors or use --force)
    ERROR:   control 12 ('CUTOFF'): pageId 4 does not exist
```

## Exit codes

| Code | Meaning                                   |
|------|-------------------------------------------|
| 0    | Success, no validation errors              |
| 1    | Validation errors found, or no files found |

## Reverting

Restore a file from its backup:

```bash
mv z1-eg/preset.json.v2.bak z1-eg/preset.json
```

Remove all backups once you're happy with the result:

```bash
rm */preset.json.v2.bak
```

## Requirements

Python 3.6+, standard library only.
