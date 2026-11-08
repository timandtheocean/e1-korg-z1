-- >>> electra-control library: written by the Electra One editor, keep your own code above this line

-- electra-control module Filter_Sel 1.0.0 "Filter Sel"
local __electraControl_Filter_Sel = (function()
local filter = {}

-- A two-knob filter: the left knob is the cutoff, the right one the
-- resonance, and the control draws the frequency response the two describe -
-- a flat passband, a peak at the cutoff as tall as the resonance, and the
-- roll-off after it. Pressing a knob puts its value back to its default.

local STEP = 2          -- pixels between two points of the curve

-- Where a value sits in its range, 0 to 1, and the number itself.
local function fractionOf(control, id)
  local value = control:getValue(id)
  if not value then return 0, 0 end
  local min, max = value:getMin(), value:getMax()
  local level = value:isSet() and value:getValue() or min
  if max <= min then return 0, level end
  return (level - min) / (max - min), level
end

function filter.onReady(control)
  control:setPaintCallback(function(c)
    local bounds = c:getBounds()
    local w, h = bounds[WIDTH], bounds[HEIGHT]
    local cut, cutLevel = fractionOf(c, "cutoff")
    local res, resLevel = fractionOf(c, "resonance")

    local on = c:getColor()
    local dimmed = graphics.dim(on, 0.3)

    local top = 18                        -- the two numbers sit above the graph
    local bottom = h - 4
    local flat = top + (bottom - top) * 0.55   -- the passband line
    local cx = 4 + cut * (w - 8)          -- the cutoff, as an x
    local bump = res * (flat - top)       -- how far the peak rises above it
    local bumpWidth = w * 0.12
    local slope = (bottom - top) / (w * 0.2)   -- the roll-off, pixels down per pixel right

    local function yAt(x)
      local y
      if x <= cx then
        local d = (cx - x) / bumpWidth
        y = flat - (d < 1 and bump * (1 - d) * (1 - d) or 0)
      else
        y = flat - bump + (x - cx) * slope
      end
      if y > bottom then y = bottom end
      return y
    end

    graphics.setColor(dimmed)
    graphics.drawLine(0, bottom, w - 1, bottom)
    local marker = math.floor(cx + 0.5)
    graphics.drawLine(marker, top, marker, bottom)

    graphics.setColor(on)
    local px, py = 0, yAt(0)
    for x = STEP, w - 1, STEP do
      local y = yAt(x)
      graphics.drawLine(math.floor(px), math.floor(py + 0.5),
                        math.floor(x), math.floor(y + 0.5))
      px, py = x, y
    end

    graphics.print(4, 0, "CUTOFF " .. cutLevel, w // 2 - 4, LEFT, REGULAR, SMALL)
    graphics.print(w // 2, 0, "RESO " .. resLevel, w // 2 - 4, RIGHT, REGULAR, SMALL)
  end)

  -- event.valueId names the value the preset assigned to the knob that
  -- turned, so one callback serves both knobs.
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

return filter
end)()

-- electra-control bind Filter_Sel #1
do
  local previous = preset.onReady
  function preset.onReady(...)
    if previous then previous(...) end
    local ok, control
    ok, control = pcall(controls.get, 1); if ok and control and __electraControl_Filter_Sel.onReady then __electraControl_Filter_Sel.onReady(control); control:repaint() end
  end
end

-- <<< electra-control library

