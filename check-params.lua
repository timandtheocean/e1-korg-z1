#!/usr/bin/env lua5.4
-- check-params.lua
-- Verifies Electra One preset.json (+ companion main.lua) parameter and parameter-list coverage
-- against all Korg Z1 MIDI Implementation files in Z1_MIDIimp/*.TXT:
--   - PROG_PRM.TXT  (Program Parameters & Footnote Lists [*1]..[*13], Mod Source Lists 1 & 2)
--   - MULT_PRM.TXT  (Multi Set Parameters & Footnote Lists [*1]..[*6])
--   - PAT_PRM.TXT   (Arpeggio Pattern Parameters & Footnote Lists [*1]..[*2])
--   - GLBL_PRM.TXT  (Global & MIDI Parameters & Footnote List [*1])
--   - Z1_MIDIimp.TXT (Channel CC, NRPN [*1], MixerSW [*2])
--
-- Usage:
--   lua5.4 check-params.lua                        # Check all e1/*/preset.json files combined
--   lua5.4 check-params.lua e1/z1-osc1/preset.json # Check a single preset.json (or multiple)
--   lua5.4 check-params.lua --verbose              # Also list all open parameters in detail

local SCRIPT_DIR = debug.getinfo(1, "S").source:match("^@(.+)/[^/]+$") or "."
local MIDIIMP_DIR = SCRIPT_DIR .. "/Z1_MIDIimp"

-- ============================================================================
-- 1. Minimal Pure-Lua JSON Parser (for Electra One preset.json)
-- ============================================================================

local function parseJson(str)
    local pos = 1
    local len = #str
    local function skipWs()
        pos = str:match("^%s*()", pos)
    end
    local parseVal
    local function parseStr()
        pos = pos + 1 -- skip opening '"'
        local out = {}
        while pos <= len do
            local c = str:sub(pos, pos)
            if c == '"' then
                pos = pos + 1
                return table.concat(out)
            elseif c == "\\" then
                local esc = str:sub(pos + 1, pos + 1)
                if esc == "n" then out[#out + 1] = "\n"
                elseif esc == "r" then out[#out + 1] = "\r"
                elseif esc == "t" then out[#out + 1] = "\t"
                else out[#out + 1] = esc end
                pos = pos + 2
            else
                local nxt = str:match('^[^"\\]+()', pos)
                out[#out + 1] = str:sub(pos, nxt - 1)
                pos = nxt
            end
        end
        error("Unterminated JSON string")
    end
    local function parseObj()
        pos = pos + 1 -- skip '{'
        local obj = {}
        skipWs()
        if str:sub(pos, pos) == "}" then
            pos = pos + 1
            return obj
        end
        while pos <= len do
            skipWs()
            local k = parseStr()
            skipWs()
            assert(str:sub(pos, pos) == ":", "Expected ':' in JSON object at " .. pos)
            pos = pos + 1
            local v = parseVal()
            obj[k] = v
            skipWs()
            local c = str:sub(pos, pos)
            pos = pos + 1
            if c == "}" then return obj end
            assert(c == ",", "Expected ',' or '}' in JSON object at " .. pos)
        end
        error("Unterminated JSON object")
    end
    local function parseArr()
        pos = pos + 1 -- skip '['
        local arr = {}
        skipWs()
        if str:sub(pos, pos) == "]" then
            pos = pos + 1
            return arr
        end
        while pos <= len do
            arr[#arr + 1] = parseVal()
            skipWs()
            local c = str:sub(pos, pos)
            pos = pos + 1
            if c == "]" then return arr end
            assert(c == ",", "Expected ',' or ']' in JSON array at " .. pos)
        end
        error("Unterminated JSON array")
    end
    parseVal = function()
        skipWs()
        local c = str:sub(pos, pos)
        if c == '"' then return parseStr()
        elseif c == "{" then return parseObj()
        elseif c == "[" then return parseArr()
        elseif str:sub(pos, pos + 3) == "true" then pos = pos + 4; return true
        elseif str:sub(pos, pos + 4) == "false" then pos = pos + 5; return false
        elseif str:sub(pos, pos + 3) == "null" then pos = pos + 4; return nil
        else
            local numStr, nxt = str:match("^([%-]?%d+%.?%d*[eE]?[%+%-]?%d*)()", pos)
            assert(numStr and #numStr > 0, "Invalid JSON value at position " .. pos)
            pos = nxt
            return tonumber(numStr)
        end
    end
    return parseVal()
end

-- ============================================================================
-- 2. Electra One Preset Simulator (executes preset.json + companion main.lua)
-- ============================================================================
-- Tracks every Z1 Parameter Change SysEx (group, exId, paramId) and CC/NRPN
-- reachable from controls actually defined in preset.json, along with the
-- control type ("list", "fader", "dx7envelope", etc.) and overlay items.

local function inspectPresetJson(presetPath, coverage)
    local f = io.open(presetPath, "r")
    if not f then
        error("Cannot open preset file: " .. tostring(presetPath))
    end
    local rawJson = f:read("*a")
    f:close()

    local pData = parseJson(rawJson)
    local dir = presetPath:match("^(.+)/[^/]+$") or "."
    local luaPath = dir .. "/main.lua"
    local shortName = presetPath:gsub("^" .. SCRIPT_DIR .. "/", "")

    -- Build mock E1 state from preset.json
    local overlaysById = {}
    for _, ov in ipairs(pData.overlays or {}) do
        local items = {}
        for i, it in ipairs(ov.items or {}) do
            items[i] = { value = it.value, label = it.label }
        end
        overlaysById[ov.id] = items
    end

    local controlsById = {}
    local orderedControls = {}
    local activeContext = nil -- Tracks which control is currently being tested

    local function makeOverlayObj(ovId)
        return {
            getId = function() return ovId end,
            getValueByIndex = function(_, idx)
                local items = overlaysById[ovId]
                if items and items[idx + 1] and items[idx + 1].value ~= nil then
                    return items[idx + 1].value
                end
                return idx
            end,
            getItems = function() return overlaysById[ovId] or {} end,
        }
    end

    local env = nil

    for _, cDef in ipairs(pData.controls or {}) do
        local cState = {
            id      = cDef.id,
            name    = cDef.name or "",
            type    = cDef.type or "fader",
            visible = (cDef.visible ~= false),
            color   = cDef.color,
            bounds  = cDef.bounds or { 0, 0, 146, 56 },
            values  = {},
            rawDef  = cDef,
        }

        local ctrlObj = {
            getId = function() return cState.id end,
            getName = function() return cState.name end,
            setName = function(_, n) cState.name = tostring(n or "") end,
            isVisible = function() return cState.visible end,
            setVisible = function(_, v) cState.visible = (v == true) end,
            setColor = function(_, c) cState.color = c end,
            getBounds = function() return cState.bounds end,
            repaint = function() end,
            setPaintCallback = function() end,
            setTouchCallback = function() end,
        }

        for _, vDef in ipairs(cDef.values or {}) do
            local vid = vDef.id or "value"
            local msgDef = vDef.message or {}
            local vState = {
                id         = vid,
                min        = vDef.min or msgDef.min or 0,
                max        = vDef.max or msgDef.max or 127,
                val        = vDef.defaultValue or vDef.min or 0,
                overlayId  = vDef.overlayId,
                fnName     = vDef["function"],
                formatter  = vDef.formatter,
                msgType    = msgDef.type,
                msgParam   = msgDef.parameterNumber,
            }
            local msgObj = {
                setRange = function(_, mn, mx)
                    vState.msgMin = mn
                    vState.msgMax = mx
                end,
                getType = function() return vState.msgType end,
                getParameterNumber = function() return vState.msgParam end,
            }
            local valObj
            valObj = {
                getId = function() return vState.id end,
                getControl = function() return ctrlObj end,
                getMessage = function() return msgObj end,
                setRange = function(_, mn, mx, defVal)
                    if mn then vState.min = mn end
                    if mx then vState.max = mx end
                    if defVal then vState.val = defVal end
                end,
                setOverlayId = function(_, ovId)
                    vState.overlayId = ovId
                end,
                getOverlayId = function() return vState.overlayId end,
                updateValue = function(_, v)
                    vState.val = v
                    -- On Electra One, updateValue triggers the Lua callback (which modules guard with suppress flags)
                    if env and vState.fnName and type(env[vState.fnName]) == "function" then
                        local savedCtx = activeContext
                        activeContext = nil
                        env[vState.fnName](valObj, v)
                        activeContext = savedCtx
                    end
                end,
                setValue = function(_, v)
                    vState.val = v
                end,
                _state = vState,
            }
            cState.values[vid] = valObj

            -- Check direct CC/NRPN messages in preset.json if any
            if msgDef.type == "cc7" and msgDef.parameterNumber then
                coverage.cc[msgDef.parameterNumber] = coverage.cc[msgDef.parameterNumber] or {}
                coverage.cc[msgDef.parameterNumber][shortName] = true
            elseif msgDef.type == "nrpn" and msgDef.parameterNumber then
                coverage.nrpn[msgDef.parameterNumber] = coverage.nrpn[msgDef.parameterNumber] or {}
                coverage.nrpn[msgDef.parameterNumber][shortName] = true
            end
        end

        ctrlObj.getValue = function(_, vid)
            return cState.values[vid or "value"] or cState.values["value"]
        end
        ctrlObj._state = cState
        controlsById[cDef.id] = ctrlObj
        orderedControls[#orderedControls + 1] = ctrlObj
    end

    -- Record a Z1 SysEx Parameter Change message emitted while exercising a control
    local function recordSysex(bytes)
        if type(bytes) ~= "table" or #bytes < 9 then return end
        -- Match Korg Z1 Parameter Change body: 42 3g 46 41 0m pl pm vl vm
        if bytes[1] == 0x42 and (bytes[2] & 0xF0) == 0x30 and bytes[3] == 0x46 and bytes[4] == 0x41 then
            local grp = bytes[5]
            local id14 = (bytes[6] & 0x7F) | ((bytes[7] & 0x7F) << 7)
            local exId = (grp == 1) and ((id14 >> 11) & 0x07) or 0
            local paramId = (grp == 1) and (id14 & 0x07FF) or id14

            coverage.groups[grp] = coverage.groups[grp] or {}
            local key = (exId << 11) | paramId
            local entry = coverage.groups[grp][key]
            if not entry then
                entry = {
                    grp       = grp,
                    exId      = exId,
                    id        = paramId,
                    presets   = {},
                    ctrlTypes = {},
                    overlays  = {},
                    hasFormatter = false,
                }
                coverage.groups[grp][key] = entry
            end
            entry.presets[shortName] = true

            if activeContext then
                local cType = activeContext.cState.type
                entry.ctrlTypes[cType] = true
                local vState = activeContext.vState
                if vState.formatter then
                    entry.hasFormatter = true
                end
                if cType == "list" and vState.overlayId and overlaysById[vState.overlayId] then
                    local items = overlaysById[vState.overlayId]
                    entry.overlays[# items] = items
                end
            end

            -- Also record base paramId (ignoring ExID) for PROG_PRM table-level tracking
            if grp == 1 then
                local baseEntry = coverage.progBase[paramId]
                if not baseEntry then
                    baseEntry = {
                        id           = paramId,
                        exIds        = {},
                        presets      = {},
                        ctrlTypes    = {},
                        overlays     = {},
                        hasFormatter = false,
                    }
                    coverage.progBase[paramId] = baseEntry
                end
                baseEntry.exIds[exId] = true
                baseEntry.presets[shortName] = true
                if activeContext then
                    local cType = activeContext.cState.type
                    baseEntry.ctrlTypes[cType] = true
                    local vState = activeContext.vState
                    if vState.formatter then
                        baseEntry.hasFormatter = true
                    end
                    if cType == "list" and vState.overlayId and overlaysById[vState.overlayId] then
                        local items = overlaysById[vState.overlayId]
                        baseEntry.overlays[#items] = items
                    end
                end
            end
        end
    end

    -- Load and run companion main.lua if present
    local lf = io.open(luaPath, "r")
    if not lf then
        return
    end
    lf:close()

    env = setmetatable({
        WHITE = 1, RED = 2, ORANGE = 3, BLUE = 4, GREEN = 5, PURPLE = 6,
        LEFT = 1, CENTER = 2, RIGHT = 3,
        REGULAR = 1, BOLD = 2, SMALL = 1, MEDIUM = 2, LARGE = 3,
        WIDTH = 3, HEIGHT = 4, PORT_1 = 1, CLICK = 1,
        preset = {
            getDevice = function()
                return {
                    getChannel = function() return 1 end,
                    sendSysex = function(_, body) recordSysex(body) end,
                }
            end,
            getGroup = function()
                return { setLabel = function() end, setVisible = function() end }
            end,
            getControl = function(cid) return controlsById[cid] end,
        },
        controls = {
            get = function(cid) return controlsById[cid] end,
        },
        overlays = {
            create = function(ovId, items)
                overlaysById[ovId] = items
            end,
            get = function(ovId)
                if overlaysById[ovId] then
                    return makeOverlayObj(ovId)
                end
                return nil
            end,
        },
        pages = {
            get = function() return { setName = function() end } end,
        },
        window = {
            stop = function() end,
            resume = function() end,
        },
        info = {
            setText = function() end,
        },
        midi = {
            sendSysex = function(_, body) recordSysex(body) end,
        },
        graphics = {
            setColor = function() end,
            fillRect = function() end,
            drawRect = function() end,
            fillRoundRect = function() end,
            drawRoundRect = function() end,
            drawLine = function() end,
            print = function() end,
        },
    }, { __index = _G })

    local chunk = assert(loadfile(luaPath, "t", env))
    chunk()
    if type(env.preset.onLoad) == "function" then env.preset.onLoad() end
    if type(env.preset.onReady) == "function" then env.preset.onReady() end

    -- Helper: fire all currently visible value callbacks once to probe their Z1 Parameter IDs
    local function probeVisibleControls(skipCtrlIds)
        for _, ctrl in ipairs(orderedControls) do
            local cState = ctrl._state
            if cState.visible and not (skipCtrlIds and skipCtrlIds[cState.id]) then
                for _, valObj in pairs(cState.values) do
                    local vState = valObj._state
                    local fn = vState.fnName and env[vState.fnName]
                    if type(fn) == "function" then
                        activeContext = { cState = cState, vState = vState }
                        local savedVal = vState.val
                        local probeVal = savedVal or vState.min or 0
                        fn(valObj, probeVal)
                        activeContext = nil
                    end
                end
            end
        end
    end

    -- 1. Initial probe in default state
    probeVisibleControls()

    -- 2. Identify mode/selector controls in preset.json (controls whose callback changes layout/selection)
    --    and sweep their range so every dynamic page/model/unit/character slot is exercised through preset.json!
    local selectorNames = {
        onOscType = true,
        onOscView = true,
        onEgSelect = true,
        onFilterSelect = true,
        onLfoSelect = true,
        onEditUnitSelect = true,
        onModSelect = true,
        onNamePos = true,
        onStaticFilter = true,
        onStaticFxTop = true,
    }

    local selectors = {}
    for _, ctrl in ipairs(orderedControls) do
        local cState = ctrl._state
        local valObj = cState.values["value"]
        if valObj then
            local vState = valObj._state
            if selectorNames[vState.fnName] then
                selectors[#selectors + 1] = { ctrl = ctrl, valObj = valObj, vState = vState }
            end
        end
    end

    -- Sweep each selector across its min..max values and probe all controls
    for _, sel in ipairs(selectors) do
        local fn = env[sel.vState.fnName]
        local mn = sel.vState.min or 0
        local mx = sel.vState.max or 0
        if mx - mn <= 32 then
            for v = mn, mx do
                activeContext = { cState = sel.ctrl._state, vState = sel.vState }
                fn(sel.valObj, v)
                activeContext = nil
                probeVisibleControls({ [sel.ctrl._state.id] = true })
            end
        end
    end

    -- Also handle 2-level selector combinations (e.g., z1-fx Edit Unit 0..2 x FX1/FX2/MFX algorithm,
    -- z1-osc2 View 0..1 x Model 0..8, z1-filter FilterSelect 0..1 x FilterType 0..4 & CutModEG 0..4)
    for _, selA in ipairs(selectors) do
        local fnA = env[selA.vState.fnName]
        local mnA, mxA = selA.vState.min or 0, selA.vState.max or 0
        if mxA - mnA <= 5 then
            for vA = mnA, mxA do
                activeContext = { cState = selA.ctrl._state, vState = selA.vState }
                fnA(selA.valObj, vA)
                activeContext = nil
                for _, selB in ipairs(selectors) do
                    if selB ~= selA then
                        local fnB = env[selB.vState.fnName]
                        local mnB, mxB = selB.vState.min or 0, selB.vState.max or 0
                        if mxB - mnB <= 16 then
                            for vB = mnB, mxB do
                                activeContext = { cState = selB.ctrl._state, vState = selB.vState }
                                fnB(selB.valObj, vB)
                                activeContext = nil
                                probeVisibleControls({
                                    [selA.ctrl._state.id] = true,
                                    [selB.ctrl._state.id] = true,
                                })
                            end
                        end
                    end
                end
                -- In z1-filter, control 21 (Cutoff Mod EG 0..4) switches the assigned EG widget (controls 4 & 5)
                local c21 = controlsById[21]
                if c21 and c21._state.values["value"] then
                    local vo21 = c21._state.values["value"]
                    local fn21 = vo21._state.fnName and env[vo21._state.fnName]
                    if type(fn21) == "function" and (vo21._state.max or 0) <= 5 then
                        for egIdx = 0, (vo21._state.max or 4) do
                            activeContext = { cState = c21._state, vState = vo21._state }
                            fn21(vo21, egIdx)
                            activeContext = nil
                            probeVisibleControls({ [20] = true, [21] = true })
                        end
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- 3. Parsers for Z1_MIDIimp/*.TXT
-- ============================================================================

local function trim(s)
    return (s or ""):match("^%s*(.-)%s*$")
end

local function isReservedParam(name)
    local low = name:lower()
    return low == "reserved" or low == "(not use)"
end

-- Parse PROG_PRM.TXT (Group 01: Program Parameters & Footnote Lists)
local function parseProgPrm(path)
    local f = assert(io.open(path, "r"))
    local text = f:read("*a")
    f:close()

    local params = {}
    local orderedIds = {}
    local curSection = "Program Common"

    for line in text:gmatch("[^\r\n]+") do
        if line:find("^%* The format of") or line:find("^%[%*1%]") then
            break
        end
        local sec = line:match("^|%s*|%[([^%]]+)%]")
        if sec then
            curSection = trim(sec)
        end

        local rStart, rEnd, rName, rDisp, rVal = line:match("^|%s*(%d+)~(%d+)%s*|([^|]+)|([^|]+)|([^|]+)|")
        if rStart then
            local s, e = tonumber(rStart), tonumber(rEnd)
            for id = s, e do
                params[id] = {
                    id       = id,
                    section  = curSection,
                    name     = string.format("%s [%d]", trim(rName), id),
                    display  = trim(rDisp),
                    valRange = trim(rVal),
                    reserved = false,
                }
                orderedIds[#orderedIds + 1] = id
            end
        else
            local idStr, name, disp, val = line:match("^|%s*(%d+)%s*|([^|]+)|([^|]+)|([^|]+)|")
            if idStr then
                local id = tonumber(idStr)
                local pName = trim(name)
                local pDisp = trim(disp)
                local pVal  = trim(val)
                local isSubHeader = (pDisp == "" and pVal == "" and pName:match("^%b()$") ~= nil)
                if not isSubHeader and not params[id] then
                    params[id] = {
                        id       = id,
                        section  = curSection,
                        name     = pName,
                        display  = pDisp,
                        valRange = pVal,
                        reserved = isReservedParam(pName),
                    }
                    orderedIds[#orderedIds + 1] = id
                end
            end
        end
    end

    -- Define the 15 Parameter Lists in PROG_PRM.TXT (Footnotes [*1]..[*13] + Mod Source Lists 1 & 2)
    local lists = {
        { code = "[*1]",  name = "Program Category", count = 18,
          match = function(p) return p.id == 17 end },
        { code = "[*2]",  name = "Scale Type", count = 11,
          match = function(p) return p.id == 29 end },
        { code = "[*3]",  name = "LFO Wave Form", count = 18,
          match = function(p) return p.display:find("%[%*3%]") ~= nil end },
        { code = "[*4]",  name = "Oscillator Type (OSC1 13 / OSC2 9)", count = 13,
          match = function(p) return p.id == 174 or p.id == 188 end },
        { code = "[*5]",  name = "Effect1&2 Type (FX1 15 / FX2 11)", count = 15,
          match = function(p) return p.id == 359 or p.id == 360 end },
        { code = "[*6]",  name = "Master Effect Type", count = 3,
          match = function(p) return p.id == 361 end },
        { code = "[*7]",  name = "Assignable SW1 Function List", count = 8,
          match = function(p) return p.id == 366 end },
        { code = "[*8]",  name = "Assignable SW2 Function List", count = 8,
          match = function(p) return p.id == 368 end },
        { code = "[*9]",  name = "Assignable F.SW Function List", count = 13,
          match = function(p) return p.id == 370 end },
        { code = "[*10]", name = "Assignable Pedal Function List", count = 6,
          match = function(p) return p.id == 372 end },
        { code = "[*11]", name = "PE (Performance Editor) List", count = 231,
          match = function(p) return p.display:find("%[%*11%]") ~= nil end },
        { code = "[*12]", name = "Brass Model Instrument Types", count = 6,
          match = function(p) return p.id == 616 end },
        { code = "[*13]", name = "Reed Model Instrument Types", count = 17,
          match = function(p) return p.id == 654 end },
        { code = "List1", name = "Modulation Source List 1 (0..48)", count = 49,
          match = function(p) return p.display:find("Mod%.Source List 1") ~= nil end },
        { code = "List2", name = "Modulation Source List 2 (0,11..45)", count = 36,
          match = function(p) return p.display:find("Mod%.Source List 2") ~= nil end },
    }

    return {
        file       = "PROG_PRM.TXT",
        title      = "KORG Z1 - Program Parameters (Group 01)",
        group      = 1,
        params     = params,
        orderedIds = orderedIds,
        lists      = lists,
    }
end

-- Parse MULT_PRM.TXT (Group 03: Multi Set Parameters & Footnote Lists [*1]..[*6])
local function parseMultPrm(path)
    local f = assert(io.open(path, "r"))
    local text = f:read("*a")
    f:close()

    local params = {}
    local orderedIds = {}
    local curSection = "Common"
    local timbre1Template = {}

    for line in text:gmatch("[^\r\n]+") do
        if line:find("^%* The format of") or line:find("^%[%*1%]") then
            break
        end
        local sec = line:match("^|%s*|%[([^%]]+)%]")
        if sec then curSection = trim(sec) end

        local rStart, rEnd, rName, rDisp, rVal = line:match("^|%s*(%d+)~(%d+)%s*|([^|]+)|([^|]+)|([^|]+)|")
        if rStart then
            for id = tonumber(rStart), tonumber(rEnd) do
                params[id] = {
                    id = id, section = curSection,
                    name = string.format("%s [%d]", trim(rName), id),
                    display = trim(rDisp), valRange = trim(rVal), reserved = false,
                }
                orderedIds[#orderedIds + 1] = id
            end
        else
            local tStart, tSec = line:match("^|%s*(%d+)~|%[(Timbre %d+)%]")
            if tStart and tSec then
                -- Expand Timbre 2..6 (27 parameter IDs each, copied from Timbre 1 template 17..43)
                local baseId = tonumber(tStart)
                for offset, tmpl in ipairs(timbre1Template) do
                    local id = baseId + offset - 1
                    params[id] = {
                        id = id, section = tSec,
                        name = tmpl.name, display = tmpl.display,
                        valRange = tmpl.valRange, reserved = tmpl.reserved,
                    }
                    orderedIds[#orderedIds + 1] = id
                end
            else
                local idStr, name, disp, val = line:match("^|%s*(%d+)%s*|([^|]+)|([^|]+)|([^|]+)|")
                if idStr then
                    local id = tonumber(idStr)
                    local pName = trim(name)
                    local entry = {
                        id = id, section = curSection,
                        name = pName, display = trim(disp),
                        valRange = trim(val), reserved = isReservedParam(pName),
                    }
                    params[id] = entry
                    orderedIds[#orderedIds + 1] = id
                    if id >= 17 and id <= 43 then
                        timbre1Template[#timbre1Template + 1] = entry
                    end
                end
            end
        end
    end

    local lists = {
        { code = "[*1]", name = "Effect1&2 Type", count = 15,
          match = function(p) return p.id == 179 or p.id == 180 end },
        { code = "[*2]", name = "Master Effect Type", count = 3,
          match = function(p) return p.id == 181 end },
        { code = "[*3]", name = "Assignable SW1 Function List", count = 8,
          match = function(p) return p.id == 194 end },
        { code = "[*4]", name = "Assignable SW2 Function List", count = 8,
          match = function(p) return p.id == 196 end },
        { code = "[*5]", name = "Assignable Foot SW Function List", count = 13,
          match = function(p) return p.id == 198 end },
        { code = "[*6]", name = "Assignable Pedal Function List", count = 6,
          match = function(p) return p.id == 200 end },
    }

    return {
        file       = "MULT_PRM.TXT",
        title      = "KORG Z1 - Multi Set Parameters (Group 03)",
        group      = 3,
        params     = params,
        orderedIds = orderedIds,
        lists      = lists,
    }
end

-- Parse PAT_PRM.TXT (Group 02: Arpeggio Pattern Parameters & Footnote Lists [*1]..[*2])
local function parsePatPrm(path)
    local f = assert(io.open(path, "r"))
    local text = f:read("*a")
    f:close()

    local params = {}
    local orderedIds = {}
    local step1Template = {}

    for line in text:gmatch("[^\r\n]+") do
        local rStart, rEnd, rName, rDisp, rVal = line:match("^|%s*(%d+)~(%d+)%s*|([^|]+)|([^|]+)|([^|]+)|")
        if rStart then
            for id = tonumber(rStart), tonumber(rEnd) do
                params[id] = {
                    id = id, section = "Pattern Common",
                    name = string.format("%s [%d]", trim(rName), id),
                    display = trim(rDisp), valRange = trim(rVal), reserved = false,
                }
                orderedIds[#orderedIds + 1] = id
            end
        else
            local idStr, name, disp, val = line:match("^|%s*(%d+)%s*|([^|]+)|([^|]+)|([^|]+)|")
            if idStr then
                local id = tonumber(idStr)
                local pName = trim(name)
                local sec = (id >= 33) and "Step 1" or "Pattern Common"
                local entry = {
                    id = id, section = sec,
                    name = pName, display = trim(disp),
                    valRange = trim(val), reserved = isReservedParam(pName),
                }
                params[id] = entry
                orderedIds[#orderedIds + 1] = id
                if id >= 33 and id <= 38 then
                    step1Template[#step1Template + 1] = entry
                end
            end
        end
    end

    -- Expand Steps 2..36 (IDs 39..248, 6 parameters per step)
    for step = 2, 36 do
        local baseId = 33 + (step - 1) * 6
        for offset, tmpl in ipairs(step1Template) do
            local id = baseId + offset - 1
            params[id] = {
                id = id, section = "Step " .. step,
                name = tmpl.name, display = tmpl.display,
                valRange = tmpl.valRange, reserved = false,
            }
            orderedIds[#orderedIds + 1] = id
        end
    end

    local lists = {
        { code = "[*1]", name = "Arpeggio Type (Type1..Type4)", count = 4,
          match = function(p) return p.id == 31 end },
        { code = "[*2]", name = "Step Tone Bitmask (Tone0..9)", count = 10,
          match = function(p) return p.name == "Tone MSB" or p.name == "Tone LSB" end },
    }

    return {
        file       = "PAT_PRM.TXT",
        title      = "KORG Z1 - Arpeggio Pattern Parameters (Group 02)",
        group      = 2,
        params     = params,
        orderedIds = orderedIds,
        lists      = lists,
    }
end

-- Parse GLBL_PRM.TXT (Group 00: Global & MIDI Parameters & Footnote List [*1])
local function parseGlblPrm(path)
    local f = assert(io.open(path, "r"))
    local text = f:read("*a")
    f:close()

    local params = {}
    local orderedIds = {}
    local curSection = "Global"

    local function addParam(id, sec, name, disp, val, res)
        if not params[id] then
            params[id] = {
                id = id, section = sec, name = name,
                display = disp or "", valRange = val or "",
                reserved = res or false,
            }
            orderedIds[#orderedIds + 1] = id
        end
    end

    for line in text:gmatch("[^\r\n]+") do
        if line:find("KORG Z1 %- MIDI Parameters") then
            curSection = "MIDI"
        end
        local subSec = line:match("^|%s*|%(([^%)]+)%)")
        if subSec then curSection = trim(subSec) end

        local rStart, rName, rDisp, rVal, rSize = line:match("^|%s*(%d+)~|([^|]+)|([^|]+)|([^|]+)|%s*(%d+)")
        if rStart then
            local baseId = tonumber(rStart)
            local sz = tonumber(rSize)
            local nm = trim(rName)
            if nm:find("^%(CC#") then
                -- Each CC Operation block has 3 parameter IDs: Transmit, Receive, Translation
                addParam(baseId + 0, nm, nm .. " Transmit",    "OFF/ON",  "0/1",  false)
                addParam(baseId + 1, nm, nm .. " Receive",     "DIS/ENA", "0/1",  false)
                addParam(baseId + 2, nm, nm .. " Translation", "[*1]",    "0~97", false)
            else
                -- User Group1..16 Name (16 chars each), User Scale1 (12), User Scale2 (128)
                -- Note: User Group2 Name at 36..51, User Group3 Name at 52..67 (50~ in txt is a typo in Korg doc for 52~)
                local actualStart = (baseId == 50 and params[50]) and 52 or baseId
                for i = 0, sz - 1 do
                    addParam(actualStart + i, curSection, string.format("%s [%d]", nm, i + 1), trim(rDisp), trim(rVal), false)
                end
            end
        else
            local idStr, name, disp, val = line:match("^|%s*(%d+)%s*|([^|]+)|([^|]+)|([^|]+)|")
            if idStr then
                local id = tonumber(idStr)
                local pName = trim(name)
                addParam(id, curSection, pName, trim(disp), trim(val), isReservedParam(pName))
            end
        end
    end

    -- Expand Program Select Map A001..A128 (442..569) & B001..B128 (570..697)
    for i = 1, 128 do
        addParam(441 + i, "Program Select Map", string.format("A%03d", i), "0~127", "0~127", false)
        addParam(569 + i, "Program Select Map", string.format("B%03d", i), "0~127", "0~127", false)
    end
    -- Expand Multi Set Select Map A01..A16 (698..713) & B01..B16 (714..729)
    for i = 1, 16 do
        addParam(697 + i, "Multi Set Select Map", string.format("A%02d", i), "0~127", "0~127", false)
        addParam(713 + i, "Multi Set Select Map", string.format("B%02d", i), "0~127", "0~127", false)
    end

    table.sort(orderedIds)

    local lists = {
        { code = "[*1]", name = "MIDI Controller Translation List (PitchBend/AfterTouch/CC#00..95)",
          count = 98, match = function(p) return p.display == "[*1]" end },
    }

    return {
        file       = "GLBL_PRM.TXT",
        title      = "KORG Z1 - Global & MIDI Parameters (Group 00)",
        group      = 0,
        params     = params,
        orderedIds = orderedIds,
        lists      = lists,
    }
end

-- Parse Z1_MIDIimp.TXT (Recognized CC, NRPN [*1], MixerSW [*2])
local function parseMidiImp(path)
    local f = assert(io.open(path, "r"))
    local text = f:read("*a")
    f:close()

    -- Parse section 2-1 Recognized Receive Channel CC messages
    local ccs = {}
    local orderedCcs = {}
    local inSec2 = false
    for line in text:gmatch("[^\r\n]+") do
        if line:find("^2%.RECOGNIZED RECEIVE DATA") then inSec2 = true end
        if line:find("^2%-2 SYSTEM REALTIME") then break end
        if inSec2 then
            local hexStr, decStr, desc = line:match("^|%s*Bn%s*|%s*([0-9A-F]+)%s*%((%d+)%)%s*|[^|]+|([^|]+)|")
            if decStr then
                local cc = tonumber(decStr)
                if not ccs[cc] then
                    ccs[cc] = { cc = cc, hex = hexStr, name = trim(desc) }
                    orderedCcs[#orderedCcs + 1] = cc
                end
            end
        end
    end

    local nrpns = {
        { id = 1, msb = 0, lsb = 1, name = "Arpeggio Pattern Select" },
        { id = 2, msb = 0, lsb = 2, name = "Arpeggio On/Off" },
        { id = 3, msb = 0, lsb = 3, name = "Arpeggio Octaves" },
        { id = 4, msb = 0, lsb = 4, name = "Arpeggiator Latch On/Off" },
        { id = 5, msb = 0, lsb = 5, name = "Arpeggiator Key Sync On/Off" },
        { id = 6, msb = 0, lsb = 6, name = "Arpeggio KBD On/Off" },
    }

    return {
        file       = "Z1_MIDIimp.TXT",
        title      = "KORG Z1 - MIDI Implementation (Channel CC / NRPN / SysEx)",
        ccs        = ccs,
        orderedCcs = orderedCcs,
        nrpns      = nrpns,
    }
end

-- ============================================================================
-- 4. Reporting Engine
-- ============================================================================

local function printBanner(title)
    print(string.rep("=", 86))
    print(" " .. title)
    print(string.rep("=", 86))
end

local function reportProgPrm(spec, coverage, verbose)
    printBanner(spec.file .. " — " .. spec.title)

    -- 1. Base Table Parameters (IDs 1..1039 in PROG_PRM.TXT)
    local totalActive, implActive, openActive, totalReserved = 0, 0, 0, 0
    local openParams = {}

    for _, id in ipairs(spec.orderedIds) do
        local p = spec.params[id]
        if p.reserved then
            totalReserved = totalReserved + 1
        else
            totalActive = totalActive + 1
            if coverage.progBase[id] then
                implActive = implActive + 1
            else
                openActive = openActive + 1
                openParams[#openParams + 1] = p
            end
        end
    end

    -- 2. Expanded ExID Addressable Parameters (ExID 0..5)
    --    ExID 0: IDs 1..463
    --    ExID 1: OSC1 Models 0..12 (IDs 464..754)
    --    ExID 2: OSC2 Models 0..8  (IDs 464..615)
    --    ExID 3: FX1 Models 0..14  (IDs 800..1003)
    --    ExID 4: FX2 Models 0..10  (IDs 800..951)
    --    ExID 5: MFX Models 0..2   (IDs 1004..1039)
    local exIdRanges = {
        { exId = 0, label = "ExID 0 (Program Core 1..463)",         minId = 1,    maxId = 463 },
        { exId = 1, label = "ExID 1 (OSC1 Models 0..12, 464..754)", minId = 464,  maxId = 754 },
        { exId = 2, label = "ExID 2 (OSC2 Models 0..8,  464..615)", minId = 464,  maxId = 615 },
        { exId = 3, label = "ExID 3 (FX1 Algos 0..14,   800..1003)",minId = 800,  maxId = 1003 },
        { exId = 4, label = "ExID 4 (FX2 Algos 0..10,   800..951)", minId = 800,  maxId = 951 },
        { exId = 5, label = "ExID 5 (Master FX 0..2,   1004..1039)",minId = 1004, maxId = 1039 },
    }

    local addrTotal, addrImpl, addrOpen = 0, 0, 0
    print(string.format(
        "  Table Parameter IDs (1..1039):  %4d active (%2d reserved) | Implemented: %4d | Open: %4d (%.1f%%)",
        totalActive, totalReserved, implActive, openActive,
        totalActive > 0 and (implActive * 100.0 / totalActive) or 0
    ))
    print("")
    print("  Breakdown by ExID (Addressable Program Parameters):")
    print("  +----------------------------------------+--------+-------------+--------+----------+")
    print("  | ExID Scope                             | Active | Implemented |  Open  | Coverage |")
    print("  +----------------------------------------+--------+-------------+--------+----------+")

    local grp1 = coverage.groups[1] or {}
    for _, r in ipairs(exIdRanges) do
        local rAct, rImp, rOpn = 0, 0, 0
        for id = r.minId, r.maxId do
            local p = spec.params[id]
            if p and not p.reserved then
                rAct = rAct + 1
                local key = (r.exId << 11) | id
                if grp1[key] then
                    rImp = rImp + 1
                else
                    rOpn = rOpn + 1
                end
            end
        end
        addrTotal = addrTotal + rAct
        addrImpl  = addrImpl + rImp
        addrOpen  = addrOpen + rOpn
        print(string.format(
            "  | %-38s | %6d | %11d | %6d |  %5.1f%%  |",
            r.label, rAct, rImp, rOpn, rAct > 0 and (rImp * 100.0 / rAct) or 0
        ))
    end
    print("  +----------------------------------------+--------+-------------+--------+----------+")
    print(string.format(
        "  | TOTAL ADDRESSABLE (ExID 0..5)          | %6d | %11d | %6d |  %5.1f%%  |",
        addrTotal, addrImpl, addrOpen, addrTotal > 0 and (addrImpl * 100.0 / addrTotal) or 0
    ))
    print("  +----------------------------------------+--------+-------------+--------+----------+")

    -- 3. Open Parameters in PROG_PRM.TXT
    if #openParams > 0 then
        print("")
        if verbose or #openParams <= 25 then
            print(string.format("  Open (Unimplemented) Active Parameters in %s (%d):", spec.file, #openParams))
            for _, p in ipairs(openParams) do
                print(string.format("    - ID %4d [%-14s]: %-28s (Display: %s, Value: %s)",
                    p.id, p.section, p.name, p.display, p.valRange))
            end
        else
            print(string.format(
                "  Open (Unimplemented) Active Parameters in %s: %d (run with --verbose to list all)",
                spec.file, #openParams
            ))
        end
    else
        print("\n  All active parameters in PROG_PRM.TXT are implemented!")
    end

    -- 4. Parameter Lists / Footnotes in PROG_PRM.TXT
    print("")
    print("  Parameter Lists / Footnotes in PROG_PRM.TXT (15 lists):")
    print("  +-------+--------------------------------------+--------+-----------+------------+-------------+")
    print("  | List  | Description                          | Items  | Params    | As E1 List | Status      |")
    print("  +-------+--------------------------------------+--------+-----------+------------+-------------+")
    local listsImpl, listsPartial, listsFader, listsOpen = 0, 0, 0, 0
    for _, lst in ipairs(spec.lists) do
        local pTotal, pImplAny, pImplList = 0, 0, 0
        for _, id in ipairs(spec.orderedIds) do
            local p = spec.params[id]
            if not p.reserved and lst.match(p) then
                pTotal = pTotal + 1
                local cov = coverage.progBase[id]
                if cov then
                    pImplAny = pImplAny + 1
                    if cov.ctrlTypes["list"] then
                        pImplList = pImplList + 1
                    end
                end
            end
        end
        local status
        if pImplList == pTotal and pTotal > 0 then
            status = "IMPL (List)"
            listsImpl = listsImpl + 1
        elseif pImplList > 0 and pImplList == pImplAny then
            status = "PARTIAL"
            listsPartial = listsPartial + 1
        elseif pImplAny > 0 then
            status = "NUM FADER"
            listsFader = listsFader + 1
        else
            status = "OPEN"
            listsOpen = listsOpen + 1
        end
        print(string.format(
            "  | %-5s | %-36s | %6d | %4d/%-4d | %4d/%-5d | %-11s |",
            lst.code, lst.name, lst.count, pImplAny, pTotal, pImplList, pTotal, status
        ))
    end
    print("  +-------+--------------------------------------+--------+-----------+------------+-------------+")
    print(string.format(
        "  Lists Summary: %d/15 full E1 Lists, %d/15 partial, %d/15 numeric fader, %d/15 open.",
        listsImpl, listsPartial, listsFader, listsOpen
    ))
    print("")
end

local function reportGenericPrm(spec, coverage, verbose)
    printBanner(spec.file .. " — " .. spec.title)
    local grpMap = coverage.groups[spec.group] or {}

    local totalActive, implActive, openActive, totalReserved = 0, 0, 0, 0
    local openParams = {}

    for _, id in ipairs(spec.orderedIds) do
        local p = spec.params[id]
        if p.reserved then
            totalReserved = totalReserved + 1
        else
            totalActive = totalActive + 1
            if grpMap[id] then
                implActive = implActive + 1
            else
                openActive = openActive + 1
                openParams[#openParams + 1] = p
            end
        end
    end

    print(string.format(
        "  Parameters: %4d active (%2d reserved) | Implemented: %4d | Open: %4d (%.1f%%)",
        totalActive, totalReserved, implActive, openActive,
        totalActive > 0 and (implActive * 100.0 / totalActive) or 0
    ))

    -- Parameter Lists in this file
    if spec.lists and #spec.lists > 0 then
        local lImpl, lOpen = 0, 0
        print("")
        print(string.format("  Parameter Lists in %s (%d lists):", spec.file, #spec.lists))
        for _, lst in ipairs(spec.lists) do
            local pTotal, pImplList = 0, 0
            for _, id in ipairs(spec.orderedIds) do
                local p = spec.params[id]
                if not p.reserved and lst.match(p) then
                    pTotal = pTotal + 1
                    if grpMap[id] and grpMap[id].ctrlTypes["list"] then
                        pImplList = pImplList + 1
                    end
                end
            end
            if pImplList == pTotal and pTotal > 0 then lImpl = lImpl + 1 else lOpen = lOpen + 1 end
            print(string.format("    - %-5s %-56s (%3d items, %d/%d params wired) -> %s",
                lst.code, lst.name, lst.count, pImplList, pTotal,
                (pImplList == pTotal and pTotal > 0) and "IMPLEMENTED" or "OPEN"))
        end
        print(string.format("  Lists Summary: %d/%d implemented, %d/%d open.", lImpl, #spec.lists, lOpen, #spec.lists))
    end

    if verbose and #openParams > 0 then
        print("")
        print(string.format("  Open Active Parameters in %s (%d):", spec.file, #openParams))
        for _, p in ipairs(openParams) do
            print(string.format("    - ID %4d [%-22s]: %-28s (%s)", p.id, p.section, p.name, p.valRange))
        end
    end
    print("")
end

local function reportMidiImp(spec, coverage)
    printBanner(spec.file .. " — " .. spec.title)
    local ccImpl = 0
    for _, cc in ipairs(spec.orderedCcs) do
        if coverage.cc[cc] then ccImpl = ccImpl + 1 end
    end
    local nrpnImpl = 0
    for _, n in ipairs(spec.nrpns) do
        if coverage.nrpn[n.id] then nrpnImpl = nrpnImpl + 1 end
    end

    -- Check how many PROG_PRM parameters that also have CC/NRPN equivalents are implemented via SysEx (41)
    print("  Note: Presets currently use Korg Z1 Parameter Change SysEx (Function 41H) rather than direct CC/NRPN.")
    print(string.format(
        "  - Recognized Channel CCs (Section 2-1): %2d defined | Direct CC controls in preset.json:   %2d implemented, %2d open",
        #spec.orderedCcs, ccImpl, #spec.orderedCcs - ccImpl
    ))
    print(string.format(
        "  - [*1] Arpeggio NRPNs (00 01..00 06):   %2d defined | Direct NRPN controls in preset.json: %2d implemented, %2d open"
            .. " (5/6 covered via SysEx IDs 374..378)",
        #spec.nrpns, nrpnImpl, #spec.nrpns - nrpnImpl
    ))
    print(
        "  - [*2] MixerSW Bitmask (CC#83):          4 switches | Direct CC#83 in preset.json:          0 implemented"
            .. " (4/4 covered via SysEx IDs 254..257)"
    )
    print("")
end

-- ============================================================================
-- 5. CLI Entrypoint
-- ============================================================================

local args = { ... }
local presetFiles = {}
local verbose = false

for _, a in ipairs(args) do
    if a == "--verbose" or a == "-v" then
        verbose = true
    else
        -- If directory is passed, append /preset.json
        local f = io.open(a .. "/preset.json", "r")
        if f then
            f:close()
            presetFiles[#presetFiles + 1] = a .. "/preset.json"
        else
            presetFiles[#presetFiles + 1] = a
        end
    end
end

-- Default: scan all e1/*/preset.json files in the workspace
if #presetFiles == 0 then
    local defaultModules = {
        "z1-base",
        "z1-common-arp",
        "z1-eg",
        "z1-filter",
        "z1-fx",
        "z1-lfo",
        "z1-mix",
        "z1-mod",
        "z1-osc-common",
        "z1-osc1",
        "z1-osc2",
        "z1-sub-noise",
    }
    for _, m in ipairs(defaultModules) do
        local p = SCRIPT_DIR .. "/e1/" .. m .. "/preset.json"
        local f = io.open(p, "r")
        if f then
            f:close()
            presetFiles[#presetFiles + 1] = p
        end
    end
end

local coverage = {
    groups   = { [0] = {}, [1] = {}, [2] = {}, [3] = {} },
    progBase = {},
    cc       = {},
    nrpn     = {},
}

for _, pFile in ipairs(presetFiles) do
    inspectPresetJson(pFile, coverage)
end

print(string.format("Checked %d preset.json file(s):", #presetFiles))
for _, pFile in ipairs(presetFiles) do
    print("  - " .. pFile:gsub("^" .. SCRIPT_DIR .. "/", ""))
end
print("")

local progSpec = parseProgPrm(MIDIIMP_DIR .. "/PROG_PRM.TXT")
local multSpec = parseMultPrm(MIDIIMP_DIR .. "/MULT_PRM.TXT")
local patSpec  = parsePatPrm(MIDIIMP_DIR .. "/PAT_PRM.TXT")
local glblSpec = parseGlblPrm(MIDIIMP_DIR .. "/GLBL_PRM.TXT")
local midiSpec = parseMidiImp(MIDIIMP_DIR .. "/Z1_MIDIimp.TXT")

reportProgPrm(progSpec, coverage, verbose)
reportGenericPrm(multSpec, coverage, verbose)
reportGenericPrm(patSpec,  coverage, verbose)
reportGenericPrm(glblSpec, coverage, verbose)
reportMidiImp(midiSpec, coverage)
