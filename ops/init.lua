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

-- define nodes
local node = require "ui.node"
local data = require "data"
local thread = require "thread"

local t = require "ops.tools"

local ops = {}

require "ops.adjust"(ops)
require "ops.curves"(ops)
require "ops.select"(ops)
require "ops.color"(ops)
require "ops.script"(ops)

-- list of ops + menu entries
t.register(ops, "contrast")
t.register(ops, "bilateral")
t.register(ops, "custom2D")
t.register(ops, "split_lr")
t.register(ops, "split_ud")

t.imageShapeSet(1, 1, 1)

local function inputProcess(self)
	local link = self.portOut[0].link
	link.data = self.imageData
	link:setData() -- cleans up CS buffers in link
	self.state = "ready"
end

function ops.input(x, y, img)
	local n = node:new("Input")
	n:addPortOut(0)
	n.image = img
	n.process = inputProcess
	n.protected = true
	n.w = 75
	n:setPos(x, y)
	n.dirty = false
	return n
end


local function cctProcess(self)
	self.procType = "par"
	local o = t.autoOutput(self, 0, 1, 1, 3)
	local X, Y, Z = require "tools.cct"(self.elem[1].value)
	print(X, Y, Z)
	o:set(0, 0, 0, X)
	o:set(0, 0, 1, Y)
	o:set(0, 0, 2, Z)
end

function ops.cct(x, y)
	local n = node:new("CCT")
	n:addPortOut(0, "XYZ")
	n:addElem("float", 1, "Temp.", 2000, 15000, 6500)
	n.process = cctProcess
	n:setPos(x, y)
	return n
end

local cct = require "tools.cct"

local function temperatureProcess(self)
	self.procType = "dev"
	local i = t.inputSourceBlack(self, 0)
	local p = t.autoTempBuffer(self, 1, 1, 1, 3)
	local o = t.autoOutput(self, 0, i:shape())

	local Li, Mi, Si = cct(self.elem[1].value, self.elem[2].value)
	local Lo, Mo, So = cct(6500)
	print(Lo/Li, Mo/Mi, So/Si)
	p:set(0, 0, 0, Lo / Li)
	p:set(0, 0, 1, Mo / Mi)
	p:set(0, 0, 2, So / Si)
	p:toDevice()
	thread.ops.temperature({i, p, o}, self)
end

function ops.temperature(x, y)
	local n = node:new("Temperature")
	n:addPortIn(0, "XYZ")
	n:addPortOut(0, "XYZ")
	n:addElem("float", 1, "CCT (K)", 2000, 22000, 6500)
	n:addElem("float", 2, "Tint", 0.75, 1.25, 1)
	n.process = temperatureProcess
	n:setPos(x, y)
	return n
end


local function xyProcess(self)
	local bi = t.inputSourceBlack(self, 1)
	local wi = t.inputSourceWhite(self, 2)

	local x, y, z = data.superSize(bi, wi)
	local _x, _y = t.imageShape()
	if x == 1 then x = _x end
	if y == 1 then y = _y end
	local xo = t.autoOutputSink(self, 1, x, y, z)
	local yo = t.autoOutputSink(self, 2, x, y, z)
	xo.cs = t.optCSsuperset(bi, wi)
	yo.cs = xo.cs
	thread.ops.xy({bi, wi, xo, yo}, self)
end

function ops.xy(x, y)
	local n = node:new("X-Y")
	n:addPortIn(1, "Y__"):addPortOut(1):addElem("text", 1, "Black", "X")
	n:addPortIn(2, "Y__"):addPortOut(2):addElem("text", 2, "White", "Y")
	n.process = xyProcess
	n:setPos(x, y)
	return n
end

local function radialProcess(self)
	local x = t.inputParam(self, 1)
	local y = t.inputParam(self, 2)

	local sx, sy = t.imageShape()
	local o = t.autoOutputSink(self, 0, sx, sy, 1)

	thread.ops.radial({x, y, o}, self)
end

function ops.radial(x, y)
	local n = node:new("Radial")
	n:addPortOut(0)
	n:addPortIn(1, "Y"):addElem("float", 1, "X", 0, 1, 0.5)
	n:addPortIn(2, "Y"):addElem("float", 2, "Y", 0, 1, 0.5)
	n.process = radialProcess
	n:setPos(x, y)
	return n
end

local function linearProcess(self)
	local x = t.inputParam(self, 1)
	local y = t.inputParam(self, 2)
	local theta = t.inputParam(self, 3)

	local sx, sy = t.imageShape()
	local o = t.autoOutputSink(self, 0, sx, sy, 1)

	thread.ops.linear({x, y, theta, o}, self)
end

function ops.linear(x, y)
	local n = node:new("Linear")
	n:addPortOut(0)
	n:addPortIn(1, "Y"):addElem("float", 1, "X", 0, 1, 0.5)
	n:addPortIn(2, "Y"):addElem("float", 2, "Y", 0, 1, 0.5)
	n:addPortIn(3, "Y"):addElem("float", 3, "θ", -1, 1, 0)
	n.process = linearProcess
	n:setPos(x, y)
	return n
end

local function mirroredProcess(self)
	local x = t.inputParam(self, 1)
	local y = t.inputParam(self, 2)
	local theta = t.inputParam(self, 3)

	local sx, sy = t.imageShape()
	local o = t.autoOutputSink(self, 0, sx, sy, 1)

	thread.ops.mirrored({x, y, theta, o}, self)
end

function ops.mirrored(x, y)
	local n = node:new("Mirrored")
	n:addPortOut(0)
	n:addPortIn(1, "Y"):addElem("float", 1, "X", 0, 1, 0.5)
	n:addPortIn(2, "Y"):addElem("float", 2, "Y", 0, 1, 0.5)
	n:addPortIn(3, "Y"):addElem("float", 3, "θ", -1, 1, 0)
	n.process = mirroredProcess
	n:setPos(x, y)
	return n
end


local function outputProcess(self)
	self.procType = "dev"
	local p1 = t.inputSourceBlack(self, 0)
	local g = t.plainParam(self, 2)
	local h = self.data.histogram -- pre-allocated
	if self.elem[1].value then
		thread.ops.display_histogram({p1, self.image, g, h}, self)
	else
		thread.ops.display({p1, self.image, g}, self)
	end
end

function ops.output(x, y, img)
	local n = node:new("Output")
	n:addPortIn(0, "ANY")
	n:addElem("bool", 1, "Histogram", true)
	n:addElem("bool", 2, "Gamut clip", false)
	n.image = img
	n.process = outputProcess
	n.protected = true
	n.w = 75
	n:setPos(x, y)
	n.compute = true
	return n
end


--[[
local function rmseProcess(self)
	self.procType = "par"
	local a, b, t, o
	a = t.inputSourceBlack(self, 1)
	b = t.inputSourceBlack(self, 2)
	t = t.autoTempBuffer(self, 1, 1, 1, settings.nativeCoreCount)
	o = t.autoOutput(self, 0, 1, 1, 1)
	self.elem[3].right = string.format("%.5f", o:get(0, 0, 0))
	thread.ops.rmse({a, b, t, o}, self)
end

function ops.rmse(x, y)
	local n = node:new("RMSE")
	n:addPortIn(1):addElem("text", 1, "A")
	n:addPortIn(2):addElem("text", 2, "B")
	n:addPortOut(0)
	n:addElem("text", 3, "RMSE:", "-")
	n.process = rmseProcess
	n:setPos(x, y)
	return n
end

local function processTune(self)
	self.procType = "dev"
	local i1, i2, o, s
	s = t.inputSourceWhite(self, 3)
	print(s:get(0, 0, 0))
	local value
	if self.data.bestStat < s:get(0, 0, 0) or math.random() < 0.02 then
		value = self.data.bestValue
		value = value + (math.random() - 0.5) * self.elem[2].value
		value = math.min(math.max(value, self.elem[1].min), self.elem[1].max)
		self.elem[1].value = value
	else
		value = self.elem[1].value
		self.data.bestValue = value
		value = value + (math.random() - 0.5) * self.elem[2].value
		value = math.min(math.max(value, self.elem[1].min), self.elem[1].max)
		self.elem[1].value = value
		self.data.bestStat = s:get(0, 0, 0)
		self.elem[3].right = string.format("%.5f", self.data.bestStat)
	end

	self.elem[2].value = self.elem[2].value * 0.99
	i1 = t.inputSourceWhite(self, 0)
	i2 = t.plainParam(self, 1)
	o = t.autoOutput(self, 0, data.superSize(i1, i2))
	thread.ops.mul({i1, i2, o}, self)
end

ops.tune = function(x, y)
	local n = node:new("Tune")
	n.data.bestValue = 2
	n.data.bestStat = math.huge
	n:addPortIn(0)
	n:addElem("float", 1, "Factor", 0, 3, 2)
	n:addElem("float", 2, "Temp", 0, 1, 1)
	n:addPortIn(3):addElem("text", 3, "Stat")
	n:addElem("button", 4, "Reset", function() n.data.bestStat = math.huge n.elem[2].value = 0.5 end)
	n:addPortOut(0)
	n.process = processTune
	n:setPos(x, y)
	return n
end
--]]

local function processAutoWB(self)
	self.procType = "dev"
	local i = t.inputSourceBlack(self, 0)
	local o = t.autoOutputSink(self, 0, i:shape())

	local ox, oy, update = self.data.tweak.getCurrent()
	local p = t.autoTempBuffer(self, -1, 1, 1, 3) -- [x, y]
	local s = t.autoTempBuffer(self, -2, 1, 1, 3) -- [r, g, b]
	p:set(0, 0, 0, ox)
	p:set(0, 0, 1, oy)
	p:toDevice()

	if update or self.elem[2].value then
		thread.ops.colorSample5x5({i, p, s}, self)
	end

	thread.ops.autoWB({i, s, o}, self)
end

function ops.autoWB(x, y)
	local n = node:new("Sample WB")
	n.data.tweak = require "tools.tweak"()
	n:addPortIn(0, "LRGB")
	n:addPortOut(0, "LRGB")
	n.data.tweak.toolButton(n, 1, "Sample WB")
	n:addElem("bool", 2, "Resample pos.", false)
	n.process = processAutoWB

	local s = t.autoTempBuffer(n, -2, 1, 1, 3)
	s:set(0, 0, 0, 1)
	s:set(0, 0, 1, 1)
	s:set(0, 0, 2, 1)
	s:toDevice()

	n:setPos(x, y)
	return n
end



do
	local pool = require "tools.imagePool"

	local function processPaintMask(self)
		self.procType = "dev"
		local link = self.portOut[0].link

		if link then
			link.data = self.mask:get()
			link:setData("Y", self.procType)

			local i = t.inputSourceBlack(self, 6)

			local ox, oy = self.data.tweak.getOrigin()
			local cx, cy, update = self.data.tweak.getCurrent()
			local p = t.autoTempBuffer(self, -1, 1, 1, 10) -- [x, y, value, flow, size, fall-off, range, fall-off, sample x, sample y]

			local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
			local alt = love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")

			if update then
				p:set(0, 0, 0, cx)
				p:set(0, 0, 1, cy)
				p:set(0, 0, 2, ctrl and 0 or self.elem[2].value)
				p:set(0, 0, 3, self.elem[3].value)
				p:set(0, 0, 4, self.elem[4].value)
				p:set(0, 0, 5, self.elem[5].value)
				p:set(0, 0, 6, self.portIn[6].link and self.elem[6].value or -1) -- range -1: disabled
				p:set(0, 0, 7, self.elem[7].value)
				p:set(0, 0, 8, alt and ox or cx)
				p:set(0, 0, 9, alt and oy or cy)
				p:toDevice(true)

				thread.ops.paintSmart({link.data, i, p}, self)
			end
		end
	end

	function ops.paintMaskSmart(x, y)
		local n = node:new("Paint Mask")

		local sx, sy = t.imageShape()
		local mask = data:new(sx, sy, 1):toDevice()

		pool.resize(sx, sy)
		n.mask = pool.add(mask)

		n:addPortOut(0, "Y")
		n:addPortIn(6, "LAB")
		n.portIn[6].toggle = {[6] = true, [7] = true}

		n.data.tweak = require "tools.tweak"()
		n.data.tweak.toolButton(n, 1, "Paint")

		n:addElem("float", 2, "Value", 0, 1, 1)
		n:addElem("float", 3, "Flow", 0, 1, 1)
		n:addElem("float", 4, "Brush Size", 0, 500, 50)
		n:addElem("float", 5, "Fall-off", 0, 1, 0.5).last = true
		n:addElem("float", 6, "Smart Range", 0, 1, 0.1).first = true
		n:addElem("float", 7, "Fall-off", 0, 1, 0.5)

		n.process = processPaintMask
		n:setPos(x, y)
		return n
	end
end



local function detailEQProcess(self)
	self.procType = "dev"

	local i, p, o
	i = t.inputSourceBlack(self, 0)
	p = t.autoTempBuffer(self, 0, 8, 5, 1)
	for i = 1, 8 do -- TODO: move to graph ui so that it can be updated only when needed
		for j = 1, 5 do
			p:set(i-1, j-1, 0, self.graph.pts[j][i])
		end
	end
	p:toDevice()
	o = t.autoOutput(self, 0, i:shape())

	thread.ops.detailEQ({i, p, o}, self)
end

local background_EQ = love.graphics.newImage("res/detail_eq.png")

function ops.detailEQ(x, y)
	local n = node:new("Detail EQ")

	n:addPortIn(0, "LAB")
	n:addPortOut(0, "LAB")

	require "ui.graph".equalizer(n, 5)
	n.graph.pts[3] = {0, 0, 0, 0, 0, 0, 0, 0}
	n.graph.pts[4] = {0, 0, 0, 0, 0, 0, 0, 0}
	n.graph.default[3] = 0
	n.graph.default[4] = 0

	n.graph.background = background_EQ

	local bl = n:addElem("bool", 1, "Boost Lightness", true)
	local bc = n:addElem("bool", 2, "Boost Chroma")
	local tl = n:addElem("bool", 3, "Denoise Lightness")
	local tc = n:addElem("bool", 4, "Denoise Chroma")
	local s = n:addElem("bool", 5, "Sharpness")
	local exclusive = {bl, bc, tl, tc, s}
	bl.exclusive = exclusive
	bc.exclusive = exclusive
	tl.exclusive = exclusive
	tc.exclusive = exclusive
	s.exclusive = exclusive

	bl.action = function() n.graph.channel = 1 end
	bc.action = function() n.graph.channel = 2 end
	tl.action = function() n.graph.channel = 3 end
	tc.action = function() n.graph.channel = 4 end
	s.action = function() n.graph.channel = 5 end

	n.process = detailEQProcess
	n:setPos(x, y)
	return n
end


local function localLaplacianProcess(self)
	self.procType = "dev"
	local i = t.inputSourceWhite(self, 0)
	local d = t.inputParam(self, 1)
	local s = t.inputParam(self, 2)
	local h = t.inputParam(self, 3)
	local r = t.inputParam(self, 4)
	local o = t.autoOutput(self, 0, i:shape())

	thread.ops.localLaplacian({i, d, s, h, r, o}, self)
end

function ops.localLaplacian(x, y)
	local n = node:new("Detail")
	n:addPortIn(0, "LAB"):addPortOut(0, "LAB")
	n:addPortIn(1, "Y"):addElem("float", 1, "Detail", -1, 1, 0)
	n:addPortIn(2, "Y"):addElem("float", 2, "Shadows", -1, 1, 0)
	n:addPortIn(3, "Y"):addElem("float", 3, "Highlights", -1, 1, 0)
	n:addPortIn(4, "Y"):addElem("float", 4, "Range", 0, 1, 0.2)
	n.process = localLaplacianProcess
	n:setPos(x, y)
	return n
end



local function histogramProcess(self)
	self.procType = "dev"
	local i = t.inputSourceBlack(self, 0)
	local h = self.data.histogram -- pre-allocated
	thread.ops.histogram({i, h}, self)
end

function ops.histogram(x, y)
	local n = node:new("Histogram")
	n:addPortIn(0, "ANY")

	local overlayHistogram = require "ui.overlay":new()
	overlayHistogram:addElem("bool", 1, "Red", false)
	overlayHistogram:addElem("bool", 2, "Green", false)
	overlayHistogram:addElem("bool", 3, "Blue", false)
	overlayHistogram:addElem("bool", 4, "Lightness", true)
	overlayHistogram:addElem("button", 5, "OK")
	n:addElem("dropdown", 1, "Visibility", overlayHistogram)

	n.process = histogramProcess
	n.data.histogram = data:new(256, 1, 4):allocHost()
	n.compute = true
	require "ui.graph".histogram(n)
	n:setPos(x, y)
	return n
end

local function waveformProcess(self)
	self.proc = "dev"
	local i = t.inputSourceBlack(self, 0)
	local w = self.data.plot -- pre-allocated
	local s = t.plainParam(self, 2)
	local l = t.plainParam(self, 1)
	thread.ops.waveform({i, w, s, l}, self)
end

function ops.waveform(x, y)
	local n = node:new("Waveform")
	n:addPortIn(0, "ANY")
	n:addElem("bool", 1, "Lightness", false)
	n:addElem("float", 2, "Scale", 0, 3, 1)

	n.process = waveformProcess
	n.data.plot = require "ui.image":new(146, 146)
	require "ui.graph".plot(n)
	n.graph.grid.horizontal = true
	n.compute = true
	n:setPos(x, y)
	return n
end

local function ABplotProcess(self)
	self.proc = "dev"
	local i = t.inputSourceBlack(self, 0)
	local w = self.data.plot -- pre-allocated
	local s = t.plainParam(self, 2)
	local clip = t.plainParam(self, 1)
	thread.ops.ABplot({i, w, s, clip}, self)
end

function ops.ABplot(x, y)
	local n = node:new("AB Plot")
	n:addPortIn(0, "ANY")
	n:addElem("bool", 1, "Clip to sRGB", true)
	n:addElem("float", 2, "Scale", 0, 3, 1)

	n.process = ABplotProcess
	n.data.plot = require "ui.image":new(145, 145)
	require "ui.graph".plot(n)
	n.graph.grid.cross = true
	n.compute = true
	n:setPos(x, y)
	return n
end

local function histEQProcess(self)
	self.procType = "dev"
	local i = t.inputSourceBlack(self, 0)
	local h = self.data.histogram -- pre-allocated
	local o = t.autoOutput(self, 0, i:shape())
	thread.ops.histEQ({i, h, o}, self)
end

function ops.histEQ(x, y)
	local n = node:new("Histogram EQ")
	n:addPortIn(0, "LAB")
	n:addPortOut(0, "LAB")

	n.process = histEQProcess
	n.data.histogram = data:new(1024, 1, 1)

	n:setPos(x, y)
	return n
end


local function previewProcess(self)
	self.procType = "dev"

	local i = t.inputSourceBlack(self, 0)
	local w, h = i:shape()

	h = h==1 and 2 or math.floor(h / w * 150)
	if self.data.preview.y ~= h then
		self.data.preview = require "ui.image":new(150, h)
		self.graph.h = h
	end

	local p = self.data.preview -- pre-allocated
	thread.ops.preview({i, p}, self)
end

function ops.preview(x, y)
	local n = node:new("Preview")
	n:addPortIn(0, "ANY")
	n.process = previewProcess
	require "ui.graph".preview(n)
	local w, h = t.imageShape()
	h = math.floor(h / w * 150)
	n.data.preview = require "ui.image":new(150, h)
	n.graph.h = h
	n.compute = true
	n:setPos(x, y)
	return n
end


ops.stat = {}
do

	local function proc(self)
		self.procType = "dev"
		assert(self.portOut[0].link)
		local i, o
		i = t.inputSourceBlack(self, 0)
		o = t.autoOutput(self, 0, 1, 1, i.z)
		o.cs = i.cs
		thread.ops.stat_maximum({i, o}, self)
	end
	function ops.stat.maximum(x, y)
		local n = node:new("Maximum")
		n:addPortIn(0, "Y__")
		n:addPortOut(0)
		n.process = proc
		n.w = 75
		n:setPos(x, y)
		return n
	end

	local function proc(self)
		self.procType = "dev"
		assert(self.portOut[0].link)
		local i, o
		i = t.inputSourceBlack(self, 0)
		o = t.autoOutput(self, 0, 1, 1, i.z)
		o.cs = i.cs
		thread.ops.stat_minimum({i, o}, self)
	end
	function ops.stat.minimum(x, y)
		local n = node:new("Minimum")
		n:addPortIn(0, "Y__")
		n:addPortOut(0)
		n.process = proc
		n.w = 75
		n:setPos(x, y)
		return n
	end

	local function proc(self)
		self.procType = "dev"
		assert(self.portOut[0].link)
		local i, o
		i = t.inputSourceBlack(self, 0)
		o = t.autoOutput(self, 0, 1, 1, i.z)
		o.cs = i.cs
		thread.ops.stat_mean({i, o}, self)
	end
	function ops.stat.mean(x, y)
		local n = node:new("Mean")
		n:addPortIn(0, "Y__")
		n:addPortOut(0)
		n.process = proc
		n.w = 75
		n:setPos(x, y)
		return n
	end

	local function proc(self)
		self.procType = "dev"
		assert(self.portOut[1].link)
		local a, b, o
		a = t.inputSourceBlack(self, 1)
		b = t.inputSourceBlack(self, 2)
		local x, y, z = data.superSize(a, b)
		o = t.autoOutput(self, 1, 1, 1, z)
		o.cs = t.optCSsuperset(a, b)
		thread.ops.stat_sad({a, b, o}, self)
	end
	function ops.stat.SAD(x, y)
		local n = node:new("SAD")
		n:addPortIn(1, "Y__"):addElem("text", 1, "A", "∑|A-B| / N")
		n:addPortIn(2, "Y__"):addElem("text", 2, "B")
		n:addPortOut(1)
		n.process = proc
		n.w = 75
		n:setPos(x, y)
		return n
	end

	local function proc(self)
		self.procType = "dev"
		assert(self.portOut[1].link)
		local a, b, o
		a = t.inputSourceBlack(self, 1)
		b = t.inputSourceBlack(self, 2)
		local x, y, z = data.superSize(a, b)
		o = t.autoOutput(self, 1, 1, 1, z)
		o.cs = t.optCSsuperset(a, b)
		thread.ops.stat_ssd({a, b, o}, self)
	end
	function ops.stat.SSD(x, y)
		local n = node:new("SSD")
		n:addPortIn(1, "Y__"):addElem("text", 1, "A", "∑(A-B)² / N")
		n:addPortIn(2, "Y__"):addElem("text", 2, "B")
		n:addPortOut(1)
		n.process = proc
		n.w = 75
		n:setPos(x, y)
		return n
	end

end

local function exposureProcess(self)
	self.procType = "dev"
	assert(self.portOut[0].link)
	local i, e, o
	i = t.inputSourceBlack(self, 0)
	e = t.inputParam(self, 1)
	o = t.autoOutput(self, 0, data.superSize(i, v))
	o.cs = t.optCSsuperset(i, e)
	thread.ops.exposure({i, e, o}, self)
end

function ops.exposure(x, y)
	local n = node:new("Exposure")
	n:addPortIn(0, "Y__")
	n:addPortIn(1, "Y"):addElem("float", 1, "Exposure", -3.3333, 3.3333, 0)
	n:addPortOut(0)
	n.process = exposureProcess
	n:setPos(x, y)
	return n
end

local function brightnessProcess(self)
	self.procType = "dev"
	assert(self.portOut[0].link)
	local i, b, o
	i = t.inputSourceBlack(self, 0)
	b = t.inputParam(self, 1)
	o = t.autoOutput(self, 0, data.superSize(i, b))
	o.cs = t.optCSsuperset(i, b)
	thread.ops.brightness({i, b, o}, self)

	if i.cs == "LRGB" and self.elem[2].value then
		thread.ops.setHue({o, i, o}, self)
		o.cs = "LCH"
	end
end

function ops.brightness(x, y)
	local n = node:new("Brightness")
	n:addPortIn(0, "Y__")
	n:addPortIn(1, "Y"):addElem("float", 1, "Brightness", - 1, 1, 0)
	n:addElem("bool", 2, "Preserve Hue", true)
	n:addPortOut(0)
	n.process = brightnessProcess
	n:setPos(x, y)
	return n
end

local function vibranceProcess(self)
	self.procType = "dev"
	assert(self.portOut[0].link)
	local i, v, p, o
	i = t.inputSourceBlack(self, 0)
	v = t.inputParam(self, 1)
	p = t.plainParam(self, 2)
	o = t.autoOutput(self, 0, data.superSize(i, v))
	thread.ops.vibrance({i, v, p, o}, self)
end

function ops.vibrance(x, y)
	local n = node:new("Vibrance")
	n:addPortIn(0, "LCH")
	n:addPortIn(1, "Y"):addElem("float", 1, "Vibrance", - 1, 1, 0)
	n:addElem("bool", 2, "Adjust lightness", true)
	n:addPortOut(0, "LCH")
	n.process = vibranceProcess
	n:setPos(x, y)
	return n
end

local function saturationProcess(self)
	self.procType = "dev"
	assert(self.portOut[0].link)
	local i, v, o
	i = t.inputSourceBlack(self, 0)
	v = t.inputParam(self, 1)
	o = t.autoOutput(self, 0, data.superSize(i, v))
	thread.ops.saturation({i, v, o}, self)
end

function ops.saturation(x, y)
	local n = node:new("Saturation")
	n:addPortIn(0, "LCH")
	n:addPortIn(1, "Y"):addElem("float", 1, "Saturation", 0, 2, 1)
	n:addPortOut(0, "LCH")
	n.process = saturationProcess
	n:setPos(x, y)
	return n
end


local function levelsProcess(self)
	self.procType = "dev"
	assert(self.portOut[0].link)
	local i, bpi, wpi, g, bpo, wpo, o
	i = t.inputSourceBlack(self, 0)
	bpi = t.inputParam(self, 1)
	wpi = t.inputParam(self, 2)
	g = t.inputParam(self, 3)
	bpo = t.inputParam(self, 4)
	wpo = t.inputParam(self, 5)
	o = t.autoOutput(self, 0, data.superSize(i, bpi, wpi, g, bpo, wpo))
	o.cs = t.optCSsuperset(i, bpi, wpi, g, bpo, wpo)
	thread.ops.levels({i, bpi, wpi, g, bpo, wpo, o}, self)
end

function ops.levels(x, y)
	local n = node:new("Levels")
	n:addPortIn(0, "Y__")
	n:addPortOut(0)
	n:addPortIn(1, "Y__"):addElem("float", 1, "Black in", 0, 1, 0)
	n:addPortIn(2, "Y__"):addElem("float", 2, "White in", 0, 1, 1)
	n:addPortIn(3, "Y__"):addElem("float", 3, "Gamma", 0, 1, 0.5)
	n:addPortIn(4, "Y__"):addElem("float", 4, "Black out", 0, 1, 0)
	n:addPortIn(5, "Y__"):addElem("float", 5, "White out", 0, 1, 1)
	n.process = levelsProcess
	n:setPos(x, y)
	return n
end



local function mixProcess(self)
	self.procType = "dev"
	assert(self.portOut[0].link)
	local p1, p2, p3, p4
	p1 = t.inputParam(self, 1)
	p2 = t.inputParam(self, 2)
	p3 = t.inputParam(self, 3)
	p4 = t.autoOutput(self, 0, data.superSize(p1, p2, p3))
	p4.cs = t.optCSsuperset(p1, p2, p3)
	thread.ops.mix({p1, p2, p3, p4}, self)
end

function ops.mix(x, y)
	local n = node:new("Mix")
	n:addPortIn(1, "Y__"):addElem("float", 1, "A", 0, 1, 0)
	n:addPortIn(2, "Y__"):addElem("float", 2, "B", 0, 1, 0)
	n:addPortIn(3, "Y__"):addElem("float", 3, "Factor", 0, 1, 1)
	n:addPortOut(0)
	n.process = mixProcess
	n.w = 75
	n:setPos(x, y)
	return n
end



local function invertProcess(self)
	assert(self.portOut[0].link)
	local p1, p2
	p1 = t.inputSourceBlack(self, 0)
	p2 = t.autoOutput(self, 0, p1:shape())
	p2.cs = p1.cs
	thread.ops.invert({p1, p2}, self)
end

function ops.invert(x, y)
	local n = node:new("Invert")
	n:addPortIn(0, "Y__")
	n:addPortOut(0)
	n.process = invertProcess
	n:setPos(x, y)
	return n
end


--[[
local function smoothstepProcess(self)
	assert(self.portOut[0].link)
	local p1, p2
	p1 = t.inputSourceBlack(self, 0)
	p2 = t.autoOutput(self, 0, p1:shape())
	thread.ops.smoothstep({p1, p2}, self)
end

function ops.smoothstep(x, y)
	local n = node:new("Smoothstep")
	n:addPortIn(0)
	n:addPortOut(0)
	n.process = smoothstepProcess
	n:setPos(x, y)
	return n
end
--]]



local function gammaProcess(self)
	assert(self.portOut[0].link)
	local p1, p2, p3
	p1 = t.inputSourceBlack(self, 0)
	p2 = t.inputParam(self, 1)
	p3 = t.autoOutput(self, 0, data.superSize(p1, p2))
	p3.cs = t.optCSsuperset(p1, p2)
	thread.ops.gamma({p1, p2, p3}, self)
end

function ops.gamma(x, y)
	local n = node:new("Gamma")
	n:addPortIn(0, "Y__")
	n:addPortIn(1, "Y__"):addElem("float", 1, "Gamma", 0, 1, 0.5)
	n:addPortOut(0)
	n.process = gammaProcess
	n:setPos(x, y)
	return n
end

ops.clut = {}
local function genClut(lut)
	local function clutProcess(self)
		assert(self.portOut[0].link)
		local p1, p2, p3, p4
		p1 = t.inputSourceBlack(self, 0)
		p2 = self.data.lut or data.zero
		p3 = t.autoOutput(self, 0, p1:shape())
		p4 = t.inputParam(self, 1)
		thread.ops.clut({p1, p2, p3, p4}, self)
	end

	ops.clut[lut] = function(x, y)
		local n = node:new(lut)

		require "ui.notice".blocking("Loading look: "..lut)
		n.data.lut = require("io.native").read("looks/"..lut..".png"):toDevice(true)

		n:addPortIn(0):addPortOut(0)
		n:addPortIn(1):addElem("float", 1, "Mix", 0, 2, 1)

		n.process = clutProcess
		--n.w = 200
		n:setPos(x, y)
		return n
	end
end

local clut = {"Precisa", "Vista", "Astia", "Provia", "Sensia", "Superia", "Velvia", "Ektachrome", "Kodachrome", "Portra", "Neopan", "Delta", "Tri-X"}
for k, v in ipairs(clut) do
	genClut(v)
end


local function loadImage(image)
	require "ui.notice".blocking("Loading image: "..(type(image) == "string" and image or image:getFilename()), true)
	return require("io.im").read(image):toDevice()
end

local function imageProcess(self)
	local link = self.portOut[0].link
	assert(link, "Attempted processing node ["..self.title.."] with no output ["..(0).."] connected")
	link.data = self.data.image
end


function ops.image(x, y, image)
	image = image or "img.jpg"
	local n = node:new("Image")
	n.data.image = loadImage(image)
	n.data.imageName = image
	n:addPortOut(0, "LRGB")
	n:addElem("text", 1, image or "-", "")
	n:addElem("button", 2, "Open", function()
		n.data.imageName = require "lib.zenity".fileOpen()
		n.data.image = loadImage(n.data.imageName)
		n.elem[1].left = n.data.imageName:gsub("^.*[/\\]", "")
		n.dirty = true
	end)

	n.process = imageProcess
	n:setPos(x, y)
	return n
end


local function fwtProcessForward(self)
	assert(self.portOut[0].link)
	local p1, p2
	p1 = t.inputSourceBlack(self, 0)
	p2 = t.autoOutput(self, 0, p1:shape())
	thread.ops.fwtHaarForward({p1, p2}, self)
end

function ops.fwtForward(x, y)
	local n = node:new("FWT Forward")
	n:addPortIn(0)
	n:addPortOut(0)
	n.process = fwtProcessForward
	n:setPos(x, y)
	return n
end



local function fwtProcessInverse(self)
	assert(self.portOut[0].link)
	local p1, p2
	p1 = t.inputSourceBlack(self, 0)
	p2 = t.autoOutput(self, 0, p1:shape())
	local f1, f2, f3, f4, f5
	f1 = t.inputParam(self, 1)
	f2 = t.inputParam(self, 2)
	f3 = t.inputParam(self, 3)
	f4 = t.inputParam(self, 4)
	f5 = t.inputParam(self, 5)
	thread.ops.fwtHaarInverse({p1, p2, f1, f2, f3, f4, f5}, self)
end

function ops.fwtInverse(x, y)
	local n = node:new("FWT Inverse")
	n:addPortIn(0)
	n:addPortOut(0)
	n:addPortIn(1):addElem("float", 1, "Level 1", 0, 3, 1)
	n:addPortIn(2):addElem("float", 2, "Level 2", 0, 3, 1)
	n:addPortIn(3):addElem("float", 3, "Level 3", 0, 3, 1)
	n:addPortIn(4):addElem("float", 4, "Level 4", 0, 3, 1)
	n:addPortIn(5):addElem("float", 5, "Level 5", 0, 3, 1)
	n.process = fwtProcessInverse
	n:setPos(x, y)
	return n
end


local channelNames = {
	SRGB = {"sRGB", "R", "G", "B"},
	LRGB = {"Linear sRGB", "R", "G", "B"},
	XYZ = {"CIE XYZ", "X", "Y", "Z"},
	LAB = {"CIE LAB", "L", "a", "b"},
	LCH = {"CIE LCH", "L", "C", "h"},
	Y = {"CIE XYZ", "Y", "Y", "Y"},
	L = {"CIE LAB", "L", "L", "L"},
}
local function getChannelNames(cs)
	local cn = channelNames[cs]
	if cn then
		return cn[1], cn[2], cn[3], cn[4]
	else
		return cs, "-", "-", "-"
	end
end

local function decomposeProcess(self)
	local p1, p2, p3, p4
	p1 = t.inputSourceBlack(self, 0)
	p2 = t.autoOutputSink(self, 1, p1.x, p1.y, 1)
	p3 = t.autoOutputSink(self, 2, p1.x, p1.y, 1)
	p4 = t.autoOutputSink(self, 3, p1.x, p1.y, 1)
	thread.ops.decompose({p1, p2, p3, p4}, self)
end

local function genDecompose(cs)
	return function (x, y)
		local n = node:new("Split")
		n:addPortIn(0, cs)
		n:addPortOut(1, "Y"):addElem("text", 1, channelNames[cs][1], channelNames[cs][2])
		n:addPortOut(2, "Y"):addElem("text", 2, "", channelNames[cs][3])
		n:addPortOut(3, "Y"):addElem("text", 3, "", channelNames[cs][4])
		n.process = decomposeProcess
		n.w = 75
		n:setPos(x, y)
		return n
	end
end

ops.decomposeSRGB = genDecompose("SRGB")
ops.decomposeLRGB = genDecompose("LRGB")
ops.decomposeXYZ = genDecompose("XYZ")
ops.decomposeLAB = genDecompose("LAB")
ops.decomposeLCH = genDecompose("LCH")

local function composeProcess(self)
	local p1, p2, p3, p4
	p1 = t.inputParam(self, 1)
	p2 = t.inputParam(self, 2)
	p3 = t.inputParam(self, 3)
	local x, y, z = data.superSize(p1, p2, p3)
	p4 = t.autoOutput(self, 0, x, y, 3)
	thread.ops.compose({p1, p2, p3, p4}, self)
end

local function genCompose(cs)
	return function(x, y)
		local n = node:new(channelNames[cs][1])
		n:addPortOut(0, cs)
		n:addPortIn(1, "Y"):addElem("float", 1, channelNames[cs][2], 0, 1, 1)
		n:addPortIn(2, "Y"):addElem("float", 2, channelNames[cs][3], 0, 1, 1)
		n:addPortIn(3, "Y"):addElem("float", 3, channelNames[cs][4], 0, 1, 1)
		if cs == "LAB" then
			n.elem[2].min = -1
			n.elem[2].value = 0
			n.elem[2].default = 0
			n.elem[3].min = -1
			n.elem[3].value = 0
			n.elem[3].default = 0
		end
		n.process = composeProcess
		n.w = 75
		n:setPos(x, y)
		return n
	end
end

ops.composeSRGB = genCompose("SRGB")
ops.composeLRGB = genCompose("LRGB")
ops.composeXYZ = genCompose("XYZ")
ops.composeLAB = genCompose("LAB")
ops.composeLCH = genCompose("LCH")




local function mixRGBProcess(self)
	local r = t.autoTempBuffer(self, 2, 1, 1, 3)
	local g = t.autoTempBuffer(self, 5, 1, 1, 3)
	local b = t.autoTempBuffer(self, 8, 1, 1, 3)
	r:set(0, 0, 0, self.elem[1].value)
	r:set(0, 0, 1, self.elem[2].value)
	r:set(0, 0, 2, self.elem[3].value)
	g:set(0, 0, 0, self.elem[4].value)
	g:set(0, 0, 1, self.elem[5].value)
	g:set(0, 0, 2, self.elem[6].value)
	b:set(0, 0, 0, self.elem[7].value)
	b:set(0, 0, 1, self.elem[8].value)
	b:set(0, 0, 2, self.elem[9].value)
	local p1, p2, r, g, b
	p1 = t.inputSourceBlack(self, 0)
	r = t.inputData(self, 2)
	g = t.inputData(self, 5)
	b = t.inputData(self, 8)
	p2 = t.autoOutput(self, 0, data.superSize(p1, r, g, b))
	thread.ops.mixrgb({p1, p2, r, g, b}, self)
end

function ops.mixRGB(x, y)
	local n = node:new("Mix RGB")
	n:addPortIn(0, "LRGB")
	n:addPortIn(2, "LRGB")
	n:addPortIn(5, "LRGB")
	n:addPortIn(8, "LRGB")
	n:addPortOut(0, "LRGB")
	n.portIn[2].toggle = {[1] = false, [2] = false, [3] = false}
	n.portIn[5].toggle = {[4] = false, [5] = false, [6] = false}
	n.portIn[8].toggle = {[7] = false, [8] = false, [9] = false}

	n:addElem("float", 1, "R(r)", - 2, 3, 1)
	n:addElem("float", 2, "R(g)", - 2, 3, 0)
	n:addElem("float", 3, "R(b)", - 2, 3, 0).last = true
	n:addElem("float", 4, "G(r)", - 2, 3, 0).first = true
	n:addElem("float", 5, "G(g)", - 2, 3, 1)
	n:addElem("float", 6, "G(b)", - 2, 3, 0).last = true
	n:addElem("float", 7, "B(r)", - 2, 3, 0).first = true
	n:addElem("float", 8, "B(g)", - 2, 3, 0)
	n:addElem("float", 9, "B(b)", - 2, 3, 1)
	n.process = mixRGBProcess
	n:setPos(x, y)
	return n
end



local function adjustLCHProcess(self)
	self.procType = "par"
	local p1, p2, l, c, h
	p1 = t.inputSourceBlack(self, 0)
	l = t.inputParam(self, 1)
	c = t.inputParam(self, 2)
	h = t.inputParam(self, 3)
	local x, y, z = data.superSize(p1, l, c, h)
	p2 = t.autoOutput(self, 0, x, y, 3)
	thread.ops.adjustlch({p1, p2, l, c, h}, self)
end

function ops.adjustLCH(x, y)
	local n = node:new("Adjust LCH")
	n:addPortIn(0)
	n:addPortOut(0)
	n:addPortIn(1):addElem("float", 1, "L factor", 0, 3, 1)
	n:addPortIn(2):addElem("float", 2, "C factor", 0, 3, 1)
	n:addPortIn(3):addElem("float", 3, "H offset", - 1, 1, 0)
	n.process = adjustLCHProcess
	n:setPos(x, y)
	return n
end



local cs = require "tools.cs"
local function colorChange(self)
	local r = self.elem[1].value
	local g = self.elem[2].value
	local b = self.elem[3].value
	r, g, b = cs.LRGB.SRGB(r, g, b)
	self.elem[4].value = {r, g, b, 1}
end

local function colorProcess(self)
	local c = t.autoTempBuffer(self, 1, 1, 1, 3)
	c:set(0, 0, 0, self.elem[1].value)
	c:set(0, 0, 1, self.elem[2].value)
	c:set(0, 0, 2, self.elem[3].value)
	c:toDevice()
	self.portOut[4].link.data = c
end

function ops.color(x, y)
	local n = node:new("Color")
	n:addElem("float", 1, "Red", 0, 1, 1)
	n:addElem("float", 2, "Green", 0, 1, 1)
	n:addElem("float", 3, "Blue", 0, 1, 1)
	n:addPortOut(4):addElem("color", 4, "Color")
	n.process = colorProcess
	n.onChange = colorChange
	n:setPos(x, y)
	return n
end


local function downsize(x, y, z)
	if not y then
		x, y, z = x:shape()
	end
	x = math.ceil(x / 2)
	y = math.ceil(y / 2)
	return x, y, z
end

local function blur(self, i, o, n, d)
	local x, y, z = downsize(i)
	local l = {}
	l[1] = t.autoTempBuffer(self, -1, x, y, d or z)
	for j = 2, n do
		l[j] = t.autoTempBuffer(self, -j, downsize(l[j-1]))
	end
	thread.ops.pyrBlurDown({i, l[1]}, self)
	for j = 2, n do
		thread.ops.pyrBlurDown({l[j-1], l[j]}, self)
	end
	for j = n, 2, -1 do
		thread.ops.pyrBlurUp({l[j], l[j-1]}, self)
	end
	thread.ops.pyrBlurUp({l[1], o}, self)
end

local function mix8(self, a, b, m, o)
	local mg1, mg2, mg3, mg4, mg5, mg6, mg7, mg8

	local al1, al2, al3, al4, al5, al6, al7, al8, ag8
	local bl1, bl2, bl3, bl4, bl5, bl6, bl7, bl8, bg8
	local g1, g2, g3, g4, g5, g6, g7

	al1 = t.autoTempBuffer(self, -1, o:shape())
	al2 = t.autoTempBuffer(self, -2, downsize(al1))
	al3 = t.autoTempBuffer(self, -3, downsize(al2))
	al4 = t.autoTempBuffer(self, -4, downsize(al3))
	al5 = t.autoTempBuffer(self, -5, downsize(al4))
	al6 = t.autoTempBuffer(self, -6, downsize(al5))
	al7 = t.autoTempBuffer(self, -7, downsize(al6))
	al8 = t.autoTempBuffer(self, -8, downsize(al7))
	ag8 = t.autoTempBuffer(self, -9, downsize(al8))

	bl1 = t.autoTempBuffer(self, -11, o:shape())
	bl2 = t.autoTempBuffer(self, -12, downsize(bl1))
	bl3 = t.autoTempBuffer(self, -13, downsize(bl2))
	bl4 = t.autoTempBuffer(self, -14, downsize(bl3))
	bl5 = t.autoTempBuffer(self, -15, downsize(bl4))
	bl6 = t.autoTempBuffer(self, -16, downsize(bl5))
	bl7 = t.autoTempBuffer(self, -17, downsize(bl6))
	bl8 = t.autoTempBuffer(self, -18, downsize(bl7))
	bg8 = t.autoTempBuffer(self, -19, downsize(bl8))

	g1 = t.autoTempBuffer(self, -21, downsize(o))
	g2 = t.autoTempBuffer(self, -22, downsize(g1))
	g3 = t.autoTempBuffer(self, -23, downsize(g2))
	g4 = t.autoTempBuffer(self, -24, downsize(g3))
	g5 = t.autoTempBuffer(self, -25, downsize(g4))
	g6 = t.autoTempBuffer(self, -26, downsize(g5))
	g7 = t.autoTempBuffer(self, -27, downsize(g6))

	thread.ops.pyrDown({a, al1, g1}, self)
	thread.ops.pyrDown({g1, al2, g2}, self)
	thread.ops.pyrDown({g2, al3, g3}, self)
	thread.ops.pyrDown({g3, al4, g4}, self)
	thread.ops.pyrDown({g4, al5, g5}, self)
	thread.ops.pyrDown({g5, al6, g6}, self)
	thread.ops.pyrDown({g6, al7, g7}, self)
	thread.ops.pyrDown({g7, al8, ag8}, self)

	thread.ops.pyrDown({b, bl1, g1}, self)
	thread.ops.pyrDown({g1, bl2, g2}, self)
	thread.ops.pyrDown({g2, bl3, g3}, self)
	thread.ops.pyrDown({g3, bl4, g4}, self)
	thread.ops.pyrDown({g4, bl5, g5}, self)
	thread.ops.pyrDown({g5, bl6, g6}, self)
	thread.ops.pyrDown({g6, bl7, g7}, self)
	thread.ops.pyrDown({g7, bl8, bg8}, self)

	mg1 = t.autoTempBuffer(self, -31, downsize(m))
	mg2 = t.autoTempBuffer(self, -32, downsize(mg1))
	mg3 = t.autoTempBuffer(self, -33, downsize(mg2))
	mg4 = t.autoTempBuffer(self, -34, downsize(mg3))
	mg5 = t.autoTempBuffer(self, -35, downsize(mg4))
	mg6 = t.autoTempBuffer(self, -36, downsize(mg5))
	mg7 = t.autoTempBuffer(self, -37, downsize(mg6))
	mg8 = t.autoTempBuffer(self, -38, downsize(mg7))

	thread.ops.pyrBlurDown({m, mg1}, self)
	thread.ops.pyrBlurDown({mg1, mg2}, self)
	thread.ops.pyrBlurDown({mg2, mg3}, self)
	thread.ops.pyrBlurDown({mg3, mg4}, self)
	thread.ops.pyrBlurDown({mg4, mg5}, self)
	thread.ops.pyrBlurDown({mg5, mg6}, self)
	thread.ops.pyrBlurDown({mg6, mg7}, self)
	thread.ops.pyrBlurDown({mg7, mg8}, self)

	thread.ops.mix({al1, bl1, m, al1}, self)
	thread.ops.mix({al2, bl2, mg1, al2}, self)
	thread.ops.mix({al3, bl3, mg2, al3}, self)
	thread.ops.mix({al4, bl4, mg3, al4}, self)
	thread.ops.mix({al5, bl5, mg4, al5}, self)
	thread.ops.mix({al6, bl6, mg5, al6}, self)
	thread.ops.mix({al7, bl7, mg6, al7}, self)
	thread.ops.mix({al8, bl8, mg7, al8}, self)
	thread.ops.mix({ag8, bg8, mg8, ag8}, self)

	thread.ops.pyrUp({al8, ag8, g7, data.one}, self)
	thread.ops.pyrUp({al7, g7, g6, data.one}, self)
	thread.ops.pyrUp({al6, g6, g5, data.one}, self)
	thread.ops.pyrUp({al5, g5, g4, data.one}, self)
	thread.ops.pyrUp({al4, g4, g3, data.one}, self)
	thread.ops.pyrUp({al3, g3, g2, data.one}, self)
	thread.ops.pyrUp({al2, g2, g1, data.one}, self)
	thread.ops.pyrUp({al1, g1, o, data.one}, self)
end

local function smartMixProcess(self)
	self.procType = "dev"
	local a, b, m, o
	a = t.inputSourceBlack(self, 1)
	b = t.inputSourceBlack(self, 2)
	m = t.inputParam(self, 3)
	o = t.autoOutput(self, 0, data.superSize(a, b, m))
	mix8(self, a, b, m, o)
end

function ops.smartMix(x, y)
	local n = node:new("Smart Mix")
	n:addPortIn(1, "LAB"):addElem("text", 1, "A")
	n:addPortIn(2, "LAB"):addElem("text", 2, "B")
	n:addPortIn(3, "Y"):addElem("float", 3, "Factor", 0, 1, 0.5)
	n:addPortOut(0, "LAB")

	n.process = smartMixProcess
	n.w = 75
	n:setPos(x, y)
	return n
end

local function blurProcess(self)
	self.procType = "dev"
	local i, o
	i = t.inputSourceBlack(self, 0)
	o = t.autoOutput(self, 0, i:shape())
	o.cs = i.cs

	local n = t.autoTempBuffer(self, -1, 1, 1, 1)
	n:set(0, 0, 0, self.elem[1].value) -- CPU-only buffer, no sync!
	thread.ops.blur({i, o, n}, self)
end

function ops.blur(x, y)
	local n = node:new("Blur")
	n:addPortIn(0, "Y__")
	n:addPortOut(0, "Y__")
	n:addElem("int", 1, "Scale", 1, 15, 3, 1)
	n.process = blurProcess
	n:setPos(x, y)
	return n
end

local function bokehProcess(self)
	self.procType = "dev"
	local i, r, o, h
	i = t.inputSourceBlack(self, 0)
	r = t.inputParam(self, 1)
	o = t.autoOutput(self, 0, i:shape())
	h = t.plainParam(self, 2)
	o.cs = i.cs
	thread.ops.bokeh({i, r, o, h}, self)
end

function ops.bokeh(x, y)
	local n = node:new("Bokeh")
	n:addPortIn(0, "Y__")
	n:addPortOut(0, "Y__")
	n:addPortIn(1, "Y"):addElem("float", 1, "Radius", 0, 1, 0.1)
	n:addElem("bool", 2, "Hexagonal", false)
	n.process = bokehProcess
	n:setPos(x, y)
	return n
end

local function RLdeconvolutionProcess(self)
	self.procType = "dev"
	local i, o, w, f
	i = t.inputSourceBlack(self, 0)
	o = t.autoOutput(self, 0, i:shape())
	w = t.inputParam(self, 1)
	f = t.inputParam(self, 2)
	thread.ops.RLdeconvolution({i, o, w, f}, self)
end

function ops.RLdeconvolution(x, y)
	local n = node:new("RL-Deconv.")
	n:addPortIn(0, "LAB")
	n:addPortOut(0, "LAB")
	n:addPortIn(1, "Y"):addElem("float", 1, "Radius", 0, 2, 0.75)
	n:addPortIn(2, "Y"):addElem("float", 2, "Strength", 0, 20, 5)
	n.process = RLdeconvolutionProcess
	n:setPos(x, y)
	return n
end

local function shockFilterProcess(self)
	self.procType = "dev"
	local i, o, w, f
	i = t.inputSourceBlack(self, 0)
	o = t.autoOutput(self, 0, i:shape())
	w = t.inputParam(self, 1)
	f = t.inputParam(self, 2)
	thread.ops.shockFilter({i, o, w, f}, self)
end

function ops.shockFilter(x, y)
	local n = node:new("Shock Filter")
	n:addPortIn(0, "LAB")
	n:addPortOut(0, "LAB")
	n:addPortIn(1, "Y"):addElem("float", 1, "Radius", 0, 1, 0.5)
	n:addPortIn(2, "Y"):addElem("float", 2, "Strength", 0, 1, 0.2)
	n.process = shockFilterProcess
	n:setPos(x, y)
	return n
end

local function sharpenProcess(self)
	self.procType = "dev"
	local i, f, s, c, o
	i = t.inputSourceBlack(self, 0)
	f = t.inputParam(self, 1)
	s = t.inputParam(self, 3)
	o = t.autoOutput(self, 0, i:shape())
	thread.ops.diffuse({i, f, s, o}, self)
	for i = 2, self.elem[2].value do
		thread.ops.diffuse({o, f, s, o}, self)
	end
end

function ops.sharpen(x, y)
	local n = node:new("Sharpen")
	n:addPortIn(0, "LAB")
	n:addPortOut(0, "LAB")
	n:addPortIn(1, "Y"):addElem("float", 1, "Strength", 0, 1, 0.5)
	n:addElem("int", 2, "Iterations", 1, 9, 5)
	n:addPortIn(3, "Y"):addElem("float", 3, "Reduce Noise", 0, 1, 0)
	n.process = sharpenProcess
	n.w = 100
	n:setPos(x, y)
	return n
end


local function clarityProcess(self)
	self.procType = "dev"
	local i, o, c, d
	i = t.inputSourceBlack(self, 0)
	c = t.inputParam(self, 1)
	o = t.autoOutput(self, 0, i:shape())
	blur(self, i, o, self.elem[2].value)
	thread.ops.clarity({i, c, o}, self)

	if self.elem[3].value then
		thread.ops.setHue({o, i, o}, self)
		o.cs = "LCH"
	end
end

function ops.clarity(x, y)
	local n = node:new("Clarity")
	n:addPortIn(0, "SRGB")
	n:addPortOut(0, "SRGB")
	n:addPortIn(1, "Y"):addElem("float", 1, "Clarity", 0, 1, 0)
	n:addElem("int", 2, "Scale", 1, 15, 8)
	n:addElem("bool", 3, "Preserve Hue", true)
	n.process = clarityProcess
	n:setPos(x, y)
	return n
end


local function compressProcess(self)
	self.procType = "dev"
	local i, o, h, s
	i = t.inputSourceBlack(self, 0)
	h = t.inputParam(self, 1)
	s = t.inputParam(self, 2)
	o = t.autoOutput(self, 0, i:shape())
	blur(self, i, o, self.elem[3].value, 1)
	thread.ops.compress({i, h, s, o}, self)
end

function ops.compress(x, y)
	local n = node:new("Compress")
	n:addPortIn(0, "LAB") -- FIXME: use L__
	n:addPortOut(0, "LAB")
	n:addPortIn(1, "Y"):addElem("float", 1, "Highlights", 0, 1, 0)
	n:addPortIn(2, "Y"):addElem("float", 2, "Shadows", 0, 1, 0)
	n:addElem("int", 3, "Scale", 1, 15, 8)
	n.process = compressProcess
	n:setPos(x, y)
	return n
end

local function structureProcess(self)
	self.procType = "dev"
	local i, s, o
	i = t.inputSourceBlack(self, 0)
	s = t.inputParam(self, 1)
	o = t.autoOutput(self, 0, i:shape())
	blur(self, i, o, self.elem[2].value, 1)
	thread.ops.structure({i, s, o}, self)
end

function ops.structure(x, y)
	local n = node:new("Structure")
	n:addPortIn(0, "LAB") -- FIXME: use L__
	n:addPortOut(0, "LAB")
	n:addPortIn(1, "Y"):addElem("float", 1, "Structure", 0, 1, 0)
	n:addElem("int", 2, "Scale", 1, 15, 8)
	n.process = structureProcess
	n:setPos(x, y)
	return n
end

local function parametricProcess(self)
	self.procType = "dev"
	local i, p1, p2, p3, p4, o
	i = t.inputSourceBlack(self, 0)
	p1 = t.inputParam(self, 1)
	p2 = t.inputParam(self, 2)
	p3 = t.inputParam(self, 3)
	p4 = t.inputParam(self, 4)
	o = t.autoOutput(self, 0, data.superSize(i, p1, p2, p3, p4))
	thread.ops.parametric({i, p1, p2, p3, p4, o}, self)
end

function ops.parametric(x, y)
	local n = node:new("Parametric")
	n:addPortIn(0, "LAB")
	n:addPortOut(0, "LAB")
	n:addPortIn(1, "Y"):addElem("float", 1, "Shadows", - 1, 1, 0)
	n:addPortIn(2, "Y"):addElem("float", 2, "Darks", - 1, 1, 0)
	n:addPortIn(3, "Y"):addElem("float", 3, "Lights", - 1, 1, 0)
	n:addPortIn(4, "Y"):addElem("float", 4, "Highlights", - 1, 1, 0)

	n.process = parametricProcess
	n:setPos(x, y)
	return n
end

local function tonalContrastProcess(self)
	self.procType = "dev"
	local i, p1, p2, p3, p4, o
	i = t.inputSourceBlack(self, 0)
	p1 = t.inputParam(self, 1)
	p2 = t.inputParam(self, 2)
	p3 = t.inputParam(self, 3)
	p4 = t.inputParam(self, 4)
	o = t.autoOutput(self, 0, data.superSize(i, p1, p2, p3, p4))
	blur(self, i, o, self.elem[5].value, 1)
	thread.ops.tonalContrast({i, p1, p2, p3, p4, o}, self)
end

function ops.tonalContrast(x, y)
	local n = node:new("Tonal Contrast")
	n:addPortIn(0, "LAB")
	n:addPortOut(0, "LAB")
	n:addPortIn(1, "Y"):addElem("float", 1, "Shadows", - 1, 1, 0)
	n:addPortIn(2, "Y"):addElem("float", 2, "Darks", - 1, 1, 0)
	n:addPortIn(3, "Y"):addElem("float", 3, "Midtones", - 1, 1, 0)
	n:addPortIn(4, "Y"):addElem("float", 4, "Lights", - 1, 1, 0)
	n:addElem("int", 5, "Scale", 1, 15, 8)

	n.process = tonalContrastProcess
	n:setPos(x, y)
	return n
end

local function pyrDownProcess(self)
	self.procType = "dev"
	local I, L, G
	I = t.inputSourceBlack(self, 0)
	L = t.autoOutputBuffer(self, 1, I:shape())
	G = t.autoOutputBuffer(self, 2, downsize(I))
	thread.ops.pyrDown({I, L, G}, self)
end

function ops.pyrDown(x, y)
	local n = node:new("Pyramid Down")
	n:addPortIn(0, "LAB")
	n:addPortOut(1, "LAB"):addElem("text", 1, "", "Laplacian")
	n:addPortOut(2, "LAB"):addElem("text", 2, "", "Gaussian")
	n.process = pyrDownProcess
	n:setPos(x, y)
	return n
end

local function pyrUpProcess(self)
	self.procType = "dev"
	local L, G, O, f
	L = t.inputSourceBlack(self, 1)
	G = t.inputSourceBlack(self, 2)
	local lx, ly, lz = L:shape()
	local gx, gy, gz = G:shape()
	lx = lx==1 and gx*2 or lx
	ly = ly==1 and gy*2 or ly
	O = t.autoOutput(self, 0, lx, ly, 3)
	f = t.inputParam(self, 3)
	thread.ops.pyrUp({L, G, O, f}, self)
end

function ops.pyrUp(x, y)
	local n = node:new("Pyramid Up")
	n:addPortOut(0, "LAB")
	n:addPortIn(1, "LAB"):addElem("text", 1, "Laplacian", "")
	n:addPortIn(2, "LAB"):addElem("text", 2, "Gaussian", "")
	n:addPortIn(3, "Y"):addElem("float", 3, "L mix factor", 0, 2, 1)
	n.process = pyrUpProcess
	n:setPos(x, y)
	return n
end

local function nlmeansProcess(self)
	self.procType = "dev"
	local i = t.inputSourceBlack(self, 0)
	local p1 = t.inputParam(self, 1)
	local p2 = t.inputParam(self, 2)
	local p3 = t.inputParam(self, 3)

	local x, y, z = data.superSize(i, p1, p2, p3)
	local t1 = t.autoTempBuffer(self, 4, x, y, 1)
	local t2 = t.autoTempBuffer(self, 5, x, y, 1)
	local t3 = t.autoTempBuffer(self, 6, x, y, z)
	local t4 = t.autoTempBuffer(self, 7, x, y, z)

	local o = t.autoOutput(self, 0, x, y, z)
	thread.ops.nlmeans({i, t1, t2, t3, t4, p1, p2, p3, o}, self)
end

function ops.nlmeans(x, y)
	local n = node:new("Denoise")
	n:addPortIn(0, "LAB")
	n:addPortOut(0, "LAB")
	n:addPortIn(1, "Y"):addElem("float", 1, "Lightness", 0, 1, 0.2)
	n:addPortIn(2, "Y"):addElem("float", 2, "Chroma", 0, 1, 0.2)
	n:addPortIn(3, "Y"):addElem("float", 3, "Mask", 0, 1, 1)
	n.process = nlmeansProcess
	n:setPos(x, y)
	return n
end


local function custom3DProcess(self)
	self.procType = "dev"
	local p1, p2, p3, p4, p5
	p1 = t.inputSourceBlack(self, 1)
	p2 = t.inputSourceBlack(self, 2)
	p3 = t.inputSourceBlack(self, 3)
	p4 = t.inputSourceBlack(self, 4)
	p5 = t.autoOutput(self, 5, data.superSize(p1, p2, p3, p4))
	thread.ops.custom3D({p1, p2, p3, p4, p5}, self)
end

function ops.custom3D(x, y)
	local n = node:new("Custom 3D")
	n:addPortIn(1):addElem("text", 1, "Input 1", "")
	n:addPortIn(2):addElem("text", 2, "Input 2", "")
	n:addPortIn(3):addElem("text", 3, "Input 3", "")
	n:addPortIn(4):addElem("text", 4, "Input 4", "")
	n:addPortOut(5):addElem("text", 5, "", "Output")
	n.process = custom3DProcess
	n:setPos(x, y)
	return n
end

ops.math = {}
local function genMath1(name, fn)
	local function process(self)
		self.procType = "dev"
		local i, o
		i = t.inputSourceBlack(self, 0)
		o = t.autoOutput(self, 0, i:shape())
		thread.ops[fn]({i, o}, self)
	end

	ops.math[name] = function(x, y)
		local n = node:new(name)
		n:addPortIn(0, "LRGB")
		n:addPortOut(0, "LRGB")
		n.process = process
		n.w = 75
		n:setPos(x, y)
		return n
	end
end

local function genMath2(name, fn, init, min, max)
	local function process(self)
		self.procType = "dev"
		local i1, i2, o
		i1 = t.inputSourceBlack(self, 0)
		i2 = t.inputParam(self, 1)
		o = t.autoOutput(self, 0, data.superSize(i1, i2))
		o.cs = t.optCSsuperset(i1, i2)
		thread.ops[fn]({i1, i2, o}, self)
	end

	ops.math[name] = function(x, y)
		local n = node:new(name)
		n:addPortIn(0, "Y__")
		n:addPortIn(1, "Y__"):addElem("float", 1, "", min or -2, max or 2, init)
		n:addPortOut(0)
		n.process = process
		n.w = 75
		n:setPos(x, y)
		return n
	end
end

genMath1("Absolute", "_abs")
genMath1("Negative", "neg")
genMath1("Invert", "inv")
genMath1("Clamp", "_clamp")

genMath2("Add", "add", 0)
genMath2("Subtract", "sub", 0)
genMath2("Multiply", "mul", 1)
genMath2("Divide", "div", 1)
genMath2("Power", "_pow", 1, 0, 2)
genMath2("Maximum", "_max", 0, 0, 1)
genMath2("Minimum", "_min", 1, 0, 1)
genMath2("Average", "average", 0, 0, 1)
genMath2("Difference", "difference", 0, 0, 1)
genMath2("Greater", "GT", 0.5, 0, 1)
genMath2("Less", "LT", 0.5, 0, 1)

local function processValue(self)
	local o = t.autoOutput(self, 0, 1, 1, 1)
	local v = tonumber(self.elem[1].value)
	o:set(0, 0, 0, v)
	o:toDevice()
end

ops.math.value = function(x, y)
	local n = node:new("Value")
	n:addPortOut(0, "Y"):addElem("textinput", 1, "1.0")
	n.process = processValue
	n.w = 75
	n:setPos(x, y)
	return n
end


ops.cs = {}
local function genCS(name, mono)
	local function process(self)
		self.procType = "dev"
		local i, o
		i = t.inputSourceBlack(self, 0)
		local x, y, z = i:shape()
		z = mono and 1 or 3
		o = t.autoOutput(self, 0, x, y, z)
		thread.ops[name]({i, o}, self)
	end

	ops.cs[name] = function(x, y)
		local n = node:new(name)
		n:addPortIn(0, "ANY")
		n:addPortOut(0, name)
		n.process = process
		n.w = 75
		n:setPos(x, y)
		return n
	end
end

genCS("SRGB")
genCS("LRGB")
genCS("XYZ")
genCS("LAB")
genCS("LCH")
genCS("Y", true)
genCS("L", true)

local function castYtoLprocess(self)
	self.procType = "dev"
	local i, o
	i = t.inputSourceBlack(self, 0)
	o = t.autoOutput(self, 0, i:shape())
	thread.ops.Y({i, o}, self)
end

function ops.castYtoL(x, y)
	local n = node:new("Y as L")
	n:addPortIn(0, "Y")
	n:addPortOut(0, "L")
	n.process = castYtoLprocess
	n.w = 75
	n:setPos(x, y)
	return n
end

local function castLtoYprocess(self)
	self.procType = "dev"
	local i, o
	i = t.inputSourceBlack(self, 0)
	o = t.autoOutput(self, 0, i:shape())
	thread.ops.L({i, o}, self)
end

function ops.castLtoY(x, y)
	local n = node:new("L as Y")
	n:addPortIn(0, "L")
	n:addPortOut(0, "Y")
	n.process = castLtoYprocess
	n.w = 75
	n:setPos(x, y)
	return n
end


ops.blend = {}
local function genBlend(name, func)
	local function process(self)
		self.procType = "dev"
		local a, b, f, o
		a = t.inputSourceBlack(self, 0)
		b = t.inputSourceBlack(self, 1)
		f = t.inputParam(self, 2)
		o = t.autoOutput(self, 0, data.superSize(a, b, f))
		thread.ops[func]({a, b, f, o}, self)
		o.cs = t.optCSsuperset(a, b)
	end

	ops.blend[func] = function(x, y)
		local n = node:new(name)
		n:addPortIn(0, "Y__")
		n:addPortIn(1, "Y__"):addElem("text", 1, "Blend Layer")
		n:addPortIn(2, "Y"):addElem("float", 2, "Mix", 0, 1, 1)
		n:addPortOut(0)
		n.process = process
		n.w = 75
		n:setPos(x, y)
		return n
	end
end

genBlend("Negate", "negate")
genBlend("Exclude", "exclude")
genBlend("Screen", "screen")
genBlend("Overlay", "overlay")
genBlend("Hard Light", "hardlight")
genBlend("Soft Light", "softlight")
genBlend("Dodge", "dodge")
genBlend("Soft Dodge", "softdodge")
genBlend("Burn", "burn")
genBlend("Soft Burn", "softburn")
genBlend("Linear Light", "linearlight")
genBlend("Vivid Light", "vividlight")
genBlend("Pin Light", "pinlight")

return ops
