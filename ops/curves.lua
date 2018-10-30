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

local background_LL = love.graphics.newImage("res/Curve_LL.png")
local background_LC = love.graphics.newImage("res/Curve_LC.png")
local background_LH = love.graphics.newImage("res/Curve_LH.png")
local background_CL = love.graphics.newImage("res/Curve_CL.png")
local background_CC = love.graphics.newImage("res/Curve_CC.png")
local background_CH = love.graphics.newImage("res/Curve_CH.png")
local background_HL = love.graphics.newImage("res/Curve_HL.png")
local background_HC = love.graphics.newImage("res/Curve_HC.png")
local background_HH = love.graphics.newImage("res/Curve_HH.png")

local node = require "ui.node"
local data = require "data"
local thread = require "thread"

local t = require "ops.tools"

return function(ops)

	local function curveLLProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:toDevice()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveLL({i, c, o}, self)
	end

	function ops.curveLL(x, y)
		local n = node:new("Curve L-L")
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
		c = self.data.curve:toDevice()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveLC({i, c, o}, self)
	end

	function ops.curveLC(x, y)
		local n = node:new("Curve L-C")
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "LCH")
		n.process = curveLCProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, {{x = 0, y = 0.5}, {x = 1, y = 0.5}})
		n.graph.background = background_LC
		n:setPos(x, y)
		return n
	end

	local function curveLHProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:toDevice()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveLH({i, c, o}, self)
	end

	function ops.curveLH(x, y)
		local n = node:new("Curve L-H")
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "LCH")
		n.process = curveLHProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, {{x = 0, y = 0.5}, {x = 1, y = 0.5}})
		n.graph.background = background_LH
		n:setPos(x, y)
		return n
	end


	local function curveCLProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:toDevice()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveCL({i, c, o}, self)
	end

	function ops.curveCL(x, y)
		local n = node:new("Curve C-L")
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "LCH")
		n.process = curveCLProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, {{x = 0, y = 0.5}, {x = 1, y = 0.5}})
		n.graph.background = background_CL
		n:setPos(x, y)
		return n
	end

	local function curveCCProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:toDevice()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveCC({i, c, o}, self)
	end

	function ops.curveCC(x, y)
		local n = node:new("Curve C-C")
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
		c = self.data.curve:toDevice()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveCH({i, c, o}, self)
	end

	function ops.curveCH(x, y)
		local n = node:new("Curve C-H")
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "LCH")
		n.process = curveCHProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, {{x = 0, y = 0.5}, {x = 1, y = 0.5}})
		n.graph.background = background_CH
		n:setPos(x, y)
		return n
	end


	local function curveHLProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:toDevice()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveHL({i, c, o}, self)
	end

	function ops.curveHL(x, y)
		local n = node:new("Curve H-L")
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "LCH")
		n.process = curveHLProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, {{x = 0, y = 0.5}, {x = 1, y = 0.5}})
		n.graph.background = background_HL
		n:setPos(x, y)
		return n
	end

	local function curveHCProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:toDevice()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveHC({i, c, o}, self)
	end

	function ops.curveHC(x, y)
		local n = node:new("Curve H-C")
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "LCH")
		n.process = curveHCProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, {{x = 0, y = 0.5}, {x = 1, y = 0.5}})
		n.graph.background = background_HC
		n:setPos(x, y)
		return n
	end

	local function curveHHProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:toDevice()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveHH({i, c, o}, self)
	end

	function ops.curveHH(x, y)
		local n = node:new("Curve H-H")
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "LCH")
		n.process = curveHHProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, {{x = 0, y = 0.5}, {x = 1, y = 0.5}})
		n.graph.background = background_HH
		n:setPos(x, y)
		return n
	end


	local function curveMapProcess(self)
		self.procType = "dev"
		local i, c, r, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:toDevice()
		r = t.plainParam(self, 1)
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveGenericMap({i, c, r, o}, self)
	end

	function ops.curveMap(x, y)
		local n = node:new("Curve Map")
		n:addPortIn(0, "Y")
		n:addPortOut(0, "Y")
		n:addElem("bool", 1, "Input Range [-1, 1]")
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
		c = self.data.curve:toDevice()
		r = t.plainParam(self, 2)
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveGenericOffset({i, d, c, r, o}, self)
	end

	function ops.curveOffset(x, y)
		local n = node:new("Curve Offset")
		n:addPortIn(0, "Y")
		n:addPortOut(0, "Y")
		n:addPortIn(1, "Y"):addElem("text", 1, "Offset Driver")
		n:addElem("bool", 2, "Driver Range [-1, 1]")
		n.process = curveOffsetProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, {{x = 0, y = 0.5}, {x = 1, y = 0.5}})
		n:setPos(x, y)
		return n
	end

	local function curveModulateProcess(self)
		self.procType = "dev"
		local i, d, c, r, o
		i = t.inputSourceBlack(self, 0)
		d = t.inputSourceBlack(self, 1)
		c = self.data.curve:toDevice()
		r = t.plainParam(self, 2)
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.curveGenericModulate({i, d, c, r, o}, self)
	end

	function ops.curveModulate(x, y)
		local n = node:new("Curve Modulate")
		n:addPortIn(0, "Y")
		n:addPortOut(0, "Y")
		n:addPortIn(1, "Y"):addElem("text", 1, "Modulate Driver")
		n:addElem("bool", 2, "Driver Range [-1, 1]")
		n.process = curveModulateProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, {{x = 0, y = 0.5}, {x = 1, y = 0.5}})
		n:setPos(x, y)
		return n
	end



	local function selectHProcess(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve:toDevice()
		o = t.autoOutput(self, 0, i:shape())
		thread.ops.selectH({i, c, o}, self)
	end

	function ops.selectH(x, y)
		local n = node:new("Select H")
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "Y")
		n.process = selectHProcess
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n, {{x = 0, y = 1}, {x = 1, y = 1}})
		n:setPos(x, y)
		return n
	end




	local function curveL__Process(self)
		self.procType = "dev"
		local i, c, a, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve
		a = t.plainParam(self, 1)
		c:toDevice()
		o = t.autoOutput(self, 0, i:shape())
		o.cs = i.cs
		thread.ops.curveL__({i, c, a, o}, self)
	end

	function ops.curveL__(x, y)
		local n = node:new("Curve L")
		n:addPortIn(0, "L__")
		n:addPortOut(0)
		n:addElem("bool", 1, "Preserve Saturation", true)
		n.process = curveL__Process
		n.data.curve = data:new(256, 1, 1)
		require "ui.graph".curve(n)
		n:setPos(x, y)
		return n
	end

	local function curveY__Process(self)
		self.procType = "dev"
		local i, c, o
		i = t.inputSourceBlack(self, 0)
		c = self.data.curve
		c:toDevice()
		o = t.autoOutput(self, 0, i:shape())
		o.cs = i.cs
		thread.ops.curveY__({i, c, o}, self)
		if self.elem[1].value and i.cs == "LRGB" then
			thread.ops.setHue({o, i, o}, self) -- TODO: integrate in main process avoiding memory overhead
			o.cs = "LCH"
		end
	end

	function ops.curveY__(x, y)
		local n = node:new("Curve Y")
		n:addPortIn(0, "Y__")
		n:addPortOut(0)
		n:addElem("bool", 1, "Preserve Hue", true)
		n.process = curveY__Process
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
		c:toDevice()
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
