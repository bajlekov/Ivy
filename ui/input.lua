--[[
  Copyright (C) 2011-2018 G. Bajlekov

    Ivy is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Ivy is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local input = {}

local moveCallback = false
local releaseCallback = false

local inputEvent = {
  x = 0,
  y = 0,
  dx = 0,
  dy = 0,
  ox = 0,
  oy = 0,
  button = false,
}


local overlayInput = require "ui.overlay.input"
local nodeInput = require "ui.node.input"
local frameInput = require "ui.frame.input"

function input.mousePressed(x, y, button)
  -- release any previous mouse drag event
  input.mouseReleased(x, y)

  inputEvent.ox = x
  inputEvent.oy = y
  inputEvent.button = button

  local hit = false
  if not hit then
    hit, moveCallback = overlayInput.press(inputEvent)
  end
  if not hit then
    hit, moveCallback = nodeInput.press(inputEvent)
  end
  if not hit then
    hit, moveCallback = frameInput.press(inputEvent)
  end

  input.mouseMoved(x, y, 0, 0)
end


function input.mouseMoved(x, y, dx, dy)
  if moveCallback then
    inputEvent.x = x
    inputEvent.y = y
    inputEvent.dx = dx
    inputEvent.dy = dy
    releaseCallback = moveCallback(inputEvent)
  end
end


function input.mouseReleased(x, y)
  inputEvent.x = x
  inputEvent.y = y
  inputEvent.dx = 0
  inputEvent.dy = 0

  if releaseCallback then
    releaseCallback(inputEvent)
  end

  moveCallback = false
  releaseCallback = false
end

return input
