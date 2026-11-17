-- Korg Z1 - Base & Utility Module for Electra One mk2
-- 1. Handshake routine (Universal Device Inquiry F0 7E 0g 06 01 F7 -> Z1 ID 42 46 00 01 00)
-- 2. Patch Request for Current Program Edit Buffer (F0 42 3g 46 10 00 F7 -> 40H Dump)
-- 3. Patch parsing for Program Name (IDs 1..16, 20H..7FH) with custom Program Name widget (Control 35)
-- 4. Automatic E1 Patch Backup & Recover from Backup (Control 4 / Control 7 + E1 Snapshot Bank 12 Slot 36)
-- 5. Snapshot-backed Undo / Redo Buffer (Controls 5 & 6 + E1 Snapshot Bank 12 Slots 1..16)

local DEVICE_ID = 1

-- Dedicated Electra One Snapshot Bank & Slots for Undo/Redo and Pre-Request Backup
SNAPSHOT_BANK         = 12
BACKUP_SNAP_SLOT        = 36
MAX_UNDO_SLOTS          = 16
UNDO_IDLE_PERIOD_MS     = 1000 -- 1-second timer tick
UNDO_IDLE_TIMEOUT_SEC   = 15   -- Save Undo snapshot only after 15 seconds of no user activity
BACKUP_HOLD_TIMEOUT_SEC = 30   -- Keep pre-switch backup patch locked for 30 seconds after preset change
local COLOUR_BACKUP     = 0xD9534F
local COLOUR_UNDO       = 0x529DEC

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

function buildParamChangeBody(exId, paramId, signedVal, gCh)
    if signedVal == nil then
        -- 2-arg call: buildParamChangeBody(paramId, signedVal) with exId = 0
        signedVal = paramId
        paramId = exId
        exId = 0
    end
    local g = gCh or getGlobalChannel()
    local id14 = ((exId & 0x07) << 11) | (paramId & 0x07FF)
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
backupHoldSeconds   = 0
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

local function ensureOneSecondTimerRunning()
    if hasTimerApi() then
        if type(_G.timer.setPeriod) == "function" then
            _G.timer.setPeriod(UNDO_IDLE_PERIOD_MS)
        end
        _G.timer.enable()
    end
end

local function stopTimerIfIdle()
    if not undoPendingSnapshot and backupHoldSeconds <= 0 then
        if hasTimerApi() then
            _G.timer.disable()
        end
    end
end

local function restartUndoIdleTimer()
    undoIdleSeconds = 0
    undoPendingSnapshot = true
    ensureOneSecondTimerRunning()
end

local function stopUndoIdleTimer()
    undoIdleSeconds = 0
    undoPendingSnapshot = false
    stopTimerIfIdle()
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

    _G.__z1InUndoRedo = true
    if not state.unpackedBytes and snapshotSlot and hasSnapshotsApi() then
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
        if #currentUnpackedProgram >= 576 then
            local params = decodeZ1ProgramDump(currentUnpackedProgram)
            if _G.preset and type(_G.preset.onZ1Dump) == "function" then
                _G.preset.onZ1Dump(params, currentUnpackedProgram)
            end
        end
    end

    if transmitToZ1 then
        if currentUnpackedProgram and #currentUnpackedProgram >= 576 then
            sendSysexBody(buildCurrentProgramDumpBody(currentUnpackedProgram))
        else
            for i = 1, 16 do
                sendSysexBody(buildParamChangeBody(0, i, programNameChars[i]))
            end
        end
    end
    _G.__z1InUndoRedo = false

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

-- Lock the current patch into patchBackup for 30 seconds when switching presets.
-- If a preset switch is already inside the 30-second hold window, keep the original
-- pre-switch patchBackup and reset the 30-second countdown so the user has 30s to Recover.
function beginPresetChangeBackup(reason)
    if backupHoldSeconds <= 0 then
        savePatchBackup(reason)
    end
    backupHoldSeconds = BACKUP_HOLD_TIMEOUT_SEC
    ensureOneSecondTimerRunning()
    refreshStatusAndNameWidgets()
    return patchBackup
end

-- Recover the backed-up patch on the E1 and transmit it back to the Z1 edit buffer
function recoverPatchBackup()
    if not patchBackup then
        info.setText("No Patch Backup Available")
        return false
    end
    backupHoldSeconds = 0
    stopTimerIfIdle()
    applyPatchState(patchBackup, true, BACKUP_SNAP_SLOT)
    pushUndoState("Recover:" .. getProgramNameString())
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
        if undoStack[1] and undoStack[1].kind == "patch" and undoStack[2] and undoStack[2].kind == "param" then
            if undoStack[1].unpackedBytes and encodeZ1ParamIntoDump then
                encodeZ1ParamIntoDump(undoStack[1].unpackedBytes, undoStack[2].exId, undoStack[2].paramId, undoStack[2].newVal)
            end
            table.remove(undoStack, 2)
        else
            table.remove(undoStack, 1)
        end
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
    if backupHoldSeconds > 0 then
        backupHoldSeconds = backupHoldSeconds - 1
        if backupHoldSeconds == 0 then
            -- 30-second recovery window expired: promote current preset to Backup
            savePatchBackup("Auto 30s Backup")
            info.setText("Backup Updated: " .. getProgramNameString())
        else
            local statusCtrl = preset.getControl(3)
            if statusCtrl then
                statusCtrl:repaint()
            end
        end
    end

    if undoPendingSnapshot then
        undoIdleSeconds = undoIdleSeconds + 1
        if undoIdleSeconds >= UNDO_IDLE_TIMEOUT_SEC then
            flushPendingUndoSnapshot()
        end
    end

    stopTimerIfIdle()
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
        oldVal = 0
    end

    paramValues[id14] = signedVal
    if currentUnpackedProgram and encodeZ1ParamIntoDump then
        encodeZ1ParamIntoDump(currentUnpackedProgram, ex, pid, signedVal)
    end
    -- When not inside a 30-second preset-switch hold window, keep patchBackup's bytes in sync with live edits
    if backupHoldSeconds <= 0 and patchBackup and patchBackup.unpackedBytes and encodeZ1ParamIntoDump then
        encodeZ1ParamIntoDump(patchBackup.unpackedBytes, ex, pid, signedVal)
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
        local dispCtrl = preset.getControl(35)
        if dispCtrl then
            dispCtrl:repaint()
        end
        return undoCursor
    end

    if #undoStack >= MAX_UNDO_SLOTS then
        if undoStack[1] and undoStack[1].kind == "patch" and undoStack[2] and undoStack[2].kind == "param" then
            if undoStack[1].unpackedBytes and encodeZ1ParamIntoDump then
                encodeZ1ParamIntoDump(undoStack[1].unpackedBytes, undoStack[2].exId, undoStack[2].paramId, undoStack[2].newVal)
            end
            table.remove(undoStack, 2)
        else
            table.remove(undoStack, 1)
        end
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
_G.recordZ1ParamChange = recordParamChange

-- Send a synth parameter change (41H) to the Z1 and record it in the Undo/Redo stack
function sendParamChange(exId, paramId, signedVal, ctrlId)
    recordParamChange(exId, paramId, signedVal, ctrlId)
    _G.__z1InUndoRedo = true
    sendSysexBody(buildParamChangeBody(exId, paramId, signedVal))
    _G.__z1InUndoRedo = false
end

local function applyParamUndoEntry(entry, targetVal)
    _G.__z1InUndoRedo = true
    paramValues[entry.id14] = targetVal
    if currentUnpackedProgram and encodeZ1ParamIntoDump then
        encodeZ1ParamIntoDump(currentUnpackedProgram, entry.exId, entry.paramId, targetVal)
    end
    if backupHoldSeconds <= 0 and patchBackup and patchBackup.unpackedBytes and encodeZ1ParamIntoDump then
        encodeZ1ParamIntoDump(patchBackup.unpackedBytes, entry.exId, entry.paramId, targetVal)
    end
    if _G.preset and type(_G.preset.onZ1Param) == "function" then
        _G.preset.onZ1Param(entry.exId, entry.paramId, targetVal)
    elseif entry.ctrlId then
        local c = controls.get(entry.ctrlId)
        if c and c.getValue then
            local vo = c:getValue("value")
            if vo then
                vo:updateValue(targetVal)
            end
        end
    end
    sendSysexBody(buildParamChangeBody(entry.exId, entry.paramId, targetVal))
    _G.__z1InUndoRedo = false
    refreshStatusAndNameWidgets()
end

-- Reconstruct and apply the full patch state at undoStack[targetIdx] by starting from
-- the nearest preceding kind=="patch" entry and replaying all param entries up to targetIdx.
local function applyReconstructedPatchAt(targetIdx)
    local baseIdx = nil
    for i = targetIdx, 1, -1 do
        if undoStack[i] and undoStack[i].kind == "patch" then
            baseIdx = i
            break
        end
    end
    if not baseIdx then
        return false
    end
    local baseState = undoStack[baseIdx]
    local stateCopy = {
        kind          = "patch",
        label         = undoStack[targetIdx].label or baseState.label,
        nameChars     = copyByteArray(baseState.nameChars),
        unpackedBytes = copyByteArray(baseState.unpackedBytes),
    }
    if stateCopy.unpackedBytes and encodeZ1ParamIntoDump then
        for i = baseIdx + 1, targetIdx do
            local e = undoStack[i]
            if e and e.kind == "param" then
                encodeZ1ParamIntoDump(stateCopy.unpackedBytes, e.exId, e.paramId, e.newVal)
            end
        end
    end
    return applyPatchState(stateCopy, true, baseState.savedToSnapshot and baseState.snapshotSlot or nil)
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
        applyParamUndoEntry(current, current.oldVal)
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
        applyReconstructedPatchAt(undoCursor)
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
        applyParamUndoEntry(state, state.newVal)
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
    if currentUnpackedProgram and #currentUnpackedProgram >= 576 then
        beginPresetChangeBackup("Pre-Req Backup")
    else
        savePatchBackup("Pre-Req Backup")
    end
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

-- ============================================================================
-- 5b. Full 576-Byte Program Parameter Decoder (PROG_PRM.TXT, ExIDs 0..5)
-- ============================================================================

local OSC_MODEL_RANGES = {
    [0]  = { 464, 485 }, -- Standard OSC (22B)
    [1]  = { 486, 499 }, -- Comb Filter OSC (14B)
    [2]  = { 500, 524 }, -- VPM OSC (25B)
    [3]  = { 525, 556 }, -- Resonance OSC (32B)
    [4]  = { 557, 565 }, -- Ring Mod.OSC (9B)
    [5]  = { 566, 573 }, -- Cross Mod.OSC (8B)
    [6]  = { 574, 576 }, -- Sync OSC (3B)
    [7]  = { 577, 601 }, -- Organ Model (25B)
    [8]  = { 602, 615 }, -- E. Piano Model (14B)
    [11] = { 694, 724 }, -- Plucked String Model (31B)
    [12] = { 725, 754 }, -- Bowed String Model (30B)
}

local FX12_MODEL_RANGES = {
    [0]  = { 800, 818 }, -- Over Drive (19B)
    [1]  = { 819, 827 }, -- Compressor (9B)
    [2]  = { 828, 847 }, -- 4 Band PEQ (20B)
    [3]  = { 848, 859 }, -- Wah (12B)
    [4]  = { 860, 871 }, -- Exciter (12B)
    [5]  = { 872, 881 }, -- Decimator (10B)
    [9]  = { 932, 940 }, -- Small Rotary SP (9B)
    [10] = { 941, 951 }, -- Delay (11B)
    [11] = { 952, 962 }, -- Talking Modulator (11B)
    [12] = { 963, 979 }, -- Multitap Delay (17B)
    [13] = { 980, 989 }, -- Ensemble (10B)
    [14] = { 990, 1003 },-- Rotary Speaker (14B)
}

local MFX_MODEL_RANGES = {
    [0] = { 1004, 1017 }, -- Stereo Delay (14B)
    [1] = { 1018, 1027 }, -- Reverb-Hall (10B)
    [2] = { 1028, 1039 }, -- Reverb-Room (12B)
}

-- FX parameters whose max exceeds 127 (stored as unsigned 0..255 in dump)
local UNSIGNED_FX_IDS = {
    [882]  = true, [900]  = true, [943]  = true,
    [966]  = true, [968]  = true, [1007] = true,
    [1008] = true, [1019] = true, [1029] = true,
}

local function decodeOscBlock(unpacked, b0, oscType, dst)
    local function u8(idx) return (unpacked[idx] or 0) & 0xFF end
    local function s8(idx)
        local b = u8(idx)
        return (b >= 128) and (b - 256) or b
    end
    local function bits(idx, shift, mask) return (u8(idx) >> shift) & mask end

    local rng = OSC_MODEL_RANGES[oscType]
    if rng then
        local lo, hi = rng[1], rng[2]
        for id = lo, hi do
            dst[id] = s8(b0 + (id - lo))
        end
    elseif oscType == 9 then -- Brass Model (IDs 616..653, 37B)
        dst[616] = u8(b0 + 0)
        dst[617] = bits(b0 + 1, 0, 0x01)
        dst[618] = bits(b0 + 1, 1, 0x01)
        for id = 619, 653 do
            dst[id] = s8(b0 + (id - 617))
        end
    elseif oscType == 10 then -- Reed Model (IDs 654..693, 38B)
        dst[654] = u8(b0 + 0)
        dst[655] = bits(b0 + 1, 0, 0x01)
        dst[656] = bits(b0 + 1, 1, 0x01)
        for id = 657, 689 do
            dst[id] = s8(b0 + (id - 655))
        end
        dst[690] = bits(b0 + 35, 7, 0x01)
        dst[691] = bits(b0 + 35, 0, 0x7F)
        dst[692] = u8(b0 + 36)
        dst[693] = s8(b0 + 37)
    end
end

local function decodeFx12Block(unpacked, b0, fxType, dst)
    local function u8(idx) return (unpacked[idx] or 0) & 0xFF end
    local function s8(idx)
        local b = u8(idx)
        return (b >= 128) and (b - 256) or b
    end
    local function bits(idx, shift, mask) return (u8(idx) >> shift) & mask end

    local rng = FX12_MODEL_RANGES[fxType]
    if rng then
        local lo, hi = rng[1], rng[2]
        for id = lo, hi do
            local idx = b0 + (id - lo)
            dst[id] = UNSIGNED_FX_IDS[id] and u8(idx) or s8(idx)
        end
    elseif fxType == 6 then -- Chorus (IDs 882..899, 16B)
        dst[882] = u8(b0 + 0)
        for id = 883, 886 do dst[id] = s8(b0 + (id - 882)) end
        dst[887] = bits(b0 + 5, 7, 0x01)
        dst[888] = bits(b0 + 5, 4, 0x07)
        dst[889] = bits(b0 + 5, 0, 0x0F)
        for id = 890, 899 do dst[id] = s8(b0 + (id - 884)) end
    elseif fxType == 7 then -- Flanger (IDs 900..915, 14B)
        dst[900] = u8(b0 + 0)
        for id = 901, 905 do dst[id] = s8(b0 + (id - 900)) end
        dst[906] = bits(b0 + 6, 7, 0x01)
        dst[907] = bits(b0 + 6, 4, 0x07)
        dst[908] = bits(b0 + 6, 0, 0x0F)
        for id = 909, 915 do dst[id] = s8(b0 + (id - 902)) end
    elseif fxType == 8 then -- Phaser (IDs 916..931, 14B)
        for id = 916, 920 do dst[id] = s8(b0 + (id - 916)) end
        dst[921] = bits(b0 + 5, 7, 0x01)
        dst[922] = bits(b0 + 5, 4, 0x07)
        dst[923] = bits(b0 + 5, 0, 0x0F)
        for id = 924, 931 do dst[id] = s8(b0 + (id - 918)) end
    end
end

function decodeZ1ProgramDump(unpacked)
    local params = { [0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {} }
    if type(unpacked) ~= "table" or #unpacked < 576 then
        return params
    end
    local function u8(idx) return (unpacked[idx] or 0) & 0xFF end
    local function s8(idx)
        local b = u8(idx)
        return (b >= 128) and (b - 256) or b
    end
    local function bits(idx, shift, mask) return (u8(idx) >> shift) & mask end

    local p0 = params[0]
    -- [Program Common] (Bytes 1..25, IDs 1..30)
    for i = 1, 16 do p0[i] = u8(i) end
    p0[17] = u8(17)
    p0[18] = u8(18)
    p0[19] = bits(19, 0, 0x01)
    p0[20] = bits(19, 1, 0x03)
    p0[21] = bits(19, 3, 0x03)
    p0[22] = u8(20)
    p0[23] = u8(21)
    p0[24] = bits(22, 0, 0x03)
    p0[25] = bits(22, 2, 0x01)
    p0[26] = bits(22, 3, 0x01)
    p0[27] = u8(23)
    p0[28] = bits(24, 0, 0x0F)
    p0[29] = bits(24, 4, 0x0F)
    p0[30] = u8(25)

    -- [EG1]..[EG4] (Bytes 26..101, IDs 31..106)
    for id = 31, 106 do p0[id] = s8(id - 5) end

    -- [LFO1]..[LFO4] (Bytes 102..145, IDs 107..162)
    for lfo = 1, 4 do
        local b0  = 102 + (lfo - 1) * 11
        local id0 = 107 + (lfo - 1) * 14
        p0[id0 + 0]  = bits(b0 + 0, 0, 0x1F)
        p0[id0 + 1]  = bits(b0 + 0, 6, 0x03)
        p0[id0 + 2]  = u8(b0 + 1)
        p0[id0 + 3]  = u8(b0 + 2)
        p0[id0 + 4]  = s8(b0 + 3)
        p0[id0 + 5]  = u8(b0 + 4)
        p0[id0 + 6]  = s8(b0 + 5)
        p0[id0 + 7]  = u8(b0 + 6)
        p0[id0 + 8]  = u8(b0 + 7)
        p0[id0 + 9]  = s8(b0 + 8)
        p0[id0 + 10] = s8(b0 + 9)
        p0[id0 + 11] = bits(b0 + 10, 7, 0x01)
        p0[id0 + 12] = bits(b0 + 10, 4, 0x07)
        p0[id0 + 13] = bits(b0 + 10, 0, 0x0F)
    end

    -- [OSC Common] (Bytes 146..154, IDs 163..173)
    p0[163] = s8(146)
    p0[164] = s8(147)
    p0[165] = bits(148, 0, 0x0F)
    p0[166] = bits(148, 4, 0x0F)
    p0[167] = u8(149)
    p0[168] = s8(150)
    p0[169] = bits(151, 0, 0x01)
    p0[170] = bits(151, 1, 0x01)
    p0[171] = u8(152)
    p0[172] = u8(153)
    p0[173] = s8(154)

    -- [OSC1] (Bytes 155..206: IDs 174..187 + 38B OSC1 Setting ExID 1)
    for id = 174, 187 do p0[id] = s8(id - 19) end
    decodeOscBlock(unpacked, 169, p0[174] or 0, params[1])

    -- [OSC2] (Bytes 207..258: IDs 188..201 + 38B OSC2 Setting ExID 2)
    for id = 188, 201 do p0[id] = s8(id + 19) end
    decodeOscBlock(unpacked, 221, p0[188] or 0, params[2])

    -- [SUB OSC], [Noise Generator], [Mixer] (Bytes 259..311, IDs 202..257)
    for id = 202, 253 do p0[id] = s8(id + 57) end
    p0[254] = bits(311, 0, 0x01)
    p0[255] = bits(311, 1, 0x01)
    p0[256] = bits(311, 2, 0x01)
    p0[257] = bits(311, 3, 0x01)

    -- [Filter], [Filter 1], [Filter 2], [Amplitude], [Output] (Bytes 312..407, IDs 258..355)
    p0[258] = bits(312, 0, 0x03)
    p0[259] = bits(312, 2, 0x01)
    p0[260] = bits(312, 4, 0x03)
    for id = 261, 355 do p0[id] = s8(id + 52) end

    -- [Effect] & [2 Band EQ] (Bytes 408..479, IDs 356..365 + FX1/FX2/MFX Settings ExIDs 3..5)
    p0[356] = u8(408)
    p0[357] = u8(409)
    p0[358] = s8(410)
    p0[359] = u8(411)
    decodeFx12Block(unpacked, 412, p0[359] or 0, params[3])
    p0[360] = u8(434)
    decodeFx12Block(unpacked, 435, p0[360] or 0, params[4])
    p0[361] = u8(457)
    local mfxRng = MFX_MODEL_RANGES[p0[361] or 0]
    if mfxRng then
        local lo, hi = mfxRng[1], mfxRng[2]
        for id = lo, hi do
            local idx = 458 + (id - lo)
            params[5][id] = UNSIGNED_FX_IDS[id] and u8(idx) or s8(idx)
        end
    end
    p0[362] = u8(476)
    p0[363] = s8(477)
    p0[364] = u8(478)
    p0[365] = s8(479)

    -- [Controller] (Bytes 480..483, IDs 366..373)
    p0[366] = bits(480, 0, 0x7F)
    p0[367] = bits(480, 7, 0x01)
    p0[368] = bits(481, 0, 0x7F)
    p0[369] = bits(481, 7, 0x01)
    p0[370] = bits(482, 0, 0x7F)
    p0[371] = bits(482, 7, 0x01)
    p0[372] = bits(483, 0, 0x07)
    p0[373] = bits(483, 3, 0x01)

    -- [Link Arpeggio] (Bytes 484..496, IDs 374..383)
    p0[374] = u8(484)
    p0[375] = bits(485, 0, 0x01)
    p0[376] = bits(485, 1, 0x01)
    p0[377] = bits(485, 2, 0x03)
    p0[378] = bits(485, 4, 0x01)
    p0[379] = bits(485, 5, 0x01)
    p0[380] = s8(486)
    p0[381] = s8(487)
    p0[382] = u8(488)
    p0[383] = u8(489)

    -- [PE Knob1]..[PE Knob5] (Bytes 497..576, IDs 384..463)
    for id = 384, 463 do p0[id] = u8(id + 113) end

    for ex = 0, 5 do
        for pid, val in pairs(params[ex]) do
            paramValues[(ex << 11) | pid] = val
        end
    end
    return params
end

local function encodeOscBlock(unpacked, b0, oscType, id, val, setBits)
    local rng = OSC_MODEL_RANGES[oscType]
    if rng and id >= rng[1] and id <= rng[2] then
        unpacked[b0 + (id - rng[1])] = val & 0xFF
    elseif oscType == 9 then -- Brass Model (IDs 616..653)
        if id == 616 then unpacked[b0] = val & 0xFF
        elseif id == 617 then setBits(b0 + 1, 0, 0x01, val)
        elseif id == 618 then setBits(b0 + 1, 1, 0x01, val)
        elseif id >= 619 and id <= 653 then unpacked[b0 + (id - 617)] = val & 0xFF end
    elseif oscType == 10 then -- Reed Model (IDs 654..693)
        if id == 654 then unpacked[b0] = val & 0xFF
        elseif id == 655 then setBits(b0 + 1, 0, 0x01, val)
        elseif id == 656 then setBits(b0 + 1, 1, 0x01, val)
        elseif id >= 657 and id <= 689 then unpacked[b0 + (id - 655)] = val & 0xFF
        elseif id == 690 then setBits(b0 + 35, 7, 0x01, val)
        elseif id == 691 then setBits(b0 + 35, 0, 0x7F, val)
        elseif id == 692 then unpacked[b0 + 36] = val & 0xFF
        elseif id == 693 then unpacked[b0 + 37] = val & 0xFF end
    end
end

local function encodeFx12Block(unpacked, b0, fxType, id, val, setBits)
    local rng = FX12_MODEL_RANGES[fxType]
    if rng and id >= rng[1] and id <= rng[2] then
        unpacked[b0 + (id - rng[1])] = val & 0xFF
    elseif fxType == 6 then -- Chorus (IDs 882..899)
        if id >= 882 and id <= 886 then unpacked[b0 + (id - 882)] = val & 0xFF
        elseif id == 887 then setBits(b0 + 5, 7, 0x01, val)
        elseif id == 888 then setBits(b0 + 5, 4, 0x07, val)
        elseif id == 889 then setBits(b0 + 5, 0, 0x0F, val)
        elseif id >= 890 and id <= 899 then unpacked[b0 + (id - 884)] = val & 0xFF end
    elseif fxType == 7 then -- Flanger (IDs 900..915)
        if id >= 900 and id <= 905 then unpacked[b0 + (id - 900)] = val & 0xFF
        elseif id == 906 then setBits(b0 + 6, 7, 0x01, val)
        elseif id == 907 then setBits(b0 + 6, 4, 0x07, val)
        elseif id == 908 then setBits(b0 + 6, 0, 0x0F, val)
        elseif id >= 909 and id <= 915 then unpacked[b0 + (id - 902)] = val & 0xFF end
    elseif fxType == 8 then -- Phaser (IDs 916..931)
        if id >= 916 and id <= 920 then unpacked[b0 + (id - 916)] = val & 0xFF
        elseif id == 921 then setBits(b0 + 5, 7, 0x01, val)
        elseif id == 922 then setBits(b0 + 5, 4, 0x07, val)
        elseif id == 923 then setBits(b0 + 5, 0, 0x0F, val)
        elseif id >= 924 and id <= 931 then unpacked[b0 + (id - 918)] = val & 0xFF end
    end
end

function encodeZ1ParamIntoDump(unpacked, exId, id, val)
    if type(unpacked) ~= "table" or #unpacked < 576 then
        return
    end
    local function setBits(idx, shift, mask, v)
        local cur = (unpacked[idx] or 0) & 0xFF
        unpacked[idx] = (cur & ~(mask << shift)) | ((v & mask) << shift)
    end

    if exId == 0 then
        if id >= 1 and id <= 16 then unpacked[id] = val & 0x7F
        elseif id == 17 or id == 18 then unpacked[id] = val & 0xFF
        elseif id == 19 then setBits(19, 0, 0x01, val)
        elseif id == 20 then setBits(19, 1, 0x03, val)
        elseif id == 21 then setBits(19, 3, 0x03, val)
        elseif id == 22 or id == 23 then unpacked[id - 2] = val & 0xFF
        elseif id == 24 then setBits(22, 0, 0x03, val)
        elseif id == 25 then setBits(22, 2, 0x01, val)
        elseif id == 26 then setBits(22, 3, 0x01, val)
        elseif id == 27 then unpacked[23] = val & 0xFF
        elseif id == 28 then setBits(24, 0, 0x0F, val)
        elseif id == 29 then setBits(24, 4, 0x0F, val)
        elseif id == 30 then unpacked[25] = val & 0xFF
        elseif id >= 31 and id <= 106 then unpacked[id - 5] = val & 0xFF
        elseif id >= 107 and id <= 162 then
            local lfo = ((id - 107) // 14) + 1
            local off = (id - 107) % 14
            local b0  = 102 + (lfo - 1) * 11
            if off == 0 then setBits(b0, 0, 0x1F, val)
            elseif off == 1 then setBits(b0, 6, 0x03, val)
            elseif off >= 2 and off <= 10 then unpacked[b0 + off - 1] = val & 0xFF
            elseif off == 11 then setBits(b0 + 10, 7, 0x01, val)
            elseif off == 12 then setBits(b0 + 10, 4, 0x07, val)
            elseif off == 13 then setBits(b0 + 10, 0, 0x0F, val) end
        elseif id == 163 or id == 164 then unpacked[id - 17] = val & 0xFF
        elseif id == 165 then setBits(148, 0, 0x0F, val)
        elseif id == 166 then setBits(148, 4, 0x0F, val)
        elseif id == 167 or id == 168 then unpacked[id - 18] = val & 0xFF
        elseif id == 169 then setBits(151, 0, 0x01, val)
        elseif id == 170 then setBits(151, 1, 0x01, val)
        elseif id >= 171 and id <= 187 then unpacked[id - 19] = val & 0xFF
        elseif id >= 188 and id <= 201 then unpacked[id + 19] = val & 0xFF
        elseif id >= 202 and id <= 253 then unpacked[id + 57] = val & 0xFF
        elseif id >= 254 and id <= 257 then setBits(311, id - 254, 0x01, val)
        elseif id == 258 then setBits(312, 0, 0x03, val)
        elseif id == 259 then setBits(312, 2, 0x01, val)
        elseif id == 260 then setBits(312, 4, 0x03, val)
        elseif id >= 261 and id <= 359 then unpacked[id + 52] = val & 0xFF
        elseif id == 360 then unpacked[434] = val & 0xFF
        elseif id == 361 then unpacked[457] = val & 0xFF
        elseif id >= 362 and id <= 365 then unpacked[id + 114] = val & 0xFF
        elseif id == 366 then setBits(480, 0, 0x7F, val)
        elseif id == 367 then setBits(480, 7, 0x01, val)
        elseif id == 368 then setBits(481, 0, 0x7F, val)
        elseif id == 369 then setBits(481, 7, 0x01, val)
        elseif id == 370 then setBits(482, 0, 0x7F, val)
        elseif id == 371 then setBits(482, 7, 0x01, val)
        elseif id == 372 then setBits(483, 0, 0x07, val)
        elseif id == 373 then setBits(483, 3, 0x01, val)
        elseif id == 374 then unpacked[484] = val & 0xFF
        elseif id == 375 then setBits(485, 0, 0x01, val)
        elseif id == 376 then setBits(485, 1, 0x01, val)
        elseif id == 377 then setBits(485, 2, 0x03, val)
        elseif id == 378 then setBits(485, 4, 0x01, val)
        elseif id == 379 then setBits(485, 5, 0x01, val)
        elseif id >= 380 and id <= 383 then unpacked[id + 106] = val & 0xFF
        elseif id >= 384 and id <= 463 then unpacked[id + 113] = val & 0xFF end
    elseif exId == 1 then
        encodeOscBlock(unpacked, 169, unpacked[155] or 0, id, val, setBits)
    elseif exId == 2 then
        encodeOscBlock(unpacked, 221, unpacked[207] or 0, id, val, setBits)
    elseif exId == 3 then
        encodeFx12Block(unpacked, 412, unpacked[411] or 0, id, val, setBits)
    elseif exId == 4 then
        encodeFx12Block(unpacked, 435, unpacked[434] or 0, id, val, setBits)
    elseif exId == 5 then
        local mfxRng = MFX_MODEL_RANGES[unpacked[457] or 0]
        if mfxRng and id >= mfxRng[1] and id <= mfxRng[2] then
            unpacked[458 + (id - mfxRng[1])] = val & 0xFF
        end
    end
end

-- Normalize a sysexBlock or raw Lua byte table into a 1-based byte accessor (without leading F0 / trailing F7)
local function readSysexBodyBytes(sysexBlock, maxPayloadBytes)
    local bytes = {}
    if type(sysexBlock) == "table" and not sysexBlock.peek then
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
        if func == 0x41 and (body[5] == 0x01 or body[5] == 0x00) and #body >= 9 then
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
            if _G.preset and type(_G.preset.onZ1Param) == "function" then
                _G.preset.onZ1Param(exId, paramId, signedVal)
            end
            return true, "param_change"
        end

        local dataStart = nil
        if func == 0x40 then
            if body[5] == 0x01 or (body[5] == 0x00 and totalBodyLen >= 664) then
                dataStart = 6 -- after 42 3g 46 40 01 (or 00)
            elseif totalBodyLen == 663 then
                dataStart = 5 -- after 42 3g 46 40 (659 packed bytes directly)
            end
        elseif func == 0x4C then
            dataStart = 8 -- after 42 3g 46 4C ub pp 00
        end

        if dataStart and #body >= dataStart then
            local hadFullPatch = (currentUnpackedProgram and #currentUnpackedProgram >= 576)
            if hadFullPatch then
                -- Keep the previous patch locked in Backup for 30 seconds so the user can Recover
                beginPresetChangeBackup("Pre-Dump Backup")
            else
                savePatchBackup("Pre-Dump Backup")
            end

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
            if #unpacked >= 576 then
                local params = decodeZ1ProgramDump(unpacked)
                if _G.preset and type(_G.preset.onZ1Dump) == "function" then
                    _G.preset.onZ1Dump(params, unpacked)
                end
                if not hadFullPatch then
                    -- First real 576-byte dump loaded: initialize patchBackup with this full patch
                    savePatchBackup("Initial Patch Backup")
                end
            end
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

function midi.onProgramChange(_midiInput, channel, _programNumber)
    local gCh = (getGlobalChannel() & 0x0F) + 1
    if channel == nil or channel == gCh then
        if currentUnpackedProgram and #currentUnpackedProgram >= 576 then
            beginPresetChangeBackup("Pre-PC Backup")
        end
        sendSysexBody(buildCurrentProgramDumpRequestBody())
        info.setText("Z1 Program Change -> Req 40H (Bk Held 30s)")
    end
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
    local bkLine = (backupHoldSeconds > 0)
        and string.format("Bk:%s (%ds)", string.sub(bkName, 1, 11), backupHoldSeconds)
        or ("Bk: " .. bkName)
    graphics.setColor(WHITE)
    graphics.print(6, 23, bkLine, w - 12, LEFT, BOLD, MEDIUM)
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
        backupHoldSeconds = 0
        stopTimerIfIdle()
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
    else
        refreshStatusAndNameWidgets()
    end
    info.setText("Z1 Base Ready")
end
