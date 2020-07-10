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

local tools = {}

local node = require "ui.node"
local data = require "data"
local thread = require "thread"


-- allocate new data if shapes mismatch
function tools.resize(out, x, y, z)
	if out then
		if not (out.x == x and out.y == y and out.z == z) then
			out = data:new(x, y, z)
		end
	else
		out = data:new(x, y, z)
	end
	return out
end

-- convert data to different color space
function tools.convert(dataSrc, dataDst, csSrc, csDst)
	if csSrc ~= csDst then
		thread.ops[csDst]({dataSrc, dataDst}, "dev")
	end
	dataDst.cs = csDst
end

-- register resize and convert in link structure
require "ui.node.link"._resize = tools.resize
require "ui.node.link"._convert = tools.convert


-- link input, white if not connected
function tools.inputSourceWhite(self, idx, cs)
	local link = self.portIn[idx].link
	local cs = cs or self.portIn[idx].cs
	return link and link:getData(cs, self.procType == "dev") or data.oneCS[cs]
end

-- link input, black if not connected
function tools.inputSourceBlack(self, idx, cs)
	local link = self.portIn[idx].link
	local cs = cs or self.portIn[idx].cs
	return link and link:getData(cs, self.procType == "dev") or data.zeroCS[cs]
end

-- link input, node data used if not connected
function tools.inputData(self, inputIdx, dataIdx, cs)
	dataIdx = dataIdx or inputIdx
	local data = self.data[dataIdx]
	local link = self.portIn[inputIdx].link
	local cs = cs or self.portIn[inputIdx].cs
	return link and link:getData(cs, self.procType == "dev") or self.procType == "dev" and data:toDevice() or data
end

-- param, not overriden by link input
function tools.plainParam(self, elemIdx)
	local data = tools.resize(self.data[elemIdx], 1, 1, 1)
	data.cs = "Y"
	self.data[elemIdx] = data
	data:set(0, 0, 0, self.elem[elemIdx].value)
	return self.procType == "dev" and data:syncDev() or data
end

-- link input, param value used if not connected
function tools.inputParam(self, inputIdx, elemIdx, cs)
	elemIdx = elemIdx or inputIdx
	local link = self.portIn[inputIdx].link
	if link then
		local cs = cs or self.portIn[inputIdx].cs
		return link:getData(cs, self.procType == "dev")
	else
		return tools.plainParam(self, elemIdx)
	end
end

-- link output, must be connected!
function tools.autoOutput(self, idx, x, y, z)
	local link = self.portOut[idx].link
	assert(link, "Attempted processing node ["..self.title.."] with no output ["..idx.."] connected")
	link:resizeData(x, y, z)
	local cs = self.portOut[idx].cs
	return link:setData(cs, self.procType)
end

-- link output, sinks data if not connected
function tools.autoOutputSink(self, idx, x, y, z)
	local link = self.portOut[idx].link
	if link then
		link:resizeData(x, y, z)
		local cs = self.portOut[idx].cs
		return link:setData(cs, self.procType)
	else
		return data.sink
	end
end

-- temporary internal buffer
function tools.autoTempBuffer(self, idx, x, y, z)
	x = x or 1
	y = y or 1
	z = z or 1
	local out = self.data[idx]
	out = tools.resize(out, x, y, z)
	self.data[idx] = out
	return out
end

-- link output, buffer if not connected
function tools.autoOutputBuffer(self, idx, x, y, z)
	if self.portOut[idx].link then
		return tools.autoOutput(self, idx, x, y, z)
	else
		return tools.autoTempBuffer(self, idx, x, y, z)
	end
end

local imageSizeX
local imageSizeY
local imageSizeZ

-- get global input image size
function tools.imageShape()
	return imageSizeX, imageSizeY, imageSizeZ
end

function tools.imageShapeSet(x, y, z)
	imageSizeX, imageSizeY, imageSizeZ = x, y, z
end


function tools.parse(ops, t)
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
				if v.type == "text" then
					n:addElem("text", k, v.left, v.right)
				elseif v.type == "bool" then
					n:addElem("bool", k, v.name, v.default)
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

function tools.register(ops, name)
	if type(name) == "string" then
		tools.parse(ops, require("ops.spec."..name))
	elseif type(name) == "table" then
		tools.parse(ops, name)
	end
end

return tools
