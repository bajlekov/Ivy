--[[
	Copyright (C) 2011-2020 G. Bajlekov

		Ivy is free software: you can redistribute it and/or modify
		it under the terms of the GNU General Public License as published by
		the Free Software Foundation, either version 3 of the License, or
		(at your option) any later version.

		Ivy is distributed in the hope that it will be useful,
		but WITHOUT ANY WARRANTY; without even the implied warranty of
		MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
		GNU General Public License for more details.

		You should have received a copy of the GNU General Public License
		along with this program.	If not, see <http://www.gnu.org/licenses/>.
]]

local wp_x = 0.95042854537718
local wp_y = 1
local wp_z = 1.0889003707981
local E = 216/24389
local K = 24389/27

local function xyz(V)
	if V^3>E then
		return V^3
	else
		return (116*V - 16)/K
	end
end

local function LAB_XYZ(l, a, b)
	local x, y, z
	y = (l + 0.16)/1.16
	x = a*0.2 + y
	z = y - b*0.5
	x = wp_x*xyz(x)
	y = wp_y*xyz(y)
	z = wp_z*xyz(z)
	return x, y, z
end

local M_1 = {
	 3.2404542, -1.5371385, -0.4985314,
	-0.9692660,	1.8760108,	0.0415560,
	 0.0556434, -0.2040259,	1.0572252,
}

local function XYZ_LRGB(x, y, z)
	local r, g, b
	r = x*M_1[1] + y*M_1[2] + z*M_1[3]
	g = x*M_1[4] + y*M_1[5] + z*M_1[6]
	b = x*M_1[7] + y*M_1[8] + z*M_1[9]
	return r, g, b
end


local node = require "ui.node"
local data = require "data"
local thread = require "thread"

local t = require "ops.tools"

return function(ops)

	local function liftProcess(self)
		self.procType = "dev"
		local i = t.inputSourceBlack(self, 0)
		local p = t.autoTempBuffer(self, -1, 1, 1, 3)
		local x, y, z = i:shape()
		local o = t.autoOutput(self, 0, x, y, 3)

		local r, g, b = XYZ_LRGB(LAB_XYZ(0.75, self.graph.x*0.1, self.graph.y*0.1))
		local m = self.elem[1].value - (0.2126729*r + 0.7151522*g + 0.0721750*b)
		p:set(0, 0, 0, r + m)
		p:set(0, 0, 1, g + m)
		p:set(0, 0, 2, b + m)
		p:syncDev()

		thread.ops.color_lift({i, p, o}, self)
	end

	function ops.color_lift(x, y)
		local n = node:new("Lift")
		n:addPortIn(0, "LRGB")
		n:addPortOut(0, "LRGB")
		n:addElem("float", 1, "Lift", -0.25, 0.25, 0)

		require "ui.graph".colorwheel(n)
		n.process = liftProcess

		n.w = 100
		n:setPos(x, y)
		return n
	end


	local function gainProcess(self)
		self.procType = "dev"
		local i = t.inputSourceBlack(self, 0)
		local p = t.autoTempBuffer(self, -1, 1, 1, 3)
		local x, y, z = i:shape()
		local o = t.autoOutput(self, 0, x, y, 3)

		local r, g, b = XYZ_LRGB(LAB_XYZ(0.75, self.graph.x*0.5, self.graph.y*0.5))
		local m = self.elem[1].value - (0.2126729*r + 0.7151522*g + 0.0721750*b)
		p:set(0, 0, 0, r + m)
		p:set(0, 0, 1, g + m)
		p:set(0, 0, 2, b + m)
		p:syncDev()

		thread.ops.color_gain({i, p, o}, self)
	end

	function ops.color_gain(x, y)
		local n = node:new("Gain")
		n:addPortIn(0, "LRGB")
		n:addPortOut(0, "LRGB")
		n:addElem("float", 1, "Gain", 0.5, 1.5, 1)

		require "ui.graph".colorwheel(n)
		n.process = gainProcess

		n.w = 100
		n:setPos(x, y)
		return n
	end

	local function gammaProcess(self)
		self.procType = "dev"
		local i = t.inputSourceBlack(self, 0)
		local p = t.autoTempBuffer(self, -1, 1, 1, 3)
		local x, y, z = i:shape()
		local o = t.autoOutput(self, 0, x, y, 3)

		local r, g, b = XYZ_LRGB(LAB_XYZ(0.75, self.graph.x*0.2, self.graph.y*0.2))
		local m = self.elem[1].value - (0.2126729*r + 0.7151522*g + 0.0721750*b)
		p:set(0, 0, 0, r + m)
		p:set(0, 0, 1, g + m)
		p:set(0, 0, 2, b + m)
		p:syncDev()

		thread.ops.color_gamma({i, p, o}, self)
	end

	function ops.color_gamma(x, y)
		local n = node:new("Gamma")
		n:addPortIn(0, "LRGB")
		n:addPortOut(0, "LRGB")
		n:addElem("float", 1, "Gamma", 0.25, 0.75, 0.5)

		require "ui.graph".colorwheel(n)
		n.process = gammaProcess

		n.w = 100
		n:setPos(x, y)
		return n
	end


	local function offsetProcess(self)
		self.procType = "dev"
		local i = t.inputSourceBlack(self, 0)
		local p = t.autoTempBuffer(self, -1, 1, 1, 3)
		local x, y, z = i:shape()
		local o = t.autoOutput(self, 0, x, y, 3)

		local r, g, b = XYZ_LRGB(LAB_XYZ(0.75, self.graph.x*0.1, self.graph.y*0.1))
		local m = self.elem[1].value - (0.2126729*r + 0.7151522*g + 0.0721750*b)
		p:set(0, 0, 0, r + m)
		p:set(0, 0, 1, g + m)
		p:set(0, 0, 2, b + m)
		p:syncDev()

		thread.ops.color_offset({i, p, o}, self)
	end

	function ops.color_offset(x, y)
		local n = node:new("Offset")
		n:addPortIn(0, "LRGB")
		n:addPortOut(0, "LRGB")
		n:addElem("float", 1, "Offset", -0.25, 0.25, 0)

		require "ui.graph".colorwheel(n)
		n.process = offsetProcess

		n.w = 100
		n:setPos(x, y)
		return n
	end



	local function shadowsProcess(self)
		self.procType = "dev"
		local i = t.inputSourceBlack(self, 0)
		local p = t.autoTempBuffer(self, -1, 1, 1, 3)
		local x, y, z = i:shape()
		local o = t.autoOutput(self, 0, x, y, 3)

		local r, g, b = XYZ_LRGB(LAB_XYZ(0.75, self.graph.x*0.1, self.graph.y*0.1))
		local m = self.elem[1].value - (0.2126729*r + 0.7151522*g + 0.0721750*b)
		p:set(0, 0, 0, r + m)
		p:set(0, 0, 1, g + m)
		p:set(0, 0, 2, b + m)
		p:syncDev()

		thread.ops.color_shadows({i, p, o}, self)
	end

	function ops.color_shadows(x, y)
		local n = node:new("Shadows")
		n:addPortIn(0, "LRGB")
		n:addPortOut(0, "LRGB")
		n:addElem("float", 1, "Shadows", -0.25, 0.25, 0)

		require "ui.graph".colorwheel(n)
		n.process = shadowsProcess

		n.w = 100
		n:setPos(x, y)
		return n
	end


	local function midtonesProcess(self)
		self.procType = "dev"
		local i = t.inputSourceBlack(self, 0)
		local p = t.autoTempBuffer(self, -1, 1, 1, 3)
		local x, y, z = i:shape()
		local o = t.autoOutput(self, 0, x, y, 3)

		local r, g, b = XYZ_LRGB(LAB_XYZ(0.75, self.graph.x*0.1, self.graph.y*0.1))
		local m = self.elem[1].value - (0.2126729*r + 0.7151522*g + 0.0721750*b)
		p:set(0, 0, 0, r + m)
		p:set(0, 0, 1, g + m)
		p:set(0, 0, 2, b + m)
		p:syncDev()

		thread.ops.color_midtones({i, p, o}, self)
	end

	function ops.color_midtones(x, y)
		local n = node:new("Midtones")
		n:addPortIn(0, "LRGB")
		n:addPortOut(0, "LRGB")
		n:addElem("float", 1, "Midtones", -0.25, 0.25, 0)

		require "ui.graph".colorwheel(n)
		n.process = midtonesProcess

		n.w = 100
		n:setPos(x, y)
		return n
	end


	local function highlightsProcess(self)
		self.procType = "dev"
		local i = t.inputSourceBlack(self, 0)
		local p = t.autoTempBuffer(self, -1, 1, 1, 3)
		local x, y, z = i:shape()
		local o = t.autoOutput(self, 0, x, y, 3)

		local r, g, b = XYZ_LRGB(LAB_XYZ(0.75, self.graph.x*0.1, self.graph.y*0.1))
		local m = self.elem[1].value - (0.2126729*r + 0.7151522*g + 0.0721750*b)
		p:set(0, 0, 0, r + m)
		p:set(0, 0, 1, g + m)
		p:set(0, 0, 2, b + m)
		p:syncDev()

		thread.ops.color_highlights({i, p, o}, self)
	end

	function ops.color_highlights(x, y)
		local n = node:new("Highlights")
		n:addPortIn(0, "LRGB")
		n:addPortOut(0, "LRGB")
		n:addElem("float", 1, "Highlights", -0.25, 0.25, 0)

		require "ui.graph".colorwheel(n)
		n.process = highlightsProcess

		n.w = 100
		n:setPos(x, y)
		return n
	end


	local function transferProcess(self)
		self.procType = "dev"
		assert(self.portOut[0].link)
		local I, C, O
		I = t.inputSourceBlack(self, 0)
		C = t.inputSourceWhite(self, 1)
		O = t.autoOutput(self, 0, data.superSize(I, C))
		thread.ops.colorTransfer({I, C, O}, self)
	end

	function ops.colorTransfer(x, y)
		local n = node:new("Color Transfer")
		n:addPortIn(0, "Y")
		n:addPortIn(1, "XYZ"):addElem("text", 1, "Color")
		n:addPortOut(0, "XYZ")
		n.process = transferProcess
		n:setPos(x, y)
		return n
	end


end
