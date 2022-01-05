--[[
  Copyright (C) 2011-2021 G. Bajlekov

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

local parse = {}

--[[
name: node name

input: list of node inputs
output: list of node outputs
    - size is inferred based on inputs
    - override with image|map|color|value
    - override with list of shapes to supersize
    - override with explicit size array
    - override with function
param: list of node params
temp: list of temporary buffers
    - size is inferred based on inputs
    - override with image|map|color|value
    - override with list of shapes to supersize
    - override with explicit size array
    - override with function
-- solve size dependencies: iterative calculation
-- persistent vs temporary buffers:
	use explicit property for persistent buffers, otherwise allocate on demand

source:
    - file name
    - list of file names
    - source code
    - list of source codes
    - list of mixed items

init: alternative/additional init function

execute:
    - executeKernel specification
    - list of executeKernel specifications
    - execute function
    - execute function from file [*.lua]
    - execute function from string
-- specifications referring to buffers: 
	- named buffers and strings
	- I[0], O[1], P[2], T[3] generating function objects that are evaluated to get buffer at runtime
	- link to spec field converted to link to buffer object

category: category in the custom add node menu
    - nil: top level custom node
    - string: single category in custom menu
    - list of strings: nested categories in custom menu
    - false: do not include in custom menu

--]]

local tools = require "ops.tools"
local node = require "ui.node"
local thread = require "thread"

local function parse(ops, t)
	local proc = function(self)
		self.procType = t.proc or "dev"
		local p = {}
		local x, y, z = 1, 1, 1

		for i = 0, self.elem.n do

			-- TODO: use self.portIn[i], self.portOut[i], self.elem[i]

			if self.portIn[i] and self.elem[i] and self.elem[i].value ~= nil then
				if t.input[i].arg then
					p[t.input[i].arg] = tools.inputParam(self, i)
				else
					table.insert(p, tools.inputParam(self, i))
				end
			elseif self.portIn[i] then
				if t.input[i].source == "white" then
					if t.input[i].arg then
						p[t.input[i].arg] = tools.inputSourceWhite(self, i)
					else
						table.insert(p, tools.inputSourceWhite(self, i))
					end
				else
					if t.input[i].arg then
						p[t.input[i].arg] = tools.inputSourceBlack(self, i)
					else
						table.insert(p, tools.inputSourceBlack(self, i))
					end
				end
			elseif self.elem[i] and self.elem[i].value ~= nil then
				if t.param[i].arg then
					p[t.param[i].arg] = tools.plainParam(self, i)
				else
					table.insert(p, tools.plainParam(self, i))
				end
			end
			if p[#p] then
				if p[#p].x > x then x = p[#p].x end
				if p[#p].y > y then y = p[#p].y end
				if p[#p].z > z then z = p[#p].z end
			end
		end

		for i = 0, self.elem.n do
			if t.output and t.temp and t.output[i] and t.temp[i] then
				local sh = t.output[i].shape
				local x, y, z = x, y, z
				if t.output[i].size == "input" then x, y, z = tools.imageShape() end
				x = (sh == "value" or sh == "color") and 1 or x
				y = (sh == "value" or sh == "color") and 1 or y
				z = (sh == "value" or sh == "map") and 1 or z
				if t.output[i].arg then
					p[t.output[i].arg] = tools.autoOutputBuffer(self, i, x, y, z)
				else
					table.insert(p, tools.autoOutputBuffer(self, i, x, y, z))
				end
			elseif t.output and t.output[i] then
				local sh = t.output[i].shape
				local x, y, z = x, y, z
				if t.output[i].size == "input" then x, y, z = tools.imageShape() end
				x = (sh == "value" or sh == "color") and 1 or x
				y = (sh == "value" or sh == "color") and 1 or y
				z = (sh == "value" or sh == "map") and 1 or z
				if t.output[i].arg then
					p[t.output[i].arg] = tools.autoOutputSink(self, i, x, y, z)
				else
					table.insert(p, tools.autoOutputSink(self, i, x, y, z))
				end
			elseif t.temp and t.temp[i] then
				local sh = t.temp[i].shape
				local x, y, z = x, y, z
				if t.output[i].size == "input" then x, y, z = tools.imageShape() end
				x = (sh == "value" or sh == "color") and 1 or x
				y = (sh == "value" or sh == "color") and 1 or y
				z = (sh == "value" or sh == "map") and 1 or z
				if t.temp[i].arg then
					p[t.temp[i].arg] = tools.autoTempBuffer(self, i, x, y, z)
				else
					table.insert(p, tools.autoTempBuffer(self, i, x, y, z))
				end
			end
		end

		thread.ops[t.procName](p, self)
	end

	local gen = function(x, y)
		local n = node:new(t.name)
		n.process = proc

		if t.input then
			for k, v in pairs(t.input) do
				n:addPortIn(k, v.cs)
			end
		end

		if t.param then
			for k, v in pairs(t.param) do
				if v.type == "label" then
					n:addElem("label", k, v.name)
				elseif v.type == "text" then
					n:addElem("text", k, v.left, v.right)
				elseif v.type == "bool" then
					n:addElem("bool", k, v.name, v.default)
				elseif v.type == "int" then
					n:addElem("int", k, v.name, v.min, v.max, v.default, v.step)
				elseif v.type == "float" then
					n:addElem("float", k, v.name, v.min, v.max, v.default)
				end
			end
		end

		if t.output then
			for k, v in pairs(t.output) do
				n:addPortOut(k, v.cs)
			end
		end

		n:setPos(x, y)
		return n
	end

	ops[t.procName] = gen
end

local function register(ops, name)
	if type(name) == "string" then
		parse(ops, require("ops.spec."..name))
	elseif type(name) == "table" then
		parse(ops, name)
	end
end

return register