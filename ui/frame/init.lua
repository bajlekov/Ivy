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

local event = require "ui.frame.event"
local draw = require "ui.frame.draw"
local style = require "ui.style"

local frame = {}

local function pass() end

-- create new frame UI scaffold
function frame:new(x, y, w, h)
	x = x or 0
	y = y or 0
	h = h or (love.graphics.getHeight() - y)
	w = w or (love.graphics.getWidth() - x)
	local out = {
		name = "BaseFrame",
		direction = "V", -- V or H -> direction of splitting
		x = x, y = y, -- position
		w = w, h = h, -- size
		style = "empty", -- panel, stack, tabs, toolbar, empty ...
		xoff = 0, yoff = 0,
		hidden = false,
		sub = {}, -- hash table for lookup by name

		-- allow overridable events per frame
		onAction = pass, -- left mouse button
		onContext = pass, -- right mouse button
		onMove = pass, -- left move
		onWheel = pass, -- mouse wheel
		onKey = pass, -- key press
		onUpdate = pass, -- update value
		onDraw = pass, -- draw routine
	}

	return setmetatable(out, {__index = frame})
end

-- change the direction of splitting
function frame:flip()
	self.direction = self.direction == "H" and "V" or "H"
	return self
end
function frame:panel(headless)
	self.style = "panel" -- allow for hidden title
	if headless then
		self.headless = true
	else
		self.yoff = style.titleHeight
	end
	self.onAction = event.onAction.panel
	self.elem = { -- ui elemenets
		n = 0,
	}
	return self
end
function frame:tabs()
	error("NYI")
	self.style = "tabs"
	return self
end
function frame:stack()
	error("NYI")
	self.style = "stack"
	return self
end
function frame:menu()
	error("NYI")
	self.style = "menu"
	self.elem = { -- ui elemenets
		n = 0,
	}
	return self
end
function frame:toolbar(headless)
	self.style = "toolbar"
	if headless then
		self.headless = true
	else
		self.yoff = style.titleHeight
	end
	self.onAction = event.onAction.toolbar
	self.elem = { -- ui elemenets
		n = 0,
	}
	return self
end
function frame:statusbar()
	self.style = "statusbar"
	self.leftText = ""
	self.centerText = ""
	self.rightText = ""
	return self
end

local elem = require "ui.elem"
function frame:addElem(type, ...)
	assert(self.elem, "ERROR: frame does not support elements")
	return elem[type](self, ...)
end

-- parse size specifier
function frame:setSize(size)
	size = size or "fill" -- Fill, 123, 123px, 123% -> parse
	local unit

	if type(size) == "number" then
		size = math.floor(size + 0.5)
		unit = "px"
	elseif size == "fit" then
		if self.direction == "H" then
			size = style.nodeWidth
			unit = "px"
		else
			unit = "fit"
		end
	elseif size == "fill" then
		unit = "fill"
	else
		local match = string.match(size, "^(%d+)px$")
		if match then
			size = tonumber(match)
			unit = "px"
		else
			local match = string.match(size, "^(%d+)%%$")
			if match then
				size = tonumber(match)
				unit = "%"
			else
				error("invalid size specifier")
			end
		end
	end

	assert(size)
	assert(unit)
	self.size = size
	self.unit = unit
end


-- add new frame
function frame:frame(name, size)
	local n = #self + 1
	name = name or ("Frame_"..n)

	self[n] = self:new()
	self[n].name = name
	self[n]:setSize(size)
	self[n].direction = self.direction == "H" and "V" or "H"
	self[n].parent = self
	self.sub[name] = self[n]
	return self[n]
end

-- recalculate sizes
function frame:arrange(w, h)
	self.w = w or self.w
	self.h = h or self.h

	if self.hidden or #self == 0 then return end

	local maxSize = self.direction == "V" and self.h or self.w
	local width = {}
	local numFill = 0
	local totWidth = 0
	local fill = false

	for k, v in ipairs(self) do
		if not v.hidden then
			if v.size == "fit" then
				width[k] = style.titleHeight + style.elemHeight * v.elem.n - (v.elem.n == 0 and style.nodeBorder or style.elemBorder) + 6
			elseif v.size == "fill" then
				width[k] = "fill"
				numFill = numFill + 1
				fill = true
			elseif v.unit == "px" then width[k] = v.size
			elseif v.unit == "%" then width[k] = math.floor(v.size / 100 * maxSize + 0.5)
			else error("wrong specification") end

			if type(width[k]) == "number" then totWidth = totWidth + width[k] end
		end
	end

	if totWidth > maxSize then error("exceeding size") end
	local fillwidth = math.floor((maxSize - totWidth) / numFill + 0.5)

	local x, y, w, h = self.x, self.y, self.w, self.h
	assert(fill or totWidth == maxSize, totWidth..", "..maxSize)
	for k, v in ipairs(self) do
		if not v.hidden then
			if width[k] == "fill" then width[k] = fillwidth end
			if self.direction == "V" then
				v.w, v.h = w, width[k]
				v.x, v.y = x, y
				y = y + width[k]
			else
				v.w, v.h = width[k], h
				v.x, v.y = x, y
				x = x + width[k]
			end
			v.w = v.w - 2 * self.xoff
			v.h = v.h - 2 * self.yoff
			v.x = v.x + self.xoff
			v.y = v.y + self.yoff
			v.scroll = 0
		end
		v:arrange() -- recurse over sub-frames
	end
end

function frame:draw()
	if not self.hidden then
		draw[self.style](self)
	end
	for k, v in ipairs(self) do
		v:draw()
	end
end

function frame:getFrame(x, y)
	if #self > 0 then
		for k, v in ipairs(self) do
			if not v.hidden and x >= v.x and x < v.x + v.w and y >= v.y and y < v.y + v.h then
				local sub, sx, sy = v:getFrame(x, y)
				if sub then
					return sub, sx, sy
				else
					return self, x - self.x, y - self.y
				end
			end
		end
	end
	return self, x - self.x, y - self.y
end

function frame:registerBaseFrame()
	frame.baseFrame = self
	return self
end

return frame
