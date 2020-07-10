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


	self:cleanData() -- TODO: properly address continuous node cleanup
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
	self:cleanData()
end

function link:remove()
	if self.portIn then
		self.portIn.link = nil
	end
	for k, v in pairs(self.portOut) do
		k.parent.dirty = true
		k.link = nil
	end

	self.portOut = {}
	self.curve = {}
	self:cleanData()
end


local thread = require "thread"

local function convert(src, dst, cs)
	if cs == "Y" or cs == "L" then
		dst = link._resize(dst, src.x, src.y, 1)
	else
		dst = link._resize(dst, src.x, src.y, 3)
	end
	link._convert(src, dst, src.cs, cs)
	dst.cs = cs
	return dst
end

local function checkSingleCS(t)
	local cs
	for k, v in pairs(t) do
		if (not cs) then
			cs = k.cs
		elseif k.cs ~= cs then
			return false
		end
	end
	return true
end

function link:getData(cs, dev)
	self.data = self.data or require "data".zero
	if cs == self.data.cs or cs == "ANY" or self.data.cs == "ANY" then -- no conversion needed
		return self.data

	-- TODO: in-place conversion may lead to data degradation after multiple conversions
	elseif checkSingleCS(self.portOut) and cs~="Y" and cs ~="L" then -- optimize when all outputs have the same CS
		local newData = convert(self.data, self.data, cs)
		self.data = newData
		return newData

	else
		local newData = self.dataCS[cs]
		if not newData then
			newData = convert(self.data, newData, cs)
		end
		self.dataCS[cs] = newData
		return newData
	end
end

function link:resizeData(x, y, z)
	self.data = link._resize(self.data, x, y, z)
	return self.data
end

function link:setData(cs, dev)
	local data = self.data
	cs = cs or data.cs
	data.cs = cs

	self.dataCS = {}

	return data
end

function link:cleanData()
	local keep = {}

	for k, v in pairs(self.portOut) do
		if k.parent.state then -- check only active nodes
			keep[k.cs] = true
		end
	end

	if self.data then
		keep[self.data.cs] = false
	end

	for k in pairs(self.dataCS) do
		if not keep[k] then
			self.dataCS[k]:free()
			self.dataCS[k] = nil
		end
	end
end

return link
