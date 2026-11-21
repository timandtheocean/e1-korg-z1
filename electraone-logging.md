# Viewing Verbose Device Logs with `electraone` CLI

Reference for streaming Electra One device logs, Lua `print()` output, and controller events using the `electraone` CLI (`/usr/bin/electraone`, v1.0).

By default, `electraone` connects to the USB MIDI **`CTRL`** port (`--port CTRL`). Use `electraone list-ports` to verify available MIDI ports and indices.

---

## 1. Quick Start: Standard Live Logs (`logger listen`)

To enable the device logger and stream timestamped logs and controller events in real time:

```bash
electraone logger listen
```

What `electraone logger listen` does automatically:
1. Sends `F0 00 21 45 7F 7D 01 00 F7` to enable device logging (`status = 0x01`, `log-level = 0x00`).
2. Routes logger output to `--logger-port` (`ctrl` by default; accepts `port1`, `port2`, or `ctrl`).
3. Subscribes to controller events (`--all` is enabled by default).
4. Prints timestamped `Log: ...` lines and decoded controller events until `Ctrl+C` (or `--duration <seconds>`).

### Useful Options

Remember that global options (`--raw`, `--port`, `--port-index`, `--timeout`, `-o`) go **before** the subcommand:

```bash
# Logs only (suppress controller UI events such as pot/touch/button traffic)
electraone logger listen --all=false

# Logs + only page and touch events, auto-stop after 30 seconds
electraone logger listen --all=false --page --touch --duration 30

# Print raw hex SysEx frames instead of decoded text
electraone --raw logger listen --all=false

# Target a specific MIDI port index (see `electraone list-ports`)
electraone --port-index 3 logger listen
```

---

## 2. Maximum Verbosity (`log-level = 0x03`, Tracing)

In the Electra One SysEx specification, the **Control Logger Output** command takes both a `status` byte and a `log-level` byte:

```text
F0 00 21 45 7F 7D <status> <log-level> F7
```

- `<status>`: `0x00` = disable, `0x01` = enable (stored in non-volatile memory on the device).
- `<log-level>`:
  - `0x00` — Critical messages (cannot be disabled)
  - `0x01` — Warning messages
  - `0x02` — Informative messages
  - `0x03` — Tracing messages (most verbose)

### Limitation in `electraone` v1.0

`electraone logger enable` and `electraone logger listen` do not expose a log-level flag and hardcode `{0x01, 0x00}` (`log-level = 0x00`). Running `electraone logger listen` will therefore reset the device's log level back to `0x00`.

### Workaround (`raw` + `events listen`)

`electraone events listen` uses the exact same timestamped `Log: ...` decoder as `logger listen`, **without** sending `0x7F 0x7D 0x01 0x00`. To enable `0x03` (Tracing) verbosity and stream the logs:

```bash
# 1. Route device logs to the CTRL port
electraone logger set-port --port ctrl

# 2. Enable the logger at Tracing verbosity (status=0x01, log-level=0x03)
#    (If the command does not emit an ACK on your firmware, add `--timeout 200` before `raw`)
electraone raw --bytes "F0 00 21 45 7F 7D 01 03 F7"

# 3. Stream incoming logs without resetting the log level
#    Use `--all=false` for logs only, or omit it to include all controller events
electraone events listen --all=false
```

To use a different verbosity level, replace `03` in the raw SysEx message with `01` (Warning) or `02` (Informative).

---

## 3. Manual Control & Disabling the Logger

```bash
# Enable / disable the non-volatile logger flag (defaults to log-level 0x00)
electraone logger enable
electraone logger disable

# Change which Electra One MIDI port transmits logs
electraone logger set-port --port ctrl   # port1, port2, or ctrl
```

### Notes

- **Lua `print()` and startup messages:** The Electra One firmware transmits startup messages and output from Lua `print()` regardless of whether the logger is enabled or disabled. Even `electraone events listen --all=false` by itself will display `Log: ...` messages from Lua `print()`.
- **`electraone debug` vs. `electraone logger`:** `electraone debug enable` / `disable` sends the legacy `0x7C` command, which is retired in newer Electra One firmware. Use `logger` (or `0x7F 0x7D` via `raw`) for device logs, and `electraone debug set-breakpoints` if you need Lua line breakpoints.
