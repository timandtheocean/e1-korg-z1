-- Offline Electra One Firmware 5.0+ Lua Test Harness for local lua5.4 verification
-- Usage: lua5.4 run_e1_offline.lua <module_dir>

local modDir = arg[1]
assert(modDir, "Usage: lua5.4 run_e1_offline.lua <module_dir>")

-- Read preset.json using python3 to extract control definitions
local p = io.popen(string.format([[python3 -c '
import json, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
for c in d.get("controls", []):
    cid = c["id"]
    name = c.get("name", "")
    vis = "true" if c.get("visible", True) else "false"
    vids = []
    for v in c.get("values", []):
        vid = v.get("id", "value")
        fn = v.get("function", "")
        dv = v.get("defaultValue", 0)
        ov = v.get("overlayId", 0)
        vids.append(f"{vid}:{fn}:{dv}:{ov}")
    print(f"{cid}\t{name}\t{vis}\t" + ",".join(vids))
' %q]], modDir .. "/preset.json"))

-- Mock E1 globals
WHITE, RED, ORANGE, BLUE, GREEN, PURPLE = 0xFFFFFF, 0xF45C51, 0xF49500, 0x529DEC, 0x03A598, 0xC44795
WIDTH, HEIGHT = 3, 4
LEFT, RIGHT, CENTER = 0, 1, 2
REGULAR, BOLD = 0, 1
SMALL, MEDIUM, LARGE = 0, 1, 2
PORT_1, PORT_2 = 1, 2
SYSEX = 0xF0
CLICK = 1

local sentMessages = {}
local overlayStore = {}
local controlStore = {}
local groupStore   = {}
local pageStore    = {}

window = {
    stop = function() end,
    resume = function() end,
}

info = {
    setText = function(_) end,
}

graphics = {
    setColor = function(_) end,
    fillRect = function(_, _, _, _) end,
    drawRect = function(_, _, _, _) end,
    fillRoundRect = function(_, _, _, _, _) end,
    drawRoundRect = function(_, _, _, _, _) end,
    drawLine = function(_, _, _, _) end,
    print = function(_, _, _, _, _, _, _) end,
}

overlays = {
    create = function(id, items)
        local obj = { items = items }
        function obj:getNumItems() return #self.items end
        function obj:getValueByIndex(idx)
            local item = self.items[idx + 1]
            return item and item.value or idx
        end
        overlayStore[id] = obj
        return obj
    end,
    get = function(id)
        return overlayStore[id]
    end,
}

pages = {
    get = function(id)
        if not pageStore[id] then
            local pg = { id = id, name = "" }
            function pg:setName(n) self.name = n end
            function pg:getName() return self.name end
            pageStore[id] = pg
        end
        return pageStore[id]
    end,
}

local function makeControl(cid, name, visible, valSpecs)
    local ctrl = {
        id = cid,
        name = name,
        visible = visible,
        color = WHITE,
        values = {},
    }
    function ctrl:getId() return self.id end
    function ctrl:getName() return self.name end
    function ctrl:setName(n) self.name = n end
    function ctrl:isVisible() return self.visible end
    function ctrl:setVisible(v) self.visible = v end
    function ctrl:setColor(c) self.color = c end
    function ctrl:getBounds() return { 0, 0, 146, 56 } end
    function ctrl:repaint()
        if self.paintCb then self.paintCb(self) end
    end
    function ctrl:setPaintCallback(cb) self.paintCb = cb end
    function ctrl:setTouchCallback(cb) self.touchCb = cb end

    for _, vs in ipairs(valSpecs) do
        local vo = {
            id = vs.vid,
            val = vs.dv,
            fn = vs.fn,
            ovId = vs.ov,
            ctrl = ctrl,
            msg = {
                setRange = function(_, _, _) end,
                setValue = function(_, v) end,
            },
        }
        function vo:getId() return self.id end
        function vo:getControl() return self.ctrl end
        function vo:getMessage() return self.msg end
        function vo:setOverlayId(ov) self.ovId = ov end
        function vo:setRange(_, _, _, _) end
        function vo:getValue() return self.val end
        function vo:updateValue(v)
            self.val = v
        end
        function vo:setValue(v)
            self.val = v
            if self.fn and _G[self.fn] then
                _G[self.fn](self, v)
            end
        end
        ctrl.values[vs.vid] = vo
    end

    function ctrl:getValue(vid)
        return self.values[vid or "value"]
    end
    return ctrl
end

for line in p:lines() do
    local cidStr, name, visStr, vidsStr = line:match("^([^\t]+)\t([^\t]*)\t([^\t]+)\t(.*)$")
    if cidStr then
        local cid = tonumber(cidStr)
        local vis = (visStr == "true")
        local specs = {}
        for item in (vidsStr .. ","):gmatch("([^,]+),") do
            local vid, fn, dv, ov = item:match("^([^:]*):([^:]*):([^:]*):([^:]*)$")
            table.insert(specs, { vid = vid, fn = fn, dv = tonumber(dv) or 0, ov = tonumber(ov) or 0 })
        end
        controlStore[cid] = makeControl(cid, name, vis, specs)
    end
end
p:close()

controls = {
    get = function(id) return controlStore[id] end,
}

local mockDevice = {
    getChannel = function(_) return 1 end,
    sendSysex = function(_, body)
        local data = { 0xF0 }
        for i = 1, #body do data[#data + 1] = body[i] end
        data[#data + 1] = 0xF7
        sentMessages[#sentMessages + 1] = { type = SYSEX, data = data }
    end,
}

midi = {
    sendSysex = function(_, body)
        mockDevice:sendSysex(body)
    end,
}

preset = {
    getDevice = function(_) return mockDevice end,
    getGroup = function(id)
        if not groupStore[id] then
            local grp = { id = id, label = "", visible = true }
            function grp:setLabel(l) self.label = l end
            function grp:setVisible(v) self.visible = v end
            groupStore[id] = grp
        end
        return groupStore[id]
    end,
    getControl = function(id) return controlStore[id] end,
}

local cases = {}
test = {
    case = function(name, fn)
        cases[#cases + 1] = { name = name, fn = fn }
    end,
    clear = function()
        sentMessages = {}
    end,
    sent = function()
        return sentMessages
    end,
    turn = function(cid, val, vid)
        local c = controlStore[cid]
        assert(c, "Missing control " .. tostring(cid))
        local vo = c:getValue(vid or "value")
        assert(vo, "Missing valueObject on control " .. tostring(cid))
        vo:setValue(val)
    end,
    eq = function(a, b, msg)
        if a ~= b then
            error(string.format("test.eq failed (%s): got %s, expected %s", tostring(msg or ""), tostring(a), tostring(b)), 2)
        end
    end,
    ok = function(cond, msg)
        if not cond then
            error(string.format("test.ok failed (%s)", tostring(msg or "")), 2)
        end
    end,
    count = function(tbl, n, msg)
        if #tbl ~= n then
            error(string.format("test.count failed (%s): got %d, expected %d", tostring(msg or ""), #tbl, n), 2)
        end
    end,
    none = function(tbl, msg)
        if #tbl ~= 0 then
            error(string.format("test.none failed (%s): got %d messages", tostring(msg or ""), #tbl), 2)
        end
    end,
}

dofile(modDir .. "/main.lua")
if preset.onLoad then preset.onLoad() end
if preset.onReady then preset.onReady() end

dofile(modDir .. "/main-tests.lua")

local passed = 0
for _, c in ipairs(cases) do
    sentMessages = {}
    local ok, err = pcall(c.fn)
    if ok then
        passed = passed + 1
        print(string.format("  [PASS] %s", c.name))
    else
        print(string.format("  [FAIL] %s -> %s", c.name, tostring(err)))
        os.exit(1)
    end
end
print(string.format("Module %s: %d/%d tests passed offline", modDir, passed, #cases))
