--[[
  Copyright (C) 2011-2019 G. Bajlekov

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

-- tracks switching between tools
-- provides widget drawing
-- provides widget interaction
-- tracks widget parameters
-- replace imageSample structure

local widget = {}

widget.mode = "move"
widget.active = false
widget.panel = nil

widget.exclusive = {}
setmetatable(widget.exclusive, {__mode = "v"})

function widget.setExclusive(elem)
	table.insert(widget.exclusive, elem)
	elem.exclusive = widget.exclusive
end

widget.mouse = {}
widget.mouse.x = 0
widget.mouse.y = 0
widget.mouse.dx = 0
widget.mouse.dy = 0

widget.image = {}
widget.image.x = 0
widget.image.y = 0

widget.sample = {}
widget.sample.r = 0
widget.sample.g = 0
widget.sample.b = 0

local cursor = require "ui.cursor"

function widget.enable()
	widget.active = true
	cursor.cross()
end

function widget.disable()
	widget.active = false
	cursor.arrow()
end

function widget.imageCoord() error("widget.imageCoord() not registered yet!") end
function widget.imagePan() error("widget.imagePan() not registered yet!") end
function widget.imageSample() error("widget.imageSample() not registered yet!") end

widget.press = {}
widget.drag = {}
widget.release = {}

-- image pan callbacks
function widget.drag.imagePan(mouse)
	widget.imagePan(mouse.dx, mouse.dy)
end

-- color sample callbacks
function widget.press.colorSample(mouse)
	widget.mouse.x = mouse.lx
	widget.mouse.y = mouse.ly
	widget.imageSample(widget.mouse.x, widget.mouse.y)
end
function widget.drag.colorSample(mouse)
	widget.mouse.x = widget.mouse.x + mouse.dx
	widget.mouse.y = widget.mouse.y + mouse.dy
	widget.imageSample(widget.mouse.x, widget.mouse.y)
end

local oldmode = false
local function widgetReleaseCallback(mouse)
	if widget.release[widget.mode] then widget.release[widget.mode](mouse) end
	if oldmode then
		widget.mode = oldmode
		oldmode = false
	end
end
local function widgetDragCallback(mouse)
	if widget.drag[widget.mode] then widget.drag[widget.mode](mouse) end
	return widgetReleaseCallback
end
local function widgetAction(frame, mouse)
	if love.keyboard.isDown("space") then
		oldmode = widget.mode
		widget.mode = "imagePan"
	end
	if widget.press[widget.mode] then widget.press[widget.mode](mouse) end
	return widgetDragCallback
end


function widget.setFrame(frame)
	widget.frame = frame
	widget.frame.onAction = widgetAction
end

function widget.imagePanTool(elem)
	widget.setExclusive(elem)
	elem.onChange = function(elem)
		if elem.value then
			widget.mode = "imagePan"
		end
	end
end
function widget.colorSampleTool(elem)
	widget.setExclusive(elem)
	elem.onChange = function(elem)
		if elem.value then
			widget.mode = "colorSample"
		end
	end
end

return widget
