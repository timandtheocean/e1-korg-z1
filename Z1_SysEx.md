# Korg Z1 SysEx Reference (Verified)

Source: [Z1_MIDIimp/Z1_MIDIimp.TXT](Z1_MIDIimp/Z1_MIDIimp.TXT) (Korg Rev 1.0, 1997-09-12).

## Header

`F0 42 3g 46 ...`

- `42` = Korg ID
- `3g` = `0x30 | g`, where `g` = global MIDI channel (0–15)
- `46` = Z1 model ID (**not** `49`)

## Messages

| Message | Dir | Format | Notes |
|---|---|---|---|
| Parameter Change | ↔ | `F0 42 3g 46 41 0m pl pm vl vm F7` | `m` group: `0` Global/MIDI, `1` Program, `2` Arp Pattern, `3` Multi. `pl pm` = Param ID LSB, MSB. `vl vm` = 14-bit value, LSB (bits 0–6) first. |
| Parameter Request | — | **Not supported** | Request a dump instead. |
| Current Program Dump Request | → Z1 | `F0 42 3g 46 10 00 F7` | Z1 replies with `40`. |
| Current Program Dump | ↔ | `F0 42 3g 46 40 01 [data] F7` | Note the `01` byte before data. |
| Program Dump Request | → Z1 | `F0 42 3g 46 1C ub pp 00 F7` | `ub` = `00uu000b`: unit `00` Prog / `01` Bank / `10` All, `b` = Bank A/B. |
| Program Dump | ↔ | `F0 42 3g 46 4C ub pp 00 [data] F7` | |
| Current Multi Dump Request | → Z1 | `F0 42 3g 46 19 00 F7` | **`19`**, not `18`. |
| Current Multi Dump | ↔ | `F0 42 3g 46 49 00 [data] F7` | **`49`**, not `48`. |
| Multi Dump Request | → Z1 | `F0 42 3g 46 1D ub mm 00 F7` | |
| Multi Dump | ↔ | `F0 42 3g 46 4D 00 ub mm 00 [data] F7` | |
| Current Arp Pattern Dump Request | → Z1 | `F0 42 3g 46 36 00 F7` | |
| Current Arp Pattern Dump | ↔ | `F0 42 3g 46 6B 00 [data] F7` | |
| Arp Pattern Dump Request | → Z1 | `F0 42 3g 46 34 u0 pp F7` | `u` `0` Pattern / `1` All; `pp` 0–19. |
| Arp Pattern Dump | ↔ | `F0 42 3g 46 69 u0 pp [data] F7` | |
| Global/MIDI Dump Request | → Z1 | `F0 42 3g 46 0E 0g F7` | `0g`: `00` Global, `01` MIDI. |
| Global/MIDI Dump | ↔ | `F0 42 3g 46 51 0g [data] F7` | |
| All Data Dump Request | → Z1 | `F0 42 3g 46 0F 00 F7` | |
| All Data Dump | ↔ | `F0 42 3g 46 50 00 00 [data] F7` | Order: Program, Multi, Pattern, Global/MIDI. |
| Program Write | → Z1 | `F0 42 3g 46 11 0b pp F7` | `b` Bank A/B, `pp` 0–127. Writes edit buffer. |
| Multi Write | → Z1 | `F0 42 3g 46 1A 00 mm F7` | `mm` 0–31. |
| Arp Pattern Write | → Z1 | `F0 42 3g 46 37 00 pp F7` | `pp` 0–19. |
| Mode Change (`4E`) | — | **Not supported** | Not in Z1 spec. |
| Device Inquiry Request | → Z1 | `F0 7E 0g 06 01 F7` | Spec lists `0g` (channel); `7F` all-call not documented. |
| Device Inquiry Reply | Z1 → | `F0 7E 0g 06 02 42 46 00 01 00 mn mn mj mj F7` | Family `46 00`, Member `01 00`, then minor/major version (LSB, MSB). |

## Z1 Replies (Status)

| Code | Format | Sent after |
|---|---|---|
| `21` Write Completed | `F0 42 3g 46 21 F7` | Write requests |
| `22` Write Error | `F0 42 3g 46 22 00 F7` | Write requests |
| `23` Data Load Completed | `F0 42 3g 46 23 F7` | Dumps received (not sent for `41` Parameter Change) |
| `24` Data Load Error | `F0 42 3g 46 24 00 F7` | Dumps received |
| `26` Data Format Error | `F0 42 3g 46 26 F7` | Malformed message |

## Dump Data Encoding (7→8 bit)

Each 7 bytes of internal data → 8 MIDI bytes. The first MIDI byte holds the MSBs (bit 7) of the next 7 bytes: bit 0 = byte 0's MSB, … bit 6 = byte 6's MSB. Then the 7 bytes follow with bit 7 cleared.

## Corrections vs. Original Draft

1. Model ID is `46`, not `49`.
2. Parameter Change has a group byte (`0m`) and is LSB-first.
3. Requests/dumps carry extra fixed or selector bytes (`00`, `01`, `0g`).
4. Current Multi request/dump are `19`/`49`, not `18`/`48`.
5. Mode Change `4E` is not supported.
6. Device Inquiry reply: `42 46 00 01 00`, not `42 49 00 00`.

## Practical Notes

- Receive requires **SysEx Receive = ENABLE**. Auto transmit of `40`/`49`/`41` requires **SysEx Transmit = ON**.
- Parameter IDs: [PROG_PRM.TXT](Z1_MIDIimp/PROG_PRM.TXT), [MULT_PRM.TXT](Z1_MIDIimp/MULT_PRM.TXT), [PAT_PRM.TXT](Z1_MIDIimp/PAT_PRM.TXT), [GLBL_PRM.TXT](Z1_MIDIimp/GLBL_PRM.TXT).

## Verified on Hardware

Tested against Korg Z1 firmware v1.02 (Global MIDI channel 1, `g = 0`):

- **T1 Device Inquiry:** Both `F0 7E 7F 06 01 F7` (all-call) and `F0 7E 00 06 01 F7` return 15 bytes: `F0 7E 00 06 02 42 46 00 01 00 02 00 01 00 F7`.
- **T2 Current Program Dump (`10 00` → `40 01`):** Returns **666 bytes** (`F0 42 30 46 40 01` + 659 packed MIDI bytes + `F7`), which unpacks to **576 bytes** of 8-bit program data.
- **T3 OSC1 Type (`174`, ExID 0 → `pl=2E pm=01`):** `F0 42 30 46 41 01 2E 01 01 00 F7` switches OSC1 to Comb Filter (byte offset 154 in unpacked dump) and reinitializes the 38-byte OSC1 setting block (offsets 168–205) to the new model's defaults. Allow ~50–100 ms after changing OSC Type before requesting a dump.
- **T4 & T5 OSC1 Model Params (ExID 1, `id14 = 2048 + ID`):** Verified with Standard Wave (`464` → `50 13`) and Wave Form Mod Source (`473` → `59 13`, unpacked offset 177).
- **T6 Negative Values:** Confirmed **14-bit two's complement** (`v & 0x3FFF`, `vl = v & 0x7F`, `vm = (v >> 7) & 0x7F`). Sending `-50` (`0x3FCE` → `4E 7F`) to parameter `474` writes `206` (`-50` in signed 8-bit) at unpacked offset 178.
- **Status Reply on `41`:** Contrary to the text note under `(20) PARAMETER CHANGE` in `Z1_MIDIimp.TXT`, the Z1 does **not** transmit `23`/`24` after `41` Parameter Change messages—only after data dumps (`40`, `4C`, etc.).
