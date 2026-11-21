# Electra One: UI/Lua lock-up of ~5-9 s caused by `snapshots.save()`

Report for the Electra One developer. Written 2026-11-21.

## Environment

| Item | Value |
|------|-------|
| Hardware | Electra One mk2, hwRevision 3.0 |
| Firmware | v5.1.0 (versionSeq 500100000) |
| Preset | Korg Z1 editor (12 pages, 580 controls, ~250 KB `main.lua`), bank 4 slot 0 |
| Snapshot area used | bank 12 (internal `bankNumber=11`), slots 1..16 and 36 |
| Preset snapshots | none created by the user manually; all come from the Lua calls below |

## Symptom

The whole device freezes (touch screen, knobs, Lua timers) for roughly 5-9 seconds.
It happens every time the preset saves a snapshot. The freeze starts about 15 s after the
user last turned a knob. That is when the preset's undo/redo logic commits its snapshot.

Firmware log seen by the user while it happened:

```
16:44:19.929 saveSnapshot: projectId=FD3sdxsK2sOm0VUSagRF, bankNumber=11, slot=15
16:44:21.735 updateSnapshot: projectId=FD3sdxsK2sOm0VUSagRF, bankNumber=11, slot=15, name=U16:P524:0->0, colour=529dec
16:44:21.753 SysexApi::process: sysex received: command=2, object=5
16:44:21.759 SysexApi::sendSnapshotList: port=2
16:44:25.854 SysexApi::process: sysex received: command=2, object=5
16:44:25.865 SysexApi::sendSnapshotList: port=2
```

Note: `saveSnapshot` -> `updateSnapshot` is 1.8 s, and the device is locked until about 5 s
after `saveSnapshot`.

## What our Lua code does (exactly)

All snapshot use is in `e1/z1-base/main.lua`. No other module calls the snapshot API.
Only these Lua calls are made:

```lua
snapshots.save(12, slot, name, colour)   -- bank 12; slot 1..16 = undo steps, slot 36 = backup
snapshots.isUsed(12, slot)               -- read only, only before a load
snapshots.load(12, slot)                 -- only on Undo/Redo/Recover when the state is not in RAM
```

Where `snapshots.save` is called:

| Where | When | Slot / name / colour |
|-------|------|----------------------|
| `flushPendingUndoSnapshot()` (line ~441) | The 1 s `timer.onTick` counts 15 idle seconds after the last Z1 parameter change (a knob turn) | slot = undo cursor (1..16), name `"U%02d:<label>"` (e.g. `U16:P524:0->0`), colour `0x529DEC` |
| `pushUndoState()` (line ~425) | On Recover and a few explicit actions (most calls pass `skipSnapshotWrite=true`) | same as above |
| `savePatchBackup()` (line ~366) | "Manual Backup" button, `requestCurrentProgramDump()` when no backup exists, 30 s after a preset change ("Auto 30s Backup") | slot 36, name = reason, colour `0xD9534F` |

The undo stack holds at most 16 entries. Once it is full the cursor stays at 16, so every
later commit overwrites slot 16 (`bankNumber=11, slot=15` in the log above).

The normal flow per knob-turn burst is therefore:

1. User turns a knob. Each tick records an undo entry in RAM only (no snapshot call).
2. 15 seconds without a further change.
3. One `snapshots.save(12, N, "U..:..", 0x529DEC)` call. This is the call that freezes the device.

We call `snapshots.save` from `timer.onTick` and from button callbacks, always on the Lua
thread. We never call it in a loop. At most one call is made per 15 s burst.

## Minimal reproduction (no preset code involved)

I ran this through `electraone lua exec` on the live device.

1. Start a heartbeat that reports gaps (it runs on the Lua scheduler):

   ```lua
   HBL = controller.micros()
   schedule.every(50, function()
       local n = controller.micros(); local g = (n - HBL) / 1000; HBL = n
       if g > 300 then print("STALL " .. math.floor(g) .. " ms at up=" .. controller.uptime()) end
   end)
   ```

2. Save one snapshot:

   ```lua
   snapshots.save(12, 16, "REPRO", 0x529DEC)
   ```

Measured results (3 runs, device otherwise idle):

| Run | `snapshots.save` returned after | Longest scheduler stall | Firmware log |
|-----|---------------------------------|-------------------------|--------------|
| 1 (60 s idle first) | 0.045 ms | **8835 ms** | `Snapshot List Change` at +4.7 s and +8.8 s after the call |
| 2 (immediately after run 1, card warm) | 0.045 ms | not measured (heartbeat reporting was broken in this run) | `Snapshot List Change` at +4.7 s and +8.9 s |
| 3 (later, card warm) | not timed | **8836 ms** | `Snapshot List Change` at +4.7 s and +8.8 s |

The repro runs inside the normal preset but touches nothing except this single `snapshots.save` call.

Observations:

* `snapshots.save()` returns almost immediately (0.045 ms), then the firmware stalls the
  whole device for about 8.8 s. The Lua scheduler (and the UI) are blocked during that time.
* Two `Snapshot List Change` events follow the call, about 4.1 s apart. The second one coincides
  with the end of the stall.
* The stall is about the same whether the SD card has been idle or not, so it is not only the
  card wake-up delay (which we see separately as 1.9 s on `persist()` after about 40 s idle).
* `snapshots.isUsed(12, 16)` reported `true` when queried after the stall.
* Without a `snapshots.save` call, the same kind of heartbeat showed gaps of at most about 110 ms
  while saving presets with `persist()` (measured earlier in the session).
* In the user's log the editor/host also requested the snapshot list (`sendSnapshotList: port=2`),
  and the lock-up was shorter (~5 s). Whether the stall depends on the host being connected is
  not known.

## Related measurements (same device, same session)

| Operation | Lua call cost | Actual stall |
|-----------|---------------|--------------|
| `persist()` (426 bytes) | blocks about 65 ms | about 1.9 s for the first write after about 40 s idle |
| `snapshots.save()` | 0.045 ms | **about 8.8 s** |
| `window.resume()` (bulk layout change) | about 110 ms | about 172 ms worst case |

## Questions for the developer

1. Is it expected that `snapshots.save()` blocks the Lua/UI thread for 5-9 s, with two list
   change events about 4 s apart? Is the work done synchronously on the main thread?
2. Is there an asynchronous way to save a snapshot (or a way to suppress the list-change
   notifications and the `updateSnapshot` rename step that follows)?
3. Is there a supported way to hold undo state in a snapshot-like store without going through the
   SD card for every save, or is keeping undo purely in RAM the recommended approach?

## Current status in our preset

The snapshot writes are temporarily disabled by the flag `SNAPSHOTS_ENABLED = false` in
`e1/z1-base/main.lua` while the user confirms that the lock-ups are gone. Undo/redo then works
from RAM only (this holds up to 16 steps and is lost on reload).
