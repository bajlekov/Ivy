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

widget.mode = "imagePan"
widget.active = false
widget.frame = nil

widget.exclusive = {}
setmetatable(widget.exclusive, {__mode = "v"})
function widget.setExclusive(elem)
	table.insert(widget.exclusive, elem)
	elem.exclusive = widget.exclusive
end

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
do
	local x, y
	function widget.press.colorSample(mouse)
		x, y = mouse.lx, mouse.ly
		widget.imageSample(x, y)
	end
	function widget.drag.colorSample(mouse)
		x = x + mouse.dx
		y = y + mouse.dy
		widget.imageSample(x, y)
	end
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
