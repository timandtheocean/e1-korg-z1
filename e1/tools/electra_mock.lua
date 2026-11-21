-- Minimal Electra One (firmware 5.x) Lua API mock, used by verify_merge.py.
-- Expects globals PRESET (preset.json as a Lua table), SCRIPT (path of main.lua),
-- TESTS (list of callback invocations), IDMAP (merged id -> module id, or nil),
-- OVMAP (merged overlay id -> true for overlays of the module under test, or nil),
-- SYSEX_IN (list of byte arrays to feed to midi.onSysex), TICKS (timer ticks).

local unpack = table.unpack
local trace = {}
local function out(s) trace[#trace + 1] = s end

local missing = {}
local function noopObject(kind)
    return setmetatable({}, { __index = function(_, k)
        missing[kind .. ":" .. k] = true
        return function() return nil end
    end })
end

-- constants -------------------------------------------------------------------
local KNOWN_UPPER = { IDMAP = true, PAGEMAP = true, OVMAP = true, PRESET = true, SCRIPT = true, TESTS = true, SYSEX_IN = true, TICKS = true, CHECK_DUP_OV = true }
setmetatable(_G, { __index = function(_, k)
    if type(k) == "string" and not KNOWN_UPPER[k] and k:match("^[A-Z][A-Z0-9_]*$") then return 0 end
end })
X, Y, WIDTH, HEIGHT = 1, 2, 3, 4
PORT_1, PORT_2, PORT_CTRL = 0, 1, 2
WHITE, GREEN, ORANGE, RED, BLUE = 0xFFFFFF, 0x00FF00, 0xFFA500, 0xFF0000, 0x0000FF
graphics = noopObject("graphics")
graphics.dim = function(color, factor)
    if type(color) ~= "number" then return 0 end
    local f = math.max(0, math.min(1, factor or 0.5))
    local r = math.floor(((color >> 16) & 0xFF) * f)
    local g = math.floor(((color >> 8) & 0xFF) * f)
    local b = math.floor((color & 0xFF) * f)
    return (r << 16) | (g << 8) | b
end
window = { stop = function() end, resume = function() end, repaint = function() end }
info = { setText = function(t) end }
print = function(...) local t = {} for i, v in ipairs({ ... }) do t[i] = tostring(v) end out("PRINT " .. table.concat(t, " ")) end

local function hex(body)
    local t = {}
    for i, b in ipairs(body) do t[i] = string.format("%02X", b & 0xFF) end
    return table.concat(t, " ")
end

-- overlays ----------------------------------------------------------------------
local overlayStore = {}
local Overlay = {}
Overlay.__index = function(t, k)
    if Overlay[k] then return Overlay[k] end
    missing["overlay:" .. k] = true
    return function() end
end
function Overlay:getValueByIndex(i) local it = self.items[i + 1]; return it and it.value end
function Overlay:getLabel(i) local it = self.items[i + 1]; return it and it.label end
function Overlay:getIndexByValue(v)
    for i, it in ipairs(self.items) do
        if it.value == v then return i - 1 end
    end
    return nil
end
function Overlay:getLength() return #self.items end
function Overlay:getId() return self.id end
local function makeOverlay(id, items)
    local o = setmetatable({ id = id, items = items or {} }, Overlay)
    overlayStore[id] = o
    return o
end
overlays = {
    get = function(id)
        local o = overlayStore[id]
        if not o then
            error("failed: overlay " .. tostring(id) .. " does not exist")
        end
        return o
    end,
    create = function(id, items)
        if CHECK_DUP_OV and overlayStore[id] then
            out("ERROR overlay " .. tostring(id) .. " already exists")
        end
        return makeOverlay(id, items)
    end,
}

recallJson = function() return nil end
recall = function(tbl)
    if recallJson() == nil then
        out("ERROR recall: Failed to parse associated JSON file.")
    end
end

-- devices -----------------------------------------------------------------------
local Device = {}
Device.__index = Device
function Device:getChannel() return self.channel end
function Device:setChannel(c) self.channel = c end
function Device:getPort() return self.port end
function Device:getId() return self.id end
function Device:sendSysex(body) out("SX " .. hex(body)) end
local deviceStore = {}

midi = {
    sendSysex = function(port, body) out("SX " .. hex(body)) end,
    sendControlChange = function(...) out("CC " .. table.concat({ ... }, " ")) end,
    sendProgramChange = function(...) out("PC " .. table.concat({ ... }, " ")) end,
}
timer = {
    enable = function() end, disable = function() end,
    setPeriod = function() end, setBpm = function() end, isEnabled = function() return false end,
}

-- controls / values / messages / groups / pages ----------------------------------
local Message, Value, Control, Group, Page = {}, {}, {}, {}, {}
local DATA_KEYS = { min = true, max = true, default = true, current = true, overlayId = true,
    value = true, color = true, visible = true, name = true, label = true, func = true, formatter = true,
    parameterNumber = true, deviceId = true, type = true, paint = true, touch = true }
local function cls(t, name)
    t.__index = function(o, k)
        if t[k] then return t[k] end
        if DATA_KEYS[k] then return nil end
        missing[name .. ":" .. k] = true
        return function() end
    end
end
cls(Message, "message"); cls(Value, "value"); cls(Control, "control"); cls(Group, "group"); cls(Page, "page")

function Message:getParameterNumber() return self.parameterNumber end
function Message:getDeviceId() return self.deviceId end
function Message:getType() return self.type end
function Message:setRange(a, b) self.min, self.max = a, b end
function Message:getMin() return self.min end
function Message:getMax() return self.max end
function Message:getValue() return self.value end
function Message:setValue(v) self.value = v; if self.valObj then self.valObj.current = v end end
function Message:setMin(v) self.min = v end
function Message:setMax(v) self.max = v end

function Value:getId() return self.id end
function Value:getControl() return self.control end
function Value:setName(n) self.name = n end
function Value:getName() return self.name or "" end
function Value:getMessage() return self.message end
function Value:setOverlayId(id) self.overlayId = id end
function Value:getOverlayId() return self.overlayId end
function Value:setRange(a, b) self.min, self.max = a, b end
function Value:setMin(v) self.min = v end
function Value:setMax(v) self.max = v end
function Value:getMin() return self.min end
function Value:getMax() return self.max end
function Value:setDefault(v) self.default = v end
function Value:getDefault() return self.default end
function Value:updateValue(v) self.current = v end
function Value:setValue(v) self.current = v end
function Value:getValue() return self.current end
function Value:isSet() return self.current ~= nil end

function Control:getId() return self.id end
function Control:getValue(id) return self.valuesById[id or "value"] end
function Control:getValues() return self.values end
function Control:setVisible(v) self.visible = v end
function Control:isVisible() return self.visible end
function Control:setName(n) self.name = n end
function Control:getName() return self.name end
function Control:setColor(c) self.color = c end
function Control:getColor() return self.color end
function Control:getBounds() return { unpack(self.bounds) } end
function Control:setBounds(b) self.bounds = b end
function Control:repaint() end
function Control:setPaintCallback(f) self.paint = f end
function Control:setTouchCallback(f) self.touch = f end
function Control:setPotCallback(f) self.pot = f end
function Control:setSwitchCallback(f) self.switch = f end
function Control:getPageId() return self.pageId end
function Control:getControlSetId() return self.controlSetId end
function Control:setSlot() end

function Group:getId() return self.id end
function Group:setVisible(v) self.visible = v end
function Group:isVisible() return self.visible end
function Group:setLabel(l) self.label = l end
function Group:getLabel() return self.label end
function Group:setName(l) self.label = l end
function Group:setColor(c) self.color = c end
function Group:getBounds() return { unpack(self.bounds) } end
function Group:setBounds(b) self.bounds = b end

function Page:getId() return self.id end
function Page:getName() return self.name end
function Page:setName(n) self.name = n end

local controlStore, groupStore, pageStore = {}, {}, {}
local activePage = 1

for _, d in ipairs(PRESET.devices or {}) do
    deviceStore[d.id] = setmetatable({ id = d.id, port = d.port, channel = d.channel or 1 }, Device)
end
for _, p in ipairs(PRESET.pages or {}) do
    pageStore[p.id] = setmetatable({ id = p.id, name = p.name }, Page)
end
for _, o in ipairs(PRESET.overlays or {}) do makeOverlay(o.id, o.items) end
for _, g in ipairs(PRESET.groups or {}) do
    groupStore[g.id] = setmetatable({ id = g.id, label = g.name, visible = g.visible ~= false,
        color = g.color, bounds = g.bounds or { 0, 0, 0, 0 } }, Group)
end
for _, c in ipairs(PRESET.controls or {}) do
    local ctl = setmetatable({ id = c.id, name = c.name, visible = c.visible ~= false, color = c.color,
        bounds = c.bounds or { 0, 0, 0, 0 }, pageId = c.pageId or 1, controlSetId = c.controlSetId,
        values = {}, valuesById = {}, json = c }, Control)
    for _, v in ipairs(c.values or {}) do
        local m = v.message or {}
        local msg = setmetatable({ type = m.type, parameterNumber = m.parameterNumber, deviceId = m.deviceId,
            min = m.min, max = m.max }, Message)
        local val = setmetatable({ id = v.id or "value", control = ctl, message = msg, min = v.min, max = v.max,
            overlayId = v.overlayId, default = v.defaultValue, func = v["function"], formatter = v.formatter }, Value)
        msg.valObj = val
        ctl.values[#ctl.values + 1] = val
        ctl.valuesById[val.id] = val
    end
    controlStore[c.id] = ctl
end

preset = {
    getControl = function(id) return controlStore[id] end,
    getGroup = function(id) return groupStore[id] end,
    getDevice = function(id) return deviceStore[id] end,
    getPage = function(id) return pageStore[id] end,
    getOverlay = function(id) return overlayStore[id] end,
}
controls = { get = function(id) return controlStore[id] end }
groups = { get = function(id) return groupStore[id] end }
pages = {
    get = function(id) return pageStore[id] end,
    display = function(id) activePage = id; out("PAGE " .. tostring(PAGEMAP and PAGEMAP[id] or id)) end,
    getActive = function() return pageStore[activePage] end,
}
devices = { get = function(id) return deviceStore[id] end }

-- run -----------------------------------------------------------------------------
local function lid(id) if IDMAP then return IDMAP[id] end return id end

local function overlayText(id)
    local o = id and overlayStore[id]
    if not o then return "nil" end
    local t = {}
    for i, it in ipairs(o.items) do t[i] = tostring(it.value) .. "=" .. tostring(it.label) end
    return table.concat(t, ",")
end

local lastState = {}
local function snapshotState()
    local keys = {}
    for gid, c in pairs(controlStore) do
        local l = lid(gid)
        if l then
            local parts = { tostring(c.visible), tostring(c.name), tostring(c.color) }
            for _, v in ipairs(c.values) do
                parts[#parts + 1] = v.id .. ":" .. tostring(v.min) .. ".." .. tostring(v.max) .. ":" ..
                    tostring(v.message.min) .. ".." .. tostring(v.message.max) .. ":" .. tostring(v.current) ..
                    ":" .. overlayText(v.overlayId)
            end
            keys["C" .. l] = table.concat(parts, "|")
        end
    end
    for gid, g in pairs(groupStore) do
        local l = lid(gid)
        if l then keys["G" .. l] = tostring(g.visible) .. "|" .. tostring(g.label) .. "|" .. tostring(g.color) end
    end
    local names = {}
    for k in pairs(keys) do names[#names + 1] = k end
    table.sort(names)
    for _, k in ipairs(names) do
        if lastState[k] ~= keys[k] then out("STATE " .. k .. " " .. keys[k]) end
    end
    lastState = keys
end

local function safe(label, f, ...)
    local ok, err = pcall(f, ...)
    if not ok then out("ERROR " .. label .. ": " .. tostring(err)) end
end

local ok, err = pcall(dofile, SCRIPT)
if not ok then out("ERROR loading script: " .. tostring(err)) end
local phaseStart = #trace
if preset.onLoad then safe("onLoad", preset.onLoad) end
if preset.onReady then safe("onReady", preset.onReady) end
-- lifecycle output of other modules is not comparable; keep only state
for i = #trace, phaseStart + 1, -1 do
    if not trace[i]:match("^ERROR") then table.remove(trace, i) end
end
snapshotState()
out("---- callbacks")

local function paintAll(tag)
    for gid, c in pairs(controlStore) do
        if lid(gid) and c.paint then safe("paint C" .. lid(gid) .. " " .. tag, c.paint, c) end
    end
end
paintAll("init")

for _, t in ipairs(TESTS) do
    if t.sysex then
        local bytes = t.sysex
        out("SYSEX_IN " .. hex(bytes))
        local block = {
            getLength = function(self) return #bytes end,
            peek = function(self, i) return bytes[i] end,
            getManufacturerSysexId = function(self) return bytes[2] end,
        }
        safe("onSysex", midi.onSysex, PORT_1, block)
        snapshotState()
    elseif t.ticks then
        if timer.onTick then
            for i = 1, t.ticks do safe("onTick", timer.onTick) end
        end
        out("TICKS " .. t.ticks)
        snapshotState()
    else
        local c = controlStore[t.ctrl]
        local v = c and c.valuesById[t.valueId]
        for _, x in ipairs(t.values) do
            out(string.format("CALL C%d.%s %s(%s)", lid(t.ctrl), t.valueId, t.kind, tostring(x)))
            local f = _G[t.fn]
            if not f then
                out("ERROR missing function " .. t.fn)
            else
                local okc, res = pcall(f, v, x)
                if not okc then out("ERROR " .. tostring(res))
                elseif t.kind == "formatter" then out("FMT " .. tostring(res)) end
            end
            if t.kind == "function" then v.current = x end
            snapshotState()
        end
    end
end
paintAll("end")

if SYSEX_IN and midi.onSysex then
    for _, bytes in ipairs(SYSEX_IN) do
        out("SYSEX_IN " .. hex(bytes))
        local block = {
            getLength = function(self) return #bytes end,
            peek = function(self, i) return bytes[i] end,
            getManufacturerSysexId = function(self) return bytes[2] end,
        }
        safe("onSysex", midi.onSysex, PORT_1, block)
        snapshotState()
    end
end
if TICKS and timer.onTick then
    for i = 1, TICKS do safe("onTick", timer.onTick) end
    out("TICKS " .. TICKS)
    snapshotState()
end

local m = {}
for k in pairs(missing) do m[#m + 1] = k end
table.sort(m)
if #m > 0 then out("MOCK-MISSING " .. table.concat(m, " ")) end
io.write(table.concat(trace, "\n"), "\n")
