-- Korg Z1 - Base & Utility Module for Electra One mk2
-- 1. Handshake routine (Universal Device Inquiry F0 7E 0g 06 01 F7 -> Z1 ID 42 46 00 01 00)
-- 2. Patch Request for Current Program Edit Buffer (F0 42 3g 46 10 00 F7 -> 40H Dump)
-- 3. Patch parsing for Program Name (IDs 1..16, 20H..7FH) with custom Program Name widget (Control 35)
-- 4. Automatic E1 Patch Backup & Recover from Backup (Control 4 / Control 7 + E1 Snapshot Bank 12 Slot 36)
-- 5. Snapshot-backed Undo / Redo Buffer (Controls 5 & 6 + E1 Snapshot Bank 12 Slots 1..16)

local DEVICE_ID = 1

-- Dedicated Electra One Snapshot Bank & Slots for Undo/Redo and Pre-Request Backup
SNAPSHOT_BANK         = 12
BACKUP_SNAP_SLOT      = 36
MAX_UNDO_SLOTS        = 16
UNDO_IDLE_PERIOD_MS   = 1000 -- 1-second timer tick
UNDO_IDLE_TIMEOUT_SEC = 15   -- Save Undo snapshot only after 15 seconds of no user activity
local COLOUR_BACKUP   = 0xD9534F
local COLOUR_UNDO     = 0x529DEC

local function getGlobalChannel()
    if z1Status and z1Status.connected and type(z1Status.channel) == "number" then
        return (z1Status.channel - 1) & 0x0F
    end
    local dev = preset.getDevice(DEVICE_ID)
    if dev and dev.getChannel then
        return (dev:getChannel() - 1) & 0x0F
    end
    return 0
end

local function sendSysexBody(body)
    local dev = preset.getDevice(DEVICE_ID)
    if dev then
        dev:sendSysex(body)
    else
        midi.sendSysex(PORT_1, body)
    end
end

local function copyByteArray(src)
    if type(src) ~= "table" then
        return nil
    end
    local dst = {}
    for i = 1, #src do
        dst[i] = src[i]
    end
    return dst
end

-- ============================================================================
-- 1. Z1 Handshake State & Device Inquiry (F0 7E 0g 06 01 F7)
-- ============================================================================

z1Status = {
    connected = false,
    channel   = 1,
    familyId  = 0,
    memberId  = 0,
    version   = "---",
    lastDump  = "None",
}

function buildDeviceInquiryBody(gCh)
    local g = gCh or getGlobalChannel()
    return { 0x7E, g & 0x0F, 0x06, 0x01 }
end

function sendDeviceInquiry()
    sendSysexBody(buildDeviceInquiryBody())
    info.setText("Sent Z1 Device Inquiry")
end

-- ============================================================================
-- 2. Program Name State, Korg 7-to-8-bit Pack/Unpack & Patch Buffer
-- ============================================================================

programNameChars = {
    0x49, 0x6E, 0x69, 0x74, 0x20, 0x50, 0x72, 0x6F,
    0x67, 0x72, 0x61, 0x6D, 0x20, 0x20, 0x20, 0x20,
} -- Default: "Init Program    "
selectedCharPos = 1
local suppressCharCallback = false

-- Current unpacked Z1 Program data buffer on the E1 (576 bytes when populated from a full 40H dump)
currentUnpackedProgram = nil

function getProgramNameString(charsTable)
    local src = charsTable or programNameChars
    local chars = {}
    for i = 1, 16 do
        local c = src[i] or 0x20
        if c < 0x20 or c > 0x7F then
            c = 0x20
        end
        chars[i] = string.char(c)
    end
    return table.concat(chars)
end

-- Unpack Korg 7-to-8-bit packed MIDI bytes:
-- Every 8 MIDI bytes = [msbByte, d0, d1, d2, d3, d4, d5, d6] -> 7 unpacked 8-bit bytes.
function unpackKorgData(packedBytes, maxUnpacked)
    local out = {}
    local n = #packedBytes
    local idx = 1
    while idx <= n do
        local msb = packedBytes[idx] or 0
        for bit = 0, 6 do
            local dataIdx = idx + 1 + bit
            if dataIdx > n then
                break
            end
            local b = (packedBytes[dataIdx] & 0x7F) | (((msb >> bit) & 0x01) << 7)
            out[#out + 1] = b
            if maxUnpacked and #out >= maxUnpacked then
                return out
            end
        end
        idx = idx + 8
    end
    return out
end

-- Pack 8-bit unpacked Z1 data bytes into Korg 7-to-8-bit MIDI format:
-- Every 7 unpacked bytes -> 8 MIDI bytes [msbByte, d0..d6] (576 unpacked -> 659 packed).
function packKorgData(unpackedBytes)
    local out = {}
    local n = #unpackedBytes
    local idx = 1
    while idx <= n do
        local msb = 0
        local groupLen = math.min(7, n - idx + 1)
        for bit = 0, groupLen - 1 do
            local b = unpackedBytes[idx + bit] & 0xFF
            if (b & 0x80) ~= 0 then
                msb = msb | (1 << bit)
            end
        end
        out[#out + 1] = msb
        for bit = 0, groupLen - 1 do
            out[#out + 1] = unpackedBytes[idx + bit] & 0x7F
        end
        idx = idx + 7
    end
    return out
end

function buildParamChangeBody(paramId, signedVal, gCh)
    local g = gCh or getGlobalChannel()
    local id14 = paramId & 0x3FFF
    local v14 = signedVal & 0x3FFF
    return {
        0x42,
        0x30 | (g & 0x0F),
        0x46,
        0x41,
        0x01,
        id14 & 0x7F,
        (id14 >> 7) & 0x7F,
        v14 & 0x7F,
        (v14 >> 7) & 0x7F,
    }
end

function buildCurrentProgramDumpBody(unpackedBytes, gCh)
    local g = gCh or getGlobalChannel()
    local packed = packKorgData(unpackedBytes)
    local body = { 0x42, 0x30 | (g & 0x0F), 0x46, 0x40, 0x01 }
    for i = 1, #packed do
        body[#body + 1] = packed[i]
    end
    return body
end

-- ============================================================================
-- 3. Patch Backup & Snapshot-Backed Undo / Redo Buffer
-- ============================================================================

patchBackup         = nil
undoStack           = {}
undoCursor          = 0
paramValues         = {}
undoIdleSeconds     = 0
undoPendingSnapshot = false
timer               = timer or {}

local function hasSnapshotsApi()
    return type(_G.snapshots) == "table"
        and type(_G.snapshots.save) == "function"
        and type(_G.snapshots.load) == "function"
end

local function hasTimerApi()
    return type(_G.timer) == "table"
        and type(_G.timer.enable) == "function"
        and type(_G.timer.disable) == "function"
end

local function restartUndoIdleTimer()
    undoIdleSeconds = 0
    undoPendingSnapshot = true
    if hasTimerApi() then
        if type(_G.timer.setPeriod) == "function" then
            _G.timer.setPeriod(UNDO_IDLE_PERIOD_MS)
        end
        _G.timer.enable()
    end
end

local function stopUndoIdleTimer()
    undoIdleSeconds = 0
    undoPendingSnapshot = false
    if hasTimerApi() then
        _G.timer.disable()
    end
end

local function captureCurrentPatchState(label)
    local nameCopy = copyByteArray(programNameChars)
    local unpackedCopy = copyByteArray(currentUnpackedProgram)
    if unpackedCopy then
        for i = 1, 16 do
            unpackedCopy[i] = nameCopy[i]
        end
    end
    return {
        kind          = "patch",
        label         = label or getProgramNameString(nameCopy),
        nameChars     = nameCopy,
        unpackedBytes = unpackedCopy,
    }
end

local function refreshStatusAndNameWidgets()
    local charCtrl = controls.get(34)
    if charCtrl then
        suppressCharCallback = true
        charCtrl:getValue("value"):updateValue(programNameChars[selectedCharPos] or 0x20)
        suppressCharCallback = false
    end
    local statusCtrl = preset.getControl(3)
    if statusCtrl then
        statusCtrl:repaint()
    end
    local dispCtrl = preset.getControl(35)
    if dispCtrl then
        dispCtrl:repaint()
    end
end

-- Apply a captured patch state to the E1 and optionally transmit it to the Korg Z1
local function applyPatchState(state, transmitToZ1, snapshotSlot)
    if type(state) ~= "table" or type(state.nameChars) ~= "table" then
        return false
    end

    if snapshotSlot and hasSnapshotsApi() then
        if _G.snapshots.isUsed and _G.snapshots.isUsed(SNAPSHOT_BANK, snapshotSlot) then
            _G.snapshots.load(SNAPSHOT_BANK, snapshotSlot)
        end
    end

    for i = 1, 16 do
        programNameChars[i] = state.nameChars[i] or 0x20
    end

    if state.unpackedBytes then
        currentUnpackedProgram = copyByteArray(state.unpackedBytes)
        for i = 1, 16 do
            currentUnpackedProgram[i] = programNameChars[i]
        end
    end

    if transmitToZ1 then
        if currentUnpackedProgram and #currentUnpackedProgram >= 576 then
            sendSysexBody(buildCurrentProgramDumpBody(currentUnpackedProgram))
        else
            for i = 1, 16 do
                sendSysexBody(buildParamChangeBody(i, programNameChars[i]))
            end
        end
    end

    refreshStatusAndNameWidgets()
    return true
end

-- Save current E1 patch state into the Backup slot (and E1 Snapshot Bank 12 Slot 36)
function savePatchBackup(reason, skipSnapshotWrite)
    local label = reason or ("Bk:" .. string.sub(getProgramNameString(), 1, 12))
    patchBackup = captureCurrentPatchState(label)
    if not skipSnapshotWrite and hasSnapshotsApi() then
        _G.snapshots.save(SNAPSHOT_BANK, BACKUP_SNAP_SLOT, label, COLOUR_BACKUP)
    end
    refreshStatusAndNameWidgets()
    return patchBackup
end

-- Recover the backed-up patch on the E1 and transmit it back to the Z1 edit buffer
function recoverPatchBackup()
    if not patchBackup then
        info.setText("No Patch Backup Available")
        return false
    end
    applyPatchState(patchBackup, true, BACKUP_SNAP_SLOT)
    z1Status.lastDump = "Recovered Bk"
    info.setText("Recovered: " .. getProgramNameString())
    refreshStatusAndNameWidgets()
    return true
end

-- Push a baseline patch state onto the Undo/Redo stack (e.g., on initial load or 40H dump).
function pushUndoState(label, skipSnapshotWrite)
    while #undoStack > undoCursor do
        table.remove(undoStack)
    end
    if #undoStack >= MAX_UNDO_SLOTS then
        table.remove(undoStack, 1)
    end

    local state = captureCurrentPatchState(label)
    undoStack[#undoStack + 1] = state
    undoCursor = #undoStack
    local slot = undoCursor
    state.snapshotSlot = slot

    if not skipSnapshotWrite and hasSnapshotsApi() then
        local snapName = string.format("U%02d:%s", slot, string.sub(getProgramNameString(), 1, 11))
        _G.snapshots.save(SNAPSHOT_BANK, slot, snapName, COLOUR_UNDO)
        state.savedToSnapshot = true
    end

    return undoCursor
end

-- Commit the pending Undo entry to E1 Snapshot Bank 12 after 15 seconds of no user activity
function flushPendingUndoSnapshot()
    local top = undoStack[undoCursor]
    if top then
        top.sealed = true
        local slot = top.snapshotSlot or undoCursor
        top.snapshotSlot = slot
        if not top.savedToSnapshot and hasSnapshotsApi() then
            local snapName = string.format("U%02d:%s", slot, string.sub(top.label or getProgramNameString(), 1, 11))
            _G.snapshots.save(SNAPSHOT_BANK, slot, snapName, COLOUR_UNDO)
            top.savedToSnapshot = true
        end
    end
    stopUndoIdleTimer()
    local dispCtrl = preset.getControl(35)
    if dispCtrl then
        dispCtrl:repaint()
    end
end

function timer.onTick()
    if not undoPendingSnapshot then
        stopUndoIdleTimer()
        return
    end
    undoIdleSeconds = undoIdleSeconds + 1
    if undoIdleSeconds >= UNDO_IDLE_TIMEOUT_SEC then
        flushPendingUndoSnapshot()
    end
end

-- Record a user synth parameter change (ignores patch name IDs 1..16).
-- Consecutive ticks on the same (exId, paramId) coalesce into a single Undo step in RAM,
-- and the E1 snapshot is written only after 15 seconds of no user activity.
function recordParamChange(exId, paramId, signedVal, ctrlId)
    local ex = (exId or 0) & 0x07
    local pid = paramId & 0x07FF
    -- Patch Name characters (ExID 0, IDs 1..16) are NOT tracked in Undo/Redo
    if ex == 0 and pid >= 1 and pid <= 16 then
        return undoCursor
    end

    local id14 = (ex << 11) | pid
    local oldVal = paramValues[id14]
    if oldVal == nil then
        if ex == 0 and currentUnpackedProgram and currentUnpackedProgram[pid] ~= nil then
            oldVal = currentUnpackedProgram[pid]
        else
            oldVal = 0
        end
    end

    paramValues[id14] = signedVal
    if ex == 0 and currentUnpackedProgram and pid >= 17 and pid <= 576 then
        currentUnpackedProgram[pid] = signedVal & 0xFF
    end

    -- Discard any redo states ahead of undoCursor
    while #undoStack > undoCursor do
        table.remove(undoStack)
    end

    -- Coalesce consecutive unsealed turns of the same parameter into the top Undo step
    local top = undoStack[undoCursor]
    if top and top.kind == "param" and top.id14 == id14 and not top.sealed then
        top.newVal = signedVal
        top.label  = string.format("P%d:%d->%d", pid, top.oldVal, signedVal)
        top.savedToSnapshot = false
        restartUndoIdleTimer()
        return undoCursor
    end

    if #undoStack >= MAX_UNDO_SLOTS then
        table.remove(undoStack, 1)
    end

    local entry = {
        kind            = "param",
        id14            = id14,
        exId            = ex,
        paramId         = pid,
        oldVal          = oldVal,
        newVal          = signedVal,
        ctrlId          = ctrlId,
        sealed          = false,
        savedToSnapshot = false,
        label           = string.format("P%d:%d->%d", pid, oldVal, signedVal),
    }
    undoStack[#undoStack + 1] = entry
    undoCursor = #undoStack
    entry.snapshotSlot = undoCursor
    restartUndoIdleTimer()
    local dispCtrl = preset.getControl(35)
    if dispCtrl then
        dispCtrl:repaint()
    end
    return undoCursor
end

-- Send a synth parameter change (41H) to the Z1 and record it in the Undo/Redo stack
function sendParamChange(exId, paramId, signedVal, ctrlId)
    recordParamChange(exId, paramId, signedVal, ctrlId)
    sendSysexBody(buildParamChangeBody(paramId, signedVal, exId))
end

local function applyParamUndoEntry(entry, targetVal, snapshotSlot)
    if snapshotSlot and hasSnapshotsApi() then
        if _G.snapshots.isUsed and _G.snapshots.isUsed(SNAPSHOT_BANK, snapshotSlot) then
            _G.snapshots.load(SNAPSHOT_BANK, snapshotSlot)
        end
    end
    paramValues[entry.id14] = targetVal
    if entry.exId == 0 and currentUnpackedProgram and entry.paramId >= 17 and entry.paramId <= 576 then
        currentUnpackedProgram[entry.paramId] = targetVal & 0xFF
    end
    if entry.ctrlId then
        local c = controls.get(entry.ctrlId)
        if c and c.getValue then
            local vo = c:getValue("value")
            if vo then
                vo:updateValue(targetVal)
            end
        end
    end
    sendSysexBody(buildParamChangeBody(entry.paramId, targetVal, entry.exId))
    refreshStatusAndNameWidgets()
end

function undoPatch()
    stopUndoIdleTimer()
    local current = undoStack[undoCursor]
    if not current or undoCursor < 1 then
        info.setText("Undo: Nothing to Undo")
        return false
    end
    current.sealed = true
    if current.kind == "param" then
        undoCursor = undoCursor - 1
        local prev = undoStack[undoCursor]
        local prevSlot = (prev and prev.savedToSnapshot) and prev.snapshotSlot or nil
        applyParamUndoEntry(current, current.oldVal, prevSlot)
        info.setText(string.format("Undo P%d = %d", current.paramId, current.oldVal))
        return true
    end
    if undoCursor <= 1 then
        info.setText("Undo: At Oldest State")
        return false
    end
    undoCursor = undoCursor - 1
    local state = undoStack[undoCursor]
    if state.kind == "param" then
        applyParamUndoEntry(state, state.newVal, state.savedToSnapshot and state.snapshotSlot or nil)
    else
        applyPatchState(state, true, state.savedToSnapshot and state.snapshotSlot or nil)
    end
    info.setText(string.format("Undo (%d/%d): %s", undoCursor, #undoStack, state.label or getProgramNameString()))
    return true
end

function redoPatch()
    stopUndoIdleTimer()
    if undoCursor >= #undoStack then
        info.setText("Redo: At Newest State")
        return false
    end
    undoCursor = undoCursor + 1
    local state = undoStack[undoCursor]
    state.sealed = true
    if state.kind == "param" then
        applyParamUndoEntry(state, state.newVal, state.savedToSnapshot and state.snapshotSlot or nil)
        info.setText(string.format("Redo P%d = %d", state.paramId, state.newVal))
        return true
    end
    applyPatchState(state, true, state.savedToSnapshot and state.snapshotSlot or nil)
    info.setText(string.format("Redo (%d/%d): %s", undoCursor, #undoStack, state.label or getProgramNameString()))
    return true
end

-- ============================================================================
-- 4. Current Program Edit Buffer Dump Request (F0 42 3g 46 10 00 F7)
-- ============================================================================

function buildCurrentProgramDumpRequestBody(gCh)
    local g = gCh or getGlobalChannel()
    return { 0x42, 0x30 | (g & 0x0F), 0x46, 0x10, 0x00 }
end

function requestCurrentProgramDump()
    -- Always keep a backup of the current E1 patch before requesting a new dump from the Z1
    savePatchBackup("Pre-Req Backup")
    sendSysexBody(buildCurrentProgramDumpRequestBody())
    info.setText("Saved Backup & Requested 40H")
end

-- ============================================================================
-- 5. Patch Dump Parsing (Device Inquiry Reply & Current Program Data Dump 40H)
-- ============================================================================

-- Populate Program Name from unpacked bytes 1..16 without echoing SysEx back to Z1
function setProgramNameFromDump(unpackedBytes)
    if type(unpackedBytes) ~= "table" then
        return
    end
    for i = 1, 16 do
        local b = unpackedBytes[i]
        if type(b) == "number" and b >= 0x20 and b <= 0x7F then
            programNameChars[i] = b
        else
            programNameChars[i] = 0x20
        end
    end
    refreshStatusAndNameWidgets()
end

-- Normalize a sysexBlock or raw Lua byte table into a 1-based byte accessor (without leading F0 / trailing F7)
local function readSysexBodyBytes(sysexBlock, maxPayloadBytes)
    local bytes = {}
    if type(sysexBlock) == "table" then
        local startIdx = (sysexBlock[1] == 0xF0) and 2 or 1
        local endIdx = #sysexBlock
        if sysexBlock[endIdx] == 0xF7 then
            endIdx = endIdx - 1
        end
        local limit = maxPayloadBytes and math.min(endIdx, startIdx + maxPayloadBytes - 1) or endIdx
        for i = startIdx, limit do
            bytes[#bytes + 1] = sysexBlock[i]
        end
        return bytes, (endIdx - startIdx + 1)
    end

    if not sysexBlock or not sysexBlock.getLength then
        return bytes, 0
    end
    local totalLen = sysexBlock:getLength()
    if totalLen <= 0 then
        return bytes, 0
    end
    local firstByte = sysexBlock:peek(1)
    local startIdx = (firstByte == 0xF0) and 2 or 1
    local endIdx = totalLen
    if sysexBlock:peek(endIdx) == 0xF7 then
        endIdx = endIdx - 1
    end
    local limit = maxPayloadBytes and math.min(endIdx, startIdx + maxPayloadBytes - 1) or endIdx
    for i = startIdx, limit do
        bytes[#bytes + 1] = sysexBlock:peek(i)
    end
    return bytes, (endIdx - startIdx + 1)
end

-- Parse incoming SysEx messages (Device Inquiry Reply & Current Program Data Dump 40H)
function parseSysexMessage(sysexBlock)
    -- Read up to 700 body bytes so full 666-byte 40H dumps are captured completely for backup/recovery
    local body, totalBodyLen = readSysexBodyBytes(sysexBlock, 700)
    if #body < 5 then
        return false
    end

    -- 1. Universal Device Inquiry Reply: 7E 0g 06 02 42 46 00 01 00 mnL mnM mjL mjM
    if body[1] == 0x7E and body[3] == 0x06 and body[4] == 0x02 and body[5] == 0x42 then
        local g = body[2] & 0x0F
        local family = (body[6] or 0) | ((body[7] or 0) << 7)
        local member = (body[8] or 0) | ((body[9] or 0) << 7)
        local minor  = (body[10] or 0) | ((body[11] or 0) << 7)
        local major  = (body[12] or 0) | ((body[13] or 0) << 7)
        if family == 0x46 then
            z1Status.connected = true
            z1Status.channel   = g + 1
            z1Status.familyId  = family
            z1Status.memberId  = member
            z1Status.version   = string.format("v%d.%02d", major, minor)
            local dev = preset.getDevice(DEVICE_ID)
            if dev and dev.setChannel then
                dev:setChannel(z1Status.channel)
            end
            info.setText(string.format("Z1 Connected Ch%d %s", z1Status.channel, z1Status.version))
            refreshStatusAndNameWidgets()
            return true, "inquiry"
        end
    end

    -- 2. Korg Z1 Current Program Data Dump (40H), Program Data Dump (4CH), or Parameter Change (41H)
    if body[1] == 0x42 and (body[2] & 0xF0) == 0x30 and body[3] == 0x46 then
        local func = body[4]

        -- 2a. Program Parameter Change (41H): 42 3g 46 41 01 idL idM valL valM
        if func == 0x41 and body[5] == 0x01 and #body >= 9 then
            local id14 = (body[6] & 0x7F) | ((body[7] & 0x7F) << 7)
            local exId = (id14 >> 11) & 0x07
            local paramId = id14 & 0x07FF
            local val14 = (body[8] & 0x7F) | ((body[9] & 0x7F) << 7)
            local signedVal = (val14 >= 0x2000) and (val14 - 0x4000) or val14
            if exId == 0 and paramId >= 1 and paramId <= 16 then
                programNameChars[paramId] = signedVal & 0x7F
                if currentUnpackedProgram then
                    currentUnpackedProgram[paramId] = signedVal & 0x7F
                end
                refreshStatusAndNameWidgets()
            else
                recordParamChange(exId, paramId, signedVal)
            end
            return true, "param_change"
        end

        local dataStart = nil
        if func == 0x40 and body[5] == 0x01 then
            dataStart = 6 -- after 42 3g 46 40 01
        elseif func == 0x4C then
            dataStart = 8 -- after 42 3g 46 4C ub pp 00
        end

        if dataStart and #body >= dataStart then
            -- Automatically back up the existing E1 patch before overwriting it with the incoming dump
            savePatchBackup("Pre-Dump Backup")

            local payload = {}
            for i = dataStart, #body do
                payload[#payload + 1] = body[i]
            end

            -- Distinguish between:
            -- (a) Direct 16-byte raw ASCII after header (e.g., 16 printable chars 20H..7FH in unit test)
            -- (b) Standard Z1 Korg 7-to-8-bit packed dump (where payload[1] and payload[9] are MSB bitmask bytes = 0x00 for ASCII)
            local isRaw16Ascii = (#payload >= 16 and totalBodyLen == (dataStart - 1 + 16)
                and payload[1] >= 0x20 and payload[9] >= 0x20)
            local unpacked
            if isRaw16Ascii then
                unpacked = {}
                for i = 1, 16 do
                    unpacked[i] = payload[i]
                end
                z1Status.lastDump = "40H Raw16"
            else
                unpacked = unpackKorgData(payload)
                z1Status.lastDump = string.format("40H (%dB)", totalBodyLen + 2)
            end

            currentUnpackedProgram = unpacked
            setProgramNameFromDump(unpacked)
            pushUndoState("Dump:" .. getProgramNameString())
            info.setText("Patch: " .. getProgramNameString())
            return true, "program_dump"
        end
    end

    return false
end

function midi.onSysex(_midiInput, sysexBlock)
    parseSysexMessage(sysexBlock)
end

-- ============================================================================
-- 6. Custom Paint Callbacks & Control Callbacks
-- ============================================================================

function fmtAsciiChar(_valueObject, value)
    local v = math.floor(value)
    if v < 0x20 or v > 0x7F then
        v = 0x20
    end
    if v == 0x20 then
        return "SPC (32)"
    elseif v == 0x7F then
        return "DEL (127)"
    end
    return string.format("'%s' (%d)", string.char(v), v)
end

function paintZ1Status(control)
    local bounds = control:getBounds()
    local w = bounds[WIDTH]
    local h = bounds[HEIGHT]
    graphics.setColor(0x18202C)
    graphics.fillRect(0, 0, w, h)
    graphics.setColor(0x03A598)
    graphics.drawRect(0, 0, w, h)

    local hdr = z1Status.connected
        and string.format("Z1 Ch%d %s | %s", z1Status.channel, z1Status.version, z1Status.lastDump)
        or ("Z1 OFFLINE | " .. z1Status.lastDump)
    graphics.setColor(z1Status.connected and GREEN or ORANGE)
    graphics.print(6, 3, hdr, w - 12, LEFT, REGULAR, SMALL)

    local bkName = patchBackup and string.sub(getProgramNameString(patchBackup.nameChars), 1, 16) or "None"
    graphics.setColor(WHITE)
    graphics.print(6, 23, "Bk: " .. bkName, w - 12, LEFT, BOLD, MEDIUM)
end

function paintProgramName(control)
    local bounds = control:getBounds()
    local w = bounds[WIDTH]
    local h = bounds[HEIGHT]
    graphics.setColor(0x18202C)
    graphics.fillRect(0, 0, w, h)
    graphics.setColor(0x529DEC)
    graphics.drawRect(0, 0, w, h)

    local nameStr = getProgramNameString()
    local curChar = string.sub(nameStr, selectedCharPos, selectedCharPos)
    local undoInfo = string.format("U:%d/%d", undoCursor, #undoStack)
    graphics.setColor(ORANGE)
    graphics.print(
        6,
        3,
        string.format("NAME [P%02d:'%s' | %s]", selectedCharPos, curChar, undoInfo),
        w - 12,
        LEFT,
        REGULAR,
        SMALL
    )

    graphics.setColor(WHITE)
    graphics.print(6, 23, nameStr, w - 12, LEFT, BOLD, MEDIUM)
end

function onHandshakeBtn(_valueObject, value)
    if math.floor(value) > 0 then
        sendDeviceInquiry()
    end
end

function onPatchRequestBtn(_valueObject, value)
    if math.floor(value) > 0 then
        requestCurrentProgramDump()
    end
end

function onRecoverBackupBtn(_valueObject, value)
    if math.floor(value) > 0 then
        recoverPatchBackup()
    end
end

function onBackupNowBtn(_valueObject, value)
    if math.floor(value) > 0 then
        savePatchBackup("Manual Backup")
        info.setText("Backup: " .. getProgramNameString())
    end
end

function onUndoBtn(_valueObject, value)
    if math.floor(value) > 0 then
        undoPatch()
    end
end

function onRedoBtn(_valueObject, value)
    if math.floor(value) > 0 then
        redoPatch()
    end
end

function onNamePos(_valueObject, value)
    local pos = math.floor(value)
    if pos < 1 then
        pos = 1
    elseif pos > 16 then
        pos = 16
    end
    selectedCharPos = pos
    refreshStatusAndNameWidgets()
end

function onNameChar(_valueObject, value)
    if suppressCharCallback then
        return
    end
    local ascii = math.floor(value)
    if ascii < 0x20 then
        ascii = 0x20
    elseif ascii > 0x7F then
        ascii = 0x7F
    end
    -- Patch Name edits (IDs 1..16) are sent directly to the Z1 and do NOT push to Undo/Redo
    programNameChars[selectedCharPos] = ascii
    if currentUnpackedProgram then
        currentUnpackedProgram[selectedCharPos] = ascii
    end
    sendSysexBody(buildParamChangeBody(selectedCharPos, ascii))
    local dispCtrl = preset.getControl(35)
    if dispCtrl then
        dispCtrl:repaint()
    end
end

-- ============================================================================
-- 7. Lifecycle Hooks
-- ============================================================================

function preset.onLoad()
    suppressCharCallback = true
    local statusCtrl = preset.getControl(3)
    if statusCtrl then
        statusCtrl:setPaintCallback(paintZ1Status)
    end
    local dispCtrl = preset.getControl(35)
    if dispCtrl then
        dispCtrl:setPaintCallback(paintProgramName)
    end
end

function preset.onReady()
    suppressCharCallback = false
    if #undoStack == 0 then
        pushUndoState("Init", true)
    end
    if not patchBackup then
        savePatchBackup("Init Backup", true)
    end
    refreshStatusAndNameWidgets()
    info.setText("Z1 Base Ready")
end
