-- >>> electra-control library: written by the Electra One editor, keep your own code above this line

-- electra-control module MIXER 1.0.0 "MIXER"
local __electraControl_MIXER = (function()
local mixer = {}

-- An eight-channel level control: one custom control across the whole
-- knob area of a mini, every knob a channel. Each knob moves the value the
-- preset assigned to it (ch1 to ch8), the bar under the knob shows it,
-- and pressing a knob puts its channel back to its default.

local CHANNELS = 8
local GAP = 12

local function levelOf(control, id)
  local value = control:getValue(id)
  if not value then return 0, 0, 1 end
  local min, max = value:getMin(), value:getMax()
  local level = value:isSet() and value:getValue() or min
  if max <= min then return 0, level, max end
  return (level - min) / (max - min), level, max
end

function mixer.onReady(control)
  control:setPaintCallback(function(c)
    local bounds = c:getBounds()
    local w, h = bounds[WIDTH], bounds[HEIGHT]
    local on = c:getColor()
    local off = graphics.dim(on, 0.25)

    local columnWidth = (w - GAP * (CHANNELS + 1)) // CHANNELS
    local top = 22
    local bottom = h - 26
    local height = bottom - top

    for i = 1, CHANNELS do
      local fraction, level = levelOf(c, "ch" .. i)
      local x = GAP + (i - 1) * (columnWidth + GAP)
      local fill = math.floor(height * fraction + 0.5)

      graphics.setColor(off)
      graphics.drawRect(x, top, columnWidth, height)
      graphics.setColor(on)
      if fill > 0 then
        graphics.fillRect(x, bottom - fill, columnWidth, fill)
      end
      graphics.print(x, 2, tostring(level), columnWidth, CENTER, BOLD, SMALL)
      graphics.print(x, bottom + 6, "CH " .. i, columnWidth, CENTER, REGULAR, SMALL)
    end
  end)

  -- event.valueId names the channel the knob that turned is assigned to.
  control:setPotCallback(function(c, event)
    if event.delta == 0 then return end
    local v = c:getValue(event.valueId)
    if not v then return end
    local level = v:isSet() and v:getValue() or v:getMin()
    v:setValue(level + event.delta)
    c:repaint()
  end)

  control:setSwitchCallback(function(c, event)
    if event.type ~= 1 then return end
    local v = c:getValue(event.valueId)
    if not v then return end
    v:setValue(v:getDefault())
    c:repaint()
  end)

  control:repaint()
end

return mixer
end)()

-- electra-control bind MIXER #1
do
  local previous = preset.onReady
  function preset.onReady(...)
    if previous then previous(...) end
    local ok, control
    ok, control = pcall(controls.get, 1); if ok and control and __electraControl_MIXER.onReady then __electraControl_MIXER.onReady(control); control:repaint() end
  end
end

-- <<< electra-control library

