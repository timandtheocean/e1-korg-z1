# Page 01 — Base: Handshake, Patch Name, Backup/Recovery & Snapshot Undo/Redo

[⬅ Back to User Manual Index](../README.md)

- **Source Folder:** [`e1/z1-base/`](../../e1/z1-base/)
- **Files:** [`preset.json`](../../e1/z1-base/preset.json) | [`main.lua`](../../e1/z1-base/main.lua) | [`main-tests.lua`](../../e1/z1-base/main-tests.lua)
- **Z1 Parameters Covered:** `IDs 1..16` (`ExID = 0`, Program Name 16 ASCII characters `20H..7FH`) + Universal Device Inquiry (`7EH`) + Current Program Dump Request (`10H`) & Data Dump (`40H` / `4CH`).

> 📸 **[Screenshot Placeholder: `../media/01-base-utility.png`]**
> *Add screenshot of the Base page showing Z1 Online status, Backup name, and Program Name LCD widget.*
>
> 🎬 **[Video Placeholder: `../media/01-base-utility.mp4`]**
> *Add short clip demonstrating Handshake, `40H` Patch Request, `Recover Backup`, and `Undo`/`Redo`.*

---

## 1. Overview

The **Base** page manages bidirectional SysEx handshaking with the Korg Z1, requests and parses the 666-byte Current Program Edit Buffer dump (`40H`), provides a 16-character Program Name editor/display, and safeguards edits on the Electra One using an automatic **Patch Backup & Recovery** system and a **16-slot Snapshot-backed Undo/Redo buffer** in Electra One **Snapshot Bank 12**.

---

## 2. Control Layout

### Control Set 1 — Z1 Handshake, Patch Request & Backup Recovery (Row 1)

| Slot | Control ID | Label | Type | Range / Values | Description |
|:---:|:---:|---|---|---|---|
| **1** | `1` | `Handshake ID` | Momentary Pad | `0..1` | Transmits Universal Device Inquiry (`F0 7E 0g 06 01 F7`) and parses the Z1's 15-byte identity reply (`42 46 00 01 00`). |
| **2** | `2` | `Patch Req 40H` | Momentary Pad | `0..1` | Automatically backs up the current E1 patch (`savePatchBackup`), then sends `F0 42 3g 46 10 00 F7` to request the Z1 edit buffer. |
| **3–4** | `3` | `Z1 Status` | Custom Display | 2-Slot LCD | **Line 1:** `Z1 Ch<ch> v<maj.min> \| <Last Dump>` (or `Z1 OFFLINE`).<br>**Line 2:** `Bk: <Backed-Up Patch Name>` |
| **5** | `4` | `Recover Backup` | Momentary Pad | `0..1` | Restores `patchBackup` + E1 Snapshot `(12, 36)` and re-transmits the full 666-byte `40H` dump (or 16 `41H` name parameters) back to the Z1. |
| **6** | `7` | `Backup Now` | Momentary Pad | `0..1` | Manually saves the current E1 patch into `patchBackup` and E1 Snapshot `(12, 36)`. |

### Control Set 2 — Program Name Editor & Snapshot Undo/Redo (Row 2)

| Slot | Control ID | Label | Type | Range / Values | Description |
|:---:|:---:|---|---|---|---|
| **1** | `33` | `Name Pos` | Fader | `1..16` | Selects character position `1..16` (`ID 1..16`) in the Program Name. |
| **2** | `34` | `Name Char` | Fader | `32..127` (`20H..7FH`) | Sets the ASCII character at `Name Pos` and sends `41H` Parameter Change directly to the Z1 (does not push to the Undo stack). |
| **3–4** | `35` | `Program Name` | Custom Display | 2-Slot LCD | **Line 1:** `NAME [P<pos>:'<char>' \| U:<cur>/<max>]`<br>**Line 2:** Full 16-character Z1 Program Name. |
| **5** | `5` | `Undo` | Momentary Pad | `0..1` | Reverts the most recent synth parameter change (`41H`) or patch state in `undoStack` and transmits the restored value to the Z1. |
| **6** | `6` | `Redo` | Momentary Pad | `0..1` | Re-applies the next synth parameter change (`41H`) or patch state in `undoStack` and transmits it to the Z1. |

---

## 3. Snapshot Bank 12 Allocation & 15-Second Idle Timer

| Bank | Slot(s) | Label Format | Purpose |
|:---:|:---:|---|---|
| **12** | `1..16` | `U01:<Param>` .. `U16:<Param>` | 16-step Undo / Redo history buffer (`COLOUR_UNDO = 0x529DEC`), written only after **15 seconds of no user activity** (`UNDO_IDLE_TIMEOUT_SEC = 15`). |
| **12** | `36` | `Pre-Req Backup` / `Manual Backup` | Dedicated Patch Backup slot (`COLOUR_BACKUP = 0xD9534F`). |
