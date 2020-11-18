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

local draw = require "ui.elem.draw"

local elem = {}

local function processElem(self, n, elem)
	assert(type(n) == "number")
	assert(n >= 1)

	elem.parent = self
	elem.visible = true
	elem.draw = draw[elem.type]

	self.elem[n] = elem
	if self.elem.n < n then self.elem.n = n end

	return elem
end

function elem:float(n, name, min, max, default)
	local elem = {
		value = default,
		min = min,
		max = max,
		default = default,
		name = name,
		type = "float",
	}
	return processElem(self, n, elem)
end

function elem:int(n, name, min, max, default, step)
	local elem = {
		value = math.round(default),
		min = math.round(min),
		max = math.round(max),
		step = step and math.round(math.max(step, 1)) or 1,
		default = math.round(default),
		name = name,
		type = "int",
	}
	return processElem(self, n, elem)
end

function elem:enum(n, name, enum, default)
	local elem = {
		value = default,
		enum = enum,
		default = default,
		name = name,
		type = "enum",
	}
	return processElem(self, n, elem)
end


function elem:bool(n, name, default)
	local elem = {
		value = default or false,
		default = default,
		name = name,
		type = "bool",
		exclusive = false,
	}
	return processElem(self, n, elem)
end

function elem:label(n, name, line)
	local elem = {
		name = name,
		line = line,
		type = "label",
	}
	return processElem(self, n, elem)
end

function elem:text(n, left, right)
	local elem = {
		left = left,
		right = right,
		type = "text",
	}
	return processElem(self, n, elem)
end

function elem:button(n, name, action)
	local elem = {
		name = name,
		action = action,
		type = "button",
	}
	return processElem(self, n, elem)
end

function elem:addNode(n, name, action)
	local f = action[1]
	local c = {}
	for i = 2, #action do
		table.insert(c, action[i])
		f = f[action[i]]
	end

	local function actionFunction(x, y)
		assert(type(f)=="function", "Unknown function associated to action!")
		local n = f(x, y)
		n.call = c -- store init function info in node for saving and reproduction
		return n
	end

	local elem = {
		name = name,
		action = actionFunction,
		type = "button",
	}
	return processElem(self, n, elem)
end

function elem:menu(n, name, frame)
	local elem = {
		name = name,
		frame = frame,
		type = "button",
		menu = true,
	}
	return processElem(self, n, elem)
end

function elem:dropdown(n, name, frame)
	local elem = {
		name = name,
		frame = frame,
		type = "button",
		dropdown = true,
	}
	return processElem(self, n, elem)
end

function elem:color(n, name)
	local elem = {
		name = name,
		type = "color",
		value = {1, 1, 1, 1},
	}
	return processElem(self, n, elem)
end

function elem:textinput(n, default)
	local elem = {
		type = "textinput",
		value = default,
		default = default,
	}
	return processElem(self, n, elem)
end

return elem
