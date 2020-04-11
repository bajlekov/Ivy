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

local background_LL = love.graphics.newImage("res/Curve_LL.png")
local background_LC = love.graphics.newImage("res/Curve_LC.png")
local background_LH = love.graphics.newImage("res/Curve_LH.png")
local background_CL = love.graphics.newImage("res/Curve_CL.png")
local background_CC = love.graphics.newImage("res/Curve_CC.png")
local background_CH = love.graphics.newImage("res/Curve_CH.png")
local background_HL = love.graphics.newImage("res/Curve_HL.png")
local background_HC = love.graphics.newImage("res/Curve_HC.png")
local background_HH = love.graphics.newImage("res/Curve_HH.png")

local background_L = love.graphics.newImage("res/Curve_L.png")
local background_C = love.graphics.newImage("res/Curve_C.png")
local background_H = love.graphics.newImage("res/Curve_H.png")
local background_A = love.graphics.newImage("res/Curve_A.png")
local background_B = love.graphics.newImage("res/Curve_B.png")

local node = require "ui.node"
local data = require "data"
local thread = require "thread"

local t = require "ops.tools"

return function(ops)

	local function curveLLProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:hostWritten():syncDev()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveLL({i, c, o}, self)
	end

	function ops.curveLL(x, y)
		local n = node:new("Curve L(L)")
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "LCH")
		n.process = curveLLProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n)
		n.graph.background = background_LL
		n:setPos(x, y)
		return n
	end

	local function curveLCProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:hostWritten():syncDev()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveLC({i, c, o}, self)
	end

	function ops.curveLC(x, y)
		local n = node:new("Curve C(L)")
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "LCH")
		n.process = curveLCProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, 0.5, 0.5)
		n.graph.background = background_LC
		n:setPos(x, y)
		return n
	end

	local function curveLHProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:hostWritten():syncDev()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveLH({i, c, o}, self)
	end

	function ops.curveLH(x, y)
		local n = node:new("Curve H(L)")
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "LCH")
		n.process = curveLHProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, 0.5, 0.5)
		n.graph.background = background_LH
		n:setPos(x, y)
		return n
	end


	local function curveCLProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:hostWritten():syncDev()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveCL({i, c, o}, self)
	end

	function ops.curveCL(x, y)
		local n = node:new("Curve L(C)")
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "LCH")
		n.process = curveCLProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, 0.5, 0.5)
		n.graph.background = background_CL
		n:setPos(x, y)
		return n
	end

	local function curveCCProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:hostWritten():syncDev()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveCC({i, c, o}, self)
	end

	function ops.curveCC(x, y)
		local n = node:new("Curve C(C)")
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "LCH")
		n.process = curveCCProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n)
		n.graph.background = background_CC
		n:setPos(x, y)
		return n
	end

	local function curveCHProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:hostWritten():syncDev()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveCH({i, c, o}, self)
	end

	function ops.curveCH(x, y)
		local n = node:new("Curve H(C)")
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "LCH")
		n.process = curveCHProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, 0.5, 0.5)
		n.graph.background = background_CH
		n:setPos(x, y)
		return n
	end


	local function curveHLProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:hostWritten():syncDev()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveHL({i, c, o}, self)
	end

	function ops.curveHL(x, y)
		local n = node:new("Curve L(H)")
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "LCH")
		n.process = curveHLProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, 0.5, 0.5)
		n.graph.background = background_HL
		n:setPos(x, y)
		return n
	end

	local function curveHCProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:hostWritten():syncDev()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveHC({i, c, o}, self)
	end

	function ops.curveHC(x, y)
		local n = node:new("Curve C(H)")
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "LCH")
		n.process = curveHCProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, 0.5, 0.5)
		n.graph.background = background_HC
		n:setPos(x, y)
		return n
	end

	local function curveHHProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:hostWritten():syncDev()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveHH({i, c, o}, self)
	end

	function ops.curveHH(x, y)
		local n = node:new("Curve H(H)")
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "LCH")
		n.process = curveHHProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, 0.5, 0.5)
		n.graph.background = background_HH
		n:setPos(x, y)
		return n
	end


	local function curveMapProcess(self)
		self.procType = "dev"
		local i, c, r, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:hostWritten():syncDev()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveGenericMap({i, c, o}, self)
	end

	function ops.curveMap(x, y)
		local n = node:new("Curve Map")
		n:addPortIn(0, "Y")
		n:addPortOut(0, "Y")
		n.process = curveMapProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n)
		n:setPos(x, y)
		return n
	end

	local function curveOffsetProcess(self)
		self.procType = "dev"
		local i, d, c, r, o
		i = t.inputSourceBlack(self, 0)
		d = t.inputSourceBlack(self, 1)
		c = self.data.curve:hostWritten():syncDev()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveGenericOffset({i, d, c, o}, self)
	end

	function ops.curveOffset(x, y)
		local n = node:new("Curve Offset")
		n:addPortIn(0, "Y")
		n:addPortOut(0, "Y")
		n:addPortIn(1, "Y"):addElem("text", 1, "Offset Driver")
		n.process = curveOffsetProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, 0.5, 0.5)
		n:setPos(x, y)
		return n
	end

	local function curveModulateProcess(self)
		self.procType = "dev"
		local i, d, c, r, o
		i = t.inputSourceBlack(self, 0)
		d = t.inputSourceBlack(self, 1)
		c = self.data.curve:hostWritten():syncDev()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveGenericModulate({i, d, c, o}, self)
	end

	function ops.curveModulate(x, y)
		local n = node:new("Curve Modulate")
		n:addPortIn(0, "Y")
		n:addPortOut(0, "Y")
		n:addPortIn(1, "Y"):addElem("text", 1, "Modulate Driver")
		n.process = curveModulateProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, 0.5, 0.5)
		n:setPos(x, y)
		return n
	end



	local function hueMaskProcess(self)
		self.procType = "dev"
		local i, c, p, o
		i = t.inputSourceBlack(self, 0)
		p = t.plainParam(self, 1)
		c = self.data.curve:hostWritten():syncDev()
		local x, y, z = i:shape()
		o = t.autoOutput(self, 0, x, y, 1)
		thread.ops.hueMask({i, c, p, o}, self)
	end

	function ops.hueMask(x, y)
		local n = node:new("Hue Mask")
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "Y")
		n:addElem("bool", 1, "Chroma modulation", true)
		n.process = hueMaskProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, 1, 1)
		n.graph.background = background_H
		n:setPos(x, y)
		return n
	end

	local function lightnessMaskProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:hostWritten():syncDev()
		local x, y, z = i:shape()
		o = t.autoOutput(self, 0, x, y, 1)
		thread.ops.lightnessMask({i, c, o}, self)
	end

	function ops.lightnessMask(x, y)
		local n = node:new("Lightness Mask")
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "Y")
		n.process = lightnessMaskProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, 1, 1)
		n.graph.background = background_L
		n:setPos(x, y)
		return n
	end


	local function chromaMaskProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:hostWritten():syncDev()
		local x, y, z = i:shape()
		o = t.autoOutput(self, 0, x, y, 1)
		thread.ops.chromaMask({i, c, o}, self)
	end

	function ops.chromaMask(x, y)
		local n = node:new("Chroma Mask")
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "Y")
		n.process = chromaMaskProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, 1, 1)
		n.graph.background = background_C
		n:setPos(x, y)
		return n
	end


	local function blueYellowMaskProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:hostWritten():syncDev()
		local x, y, z = i:shape()
		o = t.autoOutput(self, 0, x, y, 1)
		thread.ops.blueYellowMask({i, c, o}, self)
	end

	function ops.blueYellowMask(x, y)
		local n = node:new("Blue-Yellow Mask")
		n:addPortIn(0, "LAB")
		n:addPortOut(0, "Y")
		n.process = blueYellowMaskProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, 1, 1)
		n.graph.background = background_B
		n:setPos(x, y)
		return n
	end


	local function greenRedMaskProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:hostWritten():syncDev()
		local x, y, z = i:shape()
		o = t.autoOutput(self, 0, x, y, 1)
		thread.ops.greenRedMask({i, c, o}, self)
	end

	function ops.greenRedMask(x, y)
		local n = node:new("Green-Red Mask")
		n:addPortIn(0, "LAB")
		n:addPortOut(0, "Y")
		n.process = greenRedMaskProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, 1, 1)
		n.graph.background = background_A
		n:setPos(x, y)
		return n
	end



	local function curveYProcess(self)
		self.procType = "dev"
		local i, c, l, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve
		c:hostWritten():syncDev()
		l = t.plainParam(self, 1)
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveY({i, c, l, o}, self)
	end

	function ops.curveY(x, y)
		local n = node:new("Curve Y")
		n:addPortIn(0, "XYZ")
		n:addPortOut(0, "XYZ")
		n:addElem("bool", 1, "Perceptual", true)
		n.process = curveYProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n)
		n:setPos(x, y)
		return n
	end

	local function curveRGBProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve
		c:hostWritten():syncDev()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveRGB({i, c, o}, self)
	end

	function ops.curveRGB(x, y)
		local n = node:new("Curve RGB")
		n:addPortIn(0, "LRGB")
		n:addPortOut(0, "LRGB")
		n.data.curve = data:new(256, 1, 3)

		require "ui.graph".curveRGB(n)

		local r = n:addElem("bool", 1, "Red", true)
		local g = n:addElem("bool", 2, "Green")
		local b = n:addElem("bool", 3, "Blue")
		local exclusive = {r, g, b}
		r.exclusive = exclusive
		g.exclusive = exclusive
		b.exclusive = exclusive

		r.action = n.graph.setR
		g.action = n.graph.setG
		b.action = n.graph.setB

		n.process = curveRGBProcess
		n:setPos(x, y)
		return n
	end

end
