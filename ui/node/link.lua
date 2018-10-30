--[[
  Copyright (C) 2011-2018 G. Bajlekov

    ImageFloat is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ImageFloat is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local style = require "ui.style"

local link = {type = "link"}
link.meta = {__index = link}

function link:setInput(port)
	if port == self.portIn then
		return
	else
		port.parent.dirty = true
		self.portIn = port
		if port then
			port.link = self
		end
	end
end

function link:setOutput(port)
	if port and port.link ~= self then -- port might be empty
		port.parent.dirty = true
		self.portOut[port] = true -- add new end point
		if port.link then -- do not remove if node is already connected
			port.link:removeOutput(port) -- remove old connetcion from port
		end
		port.link = self -- add new connection to port
	end
	assert(self.portIn)
end

local curve = love.math.newBezierCurve(0, 0, 0, 0, 0, 0, 0, 0)
function link:updateCurve(x, y)
	local xin = self.portIn.parent.ui.x + (self.portIn.parent.w or style.nodeWidth) + style.nodeBorder + (style.elemHeight) / 2
	local yin
	if self.portIn.n == 0 then
		yin = self.portIn.parent.ui.y + style.titleHeight - style.elemHeight / 2 - 0.5 - style.nodeBorder + style.elemBorder
	else
		yin = self.portIn.parent.ui.y + style.titleHeight + style.elemHeight * (self.portIn.n) - style.elemHeight / 2 - 0.5
	end

	local xout, yout
	if x and y then -- update currently moved noodle
		xout = x
		yout = y

		local diff = 5 + 0.4 * math.abs(xin - xout) + 0.3 * math.abs(yin - yout)

		curve:setControlPoint(1, xin, yin)
		curve:setControlPoint(2, xin + diff, yin)
		curve:setControlPoint(3, xout - diff, yout)
		curve:setControlPoint(4, xout, yout)

		self.curve.move = curve:render(5)
	else
		self.curve.move = nil
		for k, v in pairs(self.portOut) do
			xout = k.parent.ui.x - style.nodeBorder - (style.elemHeight) / 2
			if k.n == 0 then
				yout = k.parent.ui.y + style.titleHeight - style.elemHeight / 2 - 0.5 - style.nodeBorder + style.elemBorder
			else
				yout = k.parent.ui.y + style.titleHeight + style.elemHeight * (k.n) - style.elemHeight / 2 - 0.5
			end

			local diff = 5 + 0.4 * math.abs(xin - xout) + 0.3 * math.abs(yin - yout)

			curve:setControlPoint(1, xin, yin)
			curve:setControlPoint(2, xin + diff, yin)
			curve:setControlPoint(3, xout - diff, yout)
			curve:setControlPoint(4, xout, yout)

			self.curve[k] = curve:render(5)
		end
	end
end

function link:draw(color)
	love.graphics.setLineJoin("bevel")
	love.graphics.setLineStyle("smooth")

	--love.graphics.setColor(style.backgroundColor)
	love.graphics.setColor({0, 0, 0, 0.3})
	love.graphics.setLineWidth(5)
	for k, v in pairs(self.curve) do
		if k ~= "move" then
			love.graphics.line(v)
		end
	end
	if self.curve.move then
		love.graphics.line(self.curve.move)
	end

	love.graphics.setColor(color or style.linkColor)
	if not self.data then love.graphics.setColor(color or style.gray4) end
	love.graphics.setLineWidth(3)
	local csPrint = true
	for k, v in pairs(self.curve) do
		if k ~= "move" then
			love.graphics.line(v)

			if settings.linkDebug and self.data and csPrint then
				love.graphics.setFont(style.elemFont)
				local cs = self.data.cs
				for k, v in pairs(self.dataCS) do
					cs = cs.."/"..k
				end
				love.graphics.print(cs.."["..self.data.x..","..self.data.y..","..self.data.z.."]", v[1] + 3, v[2] + 1)
				csPrint = false
			end
		end
	end
	if self.curve.move then
		love.graphics.setColor(style.orange)
		love.graphics.line(self.curve.move)
	end

	love.graphics.setLineWidth(1)
end

function link:connect(portIn, portOut)
	local link
	if portIn.link then
		link = portIn.link
	else
		link = {
			data = nil,
			dataCS = {},
			portIn = nil,
			portOut = {},
			curve = {},
		}
		link = setmetatable(link, self.meta)
		link:setInput(portIn)
	end
	link:setOutput(portOut)
	return link
end

function link:removeOutput(port)
	port.parent.dirty = true
	port.link = nil
	self.portOut[port] = nil
	self.curve[port] = nil
	if table.empty(self.portOut) then
		self:remove()
	end
end

function link:remove()
	if self.portIn then
		self.portIn.link = nil
	end
	for k, v in pairs(self.portOut) do
		k.parent.dirty = true
		k.link = nil
	end

	link.keepGarbage(self) -- keep data associated with link until all processing is done
	self.portOut = {}
	self.curve = {}
	collectgarbage("collect") -- TODO: remove if no problems occur with data being removed during processing
end

local trash = {}
function link.keepGarbage(data)
	table.insert(trash, data)
end
function link.collectGarbage()
	trash = {}
	collectgarbage("collect")
end



local thread = require "thread"

local function toDevice(buf)
	if buf.__gpuDirty then
		thread.ops.syncDevice(buf)
		buf.__gpuDirty = false
	end
end

local function toHost(buf)
	if buf.__cpuDirty then
		thread.ops.syncHost(buf)
		buf.__cpuDirty = false
	end
end

local function convert(src, dst, cs)
	toDevice(src)
	if cs == "Y" or cs == "L" then
		dst = link.dataResize(dst, src.x, src.y, 1)
	else
		dst = link.dataResize(dst, src.x, src.y, 3)
	end
	link.dataConvert(src, dst, src.cs, cs)
	dst.cs = cs
	dst.__csDirty = false
	dst.__cpuDirty = true
	return dst
end

local function checkSingleCS(t)
	local cs
	for k, v in pairs(t) do
		if (not cs) and k.parent.state == "waiting" then
			cs = k.cs
		elseif k.cs ~= cs and k.parent.state == "waiting" then
			return false
		end
	end
	return true
end

function link:getData(cs, dev)
	self.data = self.data or require "data".zero
	if cs == self.data.cs or cs == "ANY" or self.data.cs == "ANY" then -- no conversion needed
		if dev then
			toDevice(self.data)
		else
			toHost(self.data)
		end
		return self.data
	elseif cs ~= "Y" and cs ~= "L" and checkSingleCS(self.portOut) then -- optimize when all outputs have the same CS
		-- TODO: conversion to Y/L will be lossy!!
		local newData = convert(self.data, self.data, cs)
		if dev then
			toDevice(newData)
		else
			toHost(newData)
		end
		self.data = newData
		return newData
	else
		local newData = self.dataCS[cs]
		if (not newData) or newData.__csDirty then
			newData = convert(self.data, newData, cs)
		end
		if dev then
			toDevice(newData)
		else
			toHost(newData)
		end
		self.dataCS[cs] = newData
		return newData
	end
end

function link:resizeData(x, y, z)
	self.data = link.dataResize(self.data, x, y, z)
	return self.data
end

function link:setData(cs, dev)
	local data = self.data
	cs = cs or data.cs

	if dev then
		if dev == "dev" then
			data.__cpuDirty = true
		else
			data.__gpuDirty = true
		end
	end
	data.cs = cs

	--self.dataCS = {}
	---[[
	self.dataCS[cs] = nil
	for k, v in pairs(self.dataCS) do
		if v.__csDirty then
			self.dataCS[k] = nil -- remove all CS that were dirty before (not updated since previous change)
		else
			v.__csDirty = true -- set all CS to dirty due to changed main buffer
		end
	end
	--]]
	return data
end

function link:updateCS(cs)
	local data = self.data
	cs = cs or data.cs
	self.dataCS[cs] = nil
end

return link
