--[[
  Copyright (C) 2011-2020 G. Bajlekov

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

local overlay = {}

local event = require "ui.frame.event"
local draw = require "ui.frame.draw"
local style = require "ui.style"
local elem = require "ui.elem"

overlay.meta = {__index = overlay}
overlay.type = "overlay"

function overlay:new(name)
	local o = {elem = {n = 0}, x = nil, y = nil, w = style.nodeWidth + 2, h = nil, visible = false, name = name}
	setmetatable(o, self.meta)
	return o
end

function overlay:copy(name)
	local o = self:new(name)

	o.x = self.x
	o.y = self.y
	o.w = self.w
	o.h = self.h

	o.elem = {}
	for i = 1, self.elem.n do
		o.elem[i] = table.copy(self.elem[i])
		o.elem[i].parent = o
	end
	o.elem.n = self.elem.n
	return o
end

function overlay:addElem(type, ...)
	assert(self.elem, "ERROR: frame does not support elements")
	return elem[type](self, ...)
end

function overlay.show(frame, mouse) -- frame: reference frame for x, y coordinates
	require "ui.widget".disable()
	overlay.default()
	overlay.frame.visible = true
	overlay.frame.x = mouse.lx + frame.x
	overlay.frame.y = mouse.ly + frame.y
end

function overlay.set(f, x, y)
	-- preserve x, y
	local x = x or overlay.frame and overlay.frame.x or 0
	local y = y or overlay.frame and overlay.frame.y or 0
	overlay.frame = f
	overlay.frame.x = x
	overlay.frame.y = y
end

function overlay.default(frame)
	if frame then
		overlay.defaultFrame = frame
	else
		overlay.frame = overlay.defaultFrame
	end
end

overlay.draw = require "ui.overlay.draw"

return overlay
