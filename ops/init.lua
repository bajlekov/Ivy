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

-- define nodes
local node = require "ui.node"
local data = require "data"
local thread = require "thread"

local t = require "ops.tools"

local ops = {}

require "ops.adjust"(ops)
require "ops.clone"(ops)
require "ops.curves"(ops)
require "ops.select"(ops)
require "ops.color"(ops)
require "ops.script"(ops)

-- list of ops + menu entries
local register = require "ops.tools.register"
register(ops, "contrast")
register(ops, "gamma")
register(ops, "bilateral")
register(ops, "domainTransform")
register(ops, "split_lr")
register(ops, "split_ud")
register(ops, "random_normal")
register(ops, "random_poisson")
register(ops, "random_binomial")
register(ops, "random_impulse")
register(ops, "random_uniform")
register(ops, "random_film")
register(ops, "wiener")
register(ops, "median")

-- load custom specifications
local f = io.open("ops/custom/custom.txt", "r")
if f then
	for line in f:lines() do
		local file = line:match("^%W*(.-)%W*$")
		local name = file:gsub("%.lua$", "")

		-- load specs
		local spec = require("ops.custom.spec."..name)
		spec.procName = "custom_"..spec.procName
		register(ops, spec)
	end
end

t.imageShapeSet(1, 1, 1)

local function inputProcess(self)
	local link = self.portOut[0].link
	link.data = self.imageData
	link:setData() -- cleans up CS buffers in link
	self.state = "ready"
end

function ops.input(x, y, img)
	local n = node:new("Input")
	n:addPortOut(0, "LRGB")
	n.image = img
	n.process = inputProcess
	n.protected = true
	n.w = 75
	n:setPos(x, y)
	n.dirty = false
	return n
end


local cct = require "tools.cct"
local bradford = require "tools.bradford"
local function temperatureProcess(self)
	self.procType = "dev"
	local i = t.inputSourceBlack(self, 0)
	local p = t.autoTempBuffer(self, 1, 1, 1, 3)
	local o = t.autoOutput(self, 0, i:shape())

	local Li, Mi, Si = bradford.fwd(cct(self.elem[1].value, self.elem[2].value))
	local Lo, Mo, So = bradford.fwd(cct(6500))
	p:set(0, 0, 0, Lo / Li)
	p:set(0, 0, 1, Mo / Mi)
	p:set(0, 0, 2, So / Si)
	p:syncDev()
	thread.ops.whitepoint({i, p, o}, self)
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
	self.procType = "dev"
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
	self.procType = "dev"
	local x = t.inputParam(self, 1)
	local y = t.inputParam(self, 2)

	local sx, sy = t.imageShape()
	local o = t.autoOutputSink(self, 0, sx, sy, 1)

	thread.ops.radial({x, y, o}, self)
end

function ops.radial(x, y)
	local n = node:new("Radial")
	n:addPortOut(0, "Y")
	n:addPortIn(1, "Y"):addElem("float", 1, "X", 0, 1, 0.5)
	n:addPortIn(2, "Y"):addElem("float", 2, "Y", 0, 1, 0.5)
	n.process = radialProcess
	n:setPos(x, y)
	return n
end

local function linearProcess(self)
	self.procType = "dev"
	local x = t.inputParam(self, 1)
	local y = t.inputParam(self, 2)
	local theta = t.inputParam(self, 3)
	local w = t.inputParam(self, 4)

	local sx, sy = t.imageShape()
	local o = t.autoOutputSink(self, 0, sx, sy, 1)

	thread.ops.linear({x, y, theta, w, o}, self)
end

function ops.linear(x, y)
	local n = node:new("Linear")
	n:addPortOut(0, "Y")
	n:addPortIn(1, "Y"):addElem("float", 1, "X", 0, 1, 0.5)
	n:addPortIn(2, "Y"):addElem("float", 2, "Y", 0, 1, 0.5)
	n:addPortIn(3, "Y"):addElem("float", 3, "θ", -1, 1, 0)
	n:addPortIn(4, "Y"):addElem("float", 4, "Width", 0, 1, 0)

	n.widget = require "ui.widget.gradient"("linear", n.elem[1], n.elem[2], n.elem[3], n.elem[4])
	n.widget.toolButton(n, 5, "Manipulate")

	n.refresh = true
	n.process = linearProcess
	n:setPos(x, y)
	return n
end

local function mirroredProcess(self)
	self.procType = "dev"
	local x = t.inputParam(self, 1)
	local y = t.inputParam(self, 2)
	local theta = t.inputParam(self, 3)

	local sx, sy = t.imageShape()
	local o = t.autoOutputSink(self, 0, sx, sy, 1)

	thread.ops.mirrored({x, y, theta, o}, self)
end

function ops.mirrored(x, y)
	local n = node:new("Mirrored")
	n:addPortOut(0, "Y")
	n:addPortIn(1, "Y"):addElem("float", 1, "X", 0, 1, 0.5)
	n:addPortIn(2, "Y"):addElem("float", 2, "Y", 0, 1, 0.5)
	n:addPortIn(3, "Y"):addElem("float", 3, "θ", -1, 1, 0)
	n.process = mirroredProcess
	n:setPos(x, y)
	return n
end

local function outputProcess(self)
	self.procType = "dev"
	local i = t.inputSourceBlack(self, 0)
	local d = t.plainParam(self, 2)
	local g = t.plainParam(self, 3)
	local c = t.plainParam(self, 4)
	local h = self.data.histogram -- pre-allocated
	if self.elem[1].value then
		thread.ops.display_histogram({i, self.image, g, c, d, h}, self)
	else
		thread.ops.display({i, self.image, g, c, d}, self)
	end
end

function ops.output(x, y, img)
	local n = node:new("Output")
	n:addPortIn(0, "ANY")
	n:addElem("bool", 1, "Histogram", true)
	n:addElem("bool", 2, "Dither", true)
	n:addElem("bool", 3, "Gamut clip", false)
	n:addElem("enum", 4, "Method", {"Chroma", "Color", "Channels", "Lightness"}, 1)
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

local function processSampleWB(self)
	self.procType = "dev"
	local i = t.inputSourceBlack(self, 0)
	local o = t.autoOutputSink(self, 0, i:shape())

	local ox, oy, update = self.data.tweak.getCurrent()
	local p = t.autoTempBuffer(self, -1, 1, 1, 3) -- [x, y]
	local s = t.autoTempBuffer(self, -2, 1, 1, 3) -- [r, g, b]
	p:set(0, 0, 0, ox)
	p:set(0, 0, 1, oy)
	p:syncDev()

	if update or self.elem[2].value then
		thread.ops.whitepointSample({i, p, s}, self)
	end

	thread.ops.whitepoint({i, s, o}, self)
end

function ops.sampleWB(x, y)
	local n = node:new("Sample WB")
	n.data.tweak = require "ui.widget.tweak"()
	n:addPortIn(0, "XYZ")
	n:addPortOut(0, "XYZ")
	n.data.tweak.toolButton(n, 1, "Sample WB")
	n:addElem("bool", 2, "Resample pos.", false)
	n.process = processSampleWB

	local s = t.autoTempBuffer(n, -2, 1, 1, 3)
	s:set(0, 0, 0, 1)
	s:set(0, 0, 1, 1)
	s:set(0, 0, 2, 1)
	s:syncDev()

	n:setPos(x, y)
	return n
end

local function processSetWP(self)
	self.procType = "dev"
	local i = t.inputSourceBlack(self, 0)
	local w = t.inputSourceWhite(self, 1)
	local o = t.autoOutputSink(self, 0, i:shape())

	thread.ops.whitepoint({i, w, o}, self)
end

function ops.setWP(x, y)
	local n = node:new("Set White")
	n.data.tweak = require "ui.widget.tweak"()
	n:addPortIn(0, "XYZ")
	n:addPortOut(0, "XYZ")
	n:addPortIn(1, "XYZ"):addElem("text", 1, "White point")
	n.process = processSetWP

	n:setPos(x, y)
	return n
end


local function processFeatherMask(self)
	self.procType = "dev"
	local m = t.inputSourceBlack(self, 0)
	local g = t.inputSourceBlack(self, 1)
	local r = t.inputParam(self, 2)
	local f = t.inputParam(self, 3)
	local o = t.autoOutputSink(self, 0, m:shape())
	local n = t.plainParam(self, 4)
	thread.ops.maskRefine({m, g, r, f, o, n}, self)
end

function ops.featherMask(x, y)
	local n = node:new("Feather Mask")
	n:addPortIn(0, "XYZ")
	n:addPortIn(1, "LAB"):addElem("text", 1, "Guide")
	n:addPortIn(2, "Y"):addElem("float", 2, "Range", 0, 0.5, 0.2)
	n:addPortIn(3, "Y"):addElem("float", 3, "Fall-off", 0, 1, 0.5)
	n:addElem("float", 4, "Kernel Size", 0, 10, 2)
	n:addPortOut(0, "XYZ")
	n.process = processFeatherMask

	n:setPos(x, y)
	return n
end


do
	local pool = require "tools.imagePool"
	local ffi = require "ffi"

	local function processPaintMask(self)
		self.procType = "dev"
		local link = self.portOut[0].link

		if link then
			link.data = self.mask:get()
			link:setData("Y", self.procType)

			local i = t.inputSourceBlack(self, 6)

			local ox, oy = self.data.tweak.getOrigin()
			local path = self.data.tweak.getUpdatePath()

			if #path > 0 then
				local p = t.autoTempBuffer(self, -1, #path, 11, 1) -- [x, y, value, flow, size, fall-off, range, fall-off, patch, sample x, sample y]
				print(p.cs)
				p.cs = "Y"

				for idx, point in ipairs(path) do
					idx = idx - 1
					p:set(idx, 0, 0, point.x)
					p:set(idx, 1, 0, point.y)
					p:set(idx, 2, 0, point.ctrl and (1 - self.elem[2].value) or (self.elem[2].value))
					p:set(idx, 3, 0, self.elem[3].value)
					p:set(idx, 4, 0, self.elem[4].value)
					p:set(idx, 5, 0, self.elem[5].value)
					p:set(idx, 6, 0, self.portIn[6].link and self.elem[6].value^2 or -1) -- range -1: disabled
					p:set(idx, 7, 0, self.elem[7].value)
					p:set(idx, 8, 0, self.elem[8].value)
					p:set(idx, 9, 0, point.alt and ox or point.x)
					p:set(idx, 10, 0, point.alt and oy or point.y)
				end
				p:hostWritten() -- all host data is overwritten
				p:syncDev()

				thread.ops.paintSmart({link.data, i, p}, self)
			end
		end
	end

	function ops.paintMaskSmart(x, y)
		local n = node:new("Paint Mask")

		do
			local sx, sy = t.imageShape()
			local mask = data:new(sx, sy, 1)
			thread.ops.copy({data.zero, mask}, "dev")
			pool.resize(sx, sy)
			n.mask = pool.add(mask)
		end

		n:addPortOut(0, "Y")
		n:addPortIn(6, "LAB")
		n.portIn[6].toggle = {[6] = true, [7] = true}

		n:addElem("float", 2, "Value", 0, 1, 1)
		n:addElem("float", 3, "Flow", 0, 1, 1)
		n:addElem("float", 4, "Brush Size", 0, 500, 50)
		n:addElem("float", 5, "Fall-off", 0, 1, 0.5).last = true
		n:addElem("float", 6, "Smart Range", 0, 1, 0.2).first = true
		n:addElem("float", 7, "Fall-off", 0, 1, 0.5)
		n:addElem("bool", 8, "Smart Patch", false)

		n.data.tweak = require "ui.widget.tweak"("paint", n.elem[4], n.elem[5], n.elem[2])
		n.data.tweak.toolButton(n, 1, "Paint")

		n:addElem("button", 9, "Load", function()
			local f = io.open("mask.bin", "rb")
			local header = f:read(6*4)
			local header_uint8 = ffi.new("uint8_t[6*4]", header)
			header = ffi.cast("uint32_t*", header_uint8)
			local x, y, z = header[0], header[1], header[2]
			local sx, sy, sz = header[3], header[4], header[5]

			local imgData = f:read("*a")
			imgData = love.data.decompress("string", "lz4", imgData)

			local img = data:new(x, y, z):allocHost()
			img.sx = sx
			img.sy = sy
			img.sz = sz
			ffi.copy(img.data, imgData)
			img:toDevice(true)

			n.mask = pool.add(img)
			n.dirty = true
		end)

		-- TODO: implement auto-save
		n:addElem("button", 10, "Save", function()
			n.mask:set()

			local img = n.mask.full

			local x, y, z = img.x, img.y, img.z
			local sx, sy, sz = img.sx, img.sy, img.sz

			local header = ffi.new("uint32_t[6]", x, y, z, sx, sy, sz)

			local f = io.open("mask.bin", "wb")
			f:write(ffi.string(header, 6*4))

			local data = love.data.compress("string", "lz4", ffi.string(img.data, x*y*z*4))
			f:write(data)
			f:close()
		end)

		-- FIXME: the node needs to be updated on image resize/move for the image pool resize to trigger when no input connected (not in smart mode)
		n.refresh = true

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
	local r = t.inputParam(self, 2)
	local o = t.autoOutput(self, 0, i:shape())
	local hq = t.plainParam(self, 3)
	local s = t.inputParam(self, 5)
	local h = t.inputParam(self, 6)

	thread.ops.localLaplacian_protect({i, d, r, o, hq, s, h}, self)
end

function ops.localLaplacian(x, y)
	local n = node:new("Detail")
	n:addPortIn(0, "XYZ"):addPortOut(0, "XYZ")
	n:addPortIn(1, "Y"):addElem("float", 1, "Detail", -1, 1, 0)
	n:addPortIn(2, "Y"):addElem("float", 2, "Range", 0, 1, 0.2)
	n:addElem("bool", 3, "HQ", false)
	n:addElem("label", 4, "Protect:")
	n:addPortIn(5, "Y"):addElem("float", 5, "Shadows", 0, 1, 0)
	n:addPortIn(6, "Y"):addElem("float", 6, "Highlights", 0, 1, 0)
	n.process = localLaplacianProcess
	n:setPos(x, y)
	return n
end

local function watershedProcess(self)
	self.procType = "dev"
	local i = t.inputSourceWhite(self, 0)
	local x, y = i:shape()
	local m1 = t.inputSourceBlack(self, 1)
	local m2 = t.inputSourceBlack(self, 2)
	local o = t.autoOutput(self, 0, x, y, 1)
	local hq = t.plainParam(self, 3)

	thread.ops.watershed({i, m1, m2, o, hq}, self)
end

function ops.watershed(x, y)
	local n = node:new("Watershed")
	n:addPortIn(0, "LAB"):addPortOut(0, "Y")
	n:addPortIn(1, "Y"):addElem("text", 1, "Mask A")
	n:addPortIn(2, "Y"):addElem("text", 2, "Mask B")
	n:addElem("bool", 3, "HQ", false)
	n.process = watershedProcess
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
	n.data.histogram = data:new(256, 1, 4):allocHost():hostWritten()
	n.compute = true
	require "ui.graph".histogram(n)
	n:setPos(x, y)
	return n
end

local function waveformProcess(self)
	self.procType = "dev"
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

	n.elem.cols = 2
	n:setPos(x, y)
	
	return n
end

local function ABplotProcess(self)
	self.procType = "dev"
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

	n.elem.cols = 2
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

	h = h==1 and 2 or math.max(math.floor(h / w * 150), 50)
	if self.data.preview.y ~= h*settings.scaleUI then
		require "thread".keepData(self.data.preview)
		self.data.preview = require "ui.image":new(150*settings.scaleUI, h*settings.scaleUI)
		self.data.preview.scale = 1/settings.scaleUI
		self.graph.h = h
	end

	thread.ops.preview({i, self.data.preview}, self)
end

function ops.preview(x, y)
	local n = node:new("Preview")
	n:addPortIn(0, "ANY")
	n.process = previewProcess
	require "ui.graph".preview(n)
	local w, h = t.imageShape()
	h = h==1 and 2 or math.max(math.floor(h / w * 150), 50)
	n.data.preview = require "ui.image":new(150*settings.scaleUI, h*settings.scaleUI)
	n.data.preview.scale = 1/settings.scaleUI
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
		thread.ops.stat_maximum({i, o}, self)
	end
	function ops.stat.maximum(x, y)
		local n = node:new("Maximum")
		n:addPortIn(0, "LRGB")
		n:addPortOut(0, "LRGB")
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
		thread.ops.stat_minimum({i, o}, self)
	end
	function ops.stat.minimum(x, y)
		local n = node:new("Minimum")
		n:addPortIn(0, "LRGB")
		n:addPortOut(0, "LRGB")
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
		thread.ops.stat_mean({i, o}, self)
	end
	function ops.stat.mean(x, y)
		local n = node:new("Mean")
		n:addPortIn(0, "LRGB")
		n:addPortOut(0, "LRGB")
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
		thread.ops.stat_sad({a, b, o}, self)
	end
	function ops.stat.SAD(x, y)
		local n = node:new("SAD")
		n:addPortIn(1, "LRGB"):addElem("text", 1, "A", "∑|A-B| / N")
		n:addPortIn(2, "LRGB"):addElem("text", 2, "B")
		n:addPortOut(1, "LRGB")
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
		thread.ops.stat_ssd({a, b, o}, self)
	end
	function ops.stat.SSD(x, y)
		local n = node:new("SSD")
		n:addPortIn(1, "LRGB"):addElem("text", 1, "A", "∑(A-B)² / N")
		n:addPortIn(2, "LRGB"):addElem("text", 2, "B")
		n:addPortOut(1, "LRGB")
		n.process = proc
		n.w = 75
		n:setPos(x, y)
		return n
	end

end

local function adjustProcess(self)
	self.procType = "dev"
	assert(self.portOut[0].link)
	local i, e, b, c, v, o
	i = t.inputSourceBlack(self, 0)
	e = t.inputParam(self, 1)
	b = t.inputParam(self, 2)
	c = t.inputParam(self, 3)
	v = t.inputParam(self, 4)
	o = t.autoOutput(self, 0, data.superSize(i, e, b, c, v))
	thread.ops.adjust_basic({i, e, b, c, v, o}, self)
end

function ops.adjust_basic(x, y)
	local n = node:new("Adjust")
	n:addPortIn(0, "LRGB")
	n:addPortIn(1, "Y"):addElem("float", 1, "Exposure", -3.3333, 3.3333, 0)
	n:addPortIn(2, "Y"):addElem("float", 2, "Brightness", 0, 2, 1)
	n:addPortIn(3, "Y"):addElem("float", 3, "Contrast", 0, 2, 1)
	n:addPortIn(4, "Y"):addElem("float", 4, "Vibrance", 0, 2, 1)
	n:addPortOut(0, "LRGB")
	n.process = adjustProcess
	n:setPos(x, y)
	return n
end

local function exposureProcess(self)
	self.procType = "dev"
	assert(self.portOut[0].link)
	local i, e, o
	i = t.inputSourceBlack(self, 0)
	e = t.inputParam(self, 1)
	o = t.autoOutput(self, 0, data.superSize(i, e))
	thread.ops.exposure({i, e, o}, self)
end

function ops.exposure(x, y)
	local n = node:new("Exposure")
	n:addPortIn(0, "LRGB")
	n:addPortIn(1, "LRGB"):addElem("float", 1, "Exposure", -3.3333, 3.3333, 0)
	n:addPortOut(0, "LRGB")
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
	thread.ops.brightness({i, b, o}, self)
end

function ops.brightness(x, y)
	local n = node:new("Brightness")
	n:addPortIn(0, "XYZ")
	n:addPortOut(0, "XYZ")
	n:addPortIn(1, "Y"):addElem("float", 1, "Brightness", 0, 2, 1)
	n.process = brightnessProcess
	n:setPos(x, y)
	return n
end

local function vibranceProcess(self)
	self.procType = "dev"
	assert(self.portOut[0].link)
	local i, v, o
	i = t.inputSourceBlack(self, 0)
	v = t.inputParam(self, 1)
	o = t.autoOutput(self, 0, data.superSize(i, v))
	thread.ops.vibrance({i, v, o}, self)
end

function ops.vibrance(x, y)
	local n = node:new("Vibrance")
	n:addPortIn(0, "LRGB")
	n:addPortOut(0, "LRGB")
	n:addPortIn(1, "Y"):addElem("float", 1, "Vibrance", 0, 2, 1)
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
	n:addPortIn(0, "XYZ")
	n:addPortIn(1, "Y"):addElem("float", 1, "Saturation", 0, 2, 1)
	n:addPortOut(0, "XYZ")
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
	thread.ops.levels({i, bpi, wpi, g, bpo, wpo, o}, self)
end

function ops.levels(x, y)
	local n = node:new("Levels")
	n:addPortIn(0, "LRGB")
	n:addPortOut(0, "LRGB")
	n:addPortIn(1, "Y"):addElem("float", 1, "Black in", 0, 1, 0)
	n:addPortIn(2, "Y"):addElem("float", 2, "White in", 0, 1, 1)
	n:addPortIn(3, "Y"):addElem("float", 3, "Gamma", 0, 1, 0.5)
	n:addPortIn(4, "Y"):addElem("float", 4, "Black out", 0, 1, 0)
	n:addPortIn(5, "Y"):addElem("float", 5, "White out", 0, 1, 1)
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
	thread.ops.mix({p1, p2, p3, p4}, self)
end

function ops.mix(x, y)
	local n = node:new("Mix")
	n:addPortIn(1, "LRGB"):addElem("float", 1, "A", 0, 1, 0)
	n:addPortIn(2, "LRGB"):addElem("float", 2, "B", 0, 1, 0)
	n:addPortIn(3, "LRGB"):addElem("float", 3, "Factor", 0, 1, 1)
	n:addPortOut(0, "LRGB")
	n.process = mixProcess
	n.w = 75
	n:setPos(x, y)
	return n
end

do
	local lutEnum = {"Precisa", "Vista", "Astia", "Provia", "Sensia", "Superia", "Velvia", "Ektachrome", "Kodachrome", "Portra"}

	local function lutColorProcess(self)
		self.procType = "dev"

		local lutValue = self.elem[1].value
		local lutName = lutEnum[lutValue]
		if self.data.lutLoaded ~= lutValue then
			require "ui.notice".blocking("Loading look: "..lutName)
			if self.data.lut then
				self.data.lut:freeDev()
			end
			self.data.lut = require("io.native").read("looks/"..lutName..".png"):syncDev()
			self.data.lutLoaded = lutValue
		end

		assert(self.portOut[0].link)
		local p1, p2, p3, p4
		p1 = t.inputSourceBlack(self, 0)
		p2 = self.data.lut
		p3 = t.autoOutput(self, 0, p1:shape())
		p4 = t.inputParam(self, 2)
		thread.ops.lut({p1, p2, p3, p4}, self)
	end

	function ops.lutColor(x, y)
		local n = node:new("Color LUT")

		n.data.lutLoaded = 0
		n:addPortIn(0, "LRGB"):addPortOut(0, "LRGB")
		n:addElem("enum", 1, "LUT", lutEnum, 1)
		n:addPortIn(2, "Y"):addElem("float", 2, "Mix", 0, 2, 1)

		n.process = lutColorProcess
		n:setPos(x, y)
		return n
	end
end

do
	local lutEnum = {"Neopan", "Delta", "Tri-X"}

	local function lutBWProcess(self)
		self.procType = "dev"

		local lutValue = self.elem[1].value
		local lutName = lutEnum[lutValue]
		if self.data.lutLoaded ~= lutValue then
			require "ui.notice".blocking("Loading look: "..lutName)
			if self.data.lut then
				self.data.lut:freeDev()
			end
			self.data.lut = require("io.native").read("looks/"..lutName..".png"):syncDev()
			self.data.lutLoaded = lutValue
		end

		assert(self.portOut[0].link)
		local p1, p2, p3, p4
		p1 = t.inputSourceBlack(self, 0)
		p2 = self.data.lut
		p3 = t.autoOutput(self, 0, p1:shape())
		p4 = t.inputParam(self, 2)
		thread.ops.lut({p1, p2, p3, p4}, self)
	end

	function ops.lutBW(x, y)
		local n = node:new("B/W LUT")

		n.data.lutLoaded = 0
		n:addPortIn(0, "LRGB"):addPortOut(0, "LRGB")
		n:addElem("enum", 1, "LUT", lutEnum, 1)
		n:addPortIn(2, "Y"):addElem("float", 2, "Mix", 0, 2, 1)

		n.process = lutBWProcess
		n:setPos(x, y)
		return n
	end
end

local function loadImage(image)
	require "ui.notice".blocking("Loading image: "..(type(image) == "string" and image or image:getFilename()), true)
	return require("io.im").read(image):syncDev()
end

local pool = require "tools.imagePool"

local function imageProcess(self)
	self.procType = "dev"

	local link = self.portOut[0].link
	if link then
		link.data = self.data.image:get()
		link:setData("LRGB", self.procType)

		--force copy CS conversion!
		link.forceCopyConvert = true

		--TODO: read-only image pool

		self.state = "ready"
	end
end


function ops.image(x, y, image)
	local n = node:new("Image")
	n.data.imageName = image or "img.jpg"

	do
		local sx, sy = t.imageShape()
		local image = loadImage(n.data.imageName)
		pool.resize(sx, sy)
		n.data.image = pool.add(image)
	end

	n.data.imageName = image
	n:addPortOut(0, "LRGB")
	n:addElem("text", 1, n.data.imageName or "-", "")
	n:addElem("button", 2, "Open", function()
		n.data.imageName = require "lib.fileDialog".fileOpen()
		local image = loadImage(n.data.imageName)
		n.data.image = pool.add(image)
		n.elem[1].left = n.data.imageName:gsub("^.*[/\\]", "")
		n.dirty = true
	end)

	n.refresh = true
	n.process = imageProcess
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

local function splitProcess(self)
	self.procType = "dev"
	local i, o1, o2, o3
	i = t.inputSourceBlack(self, 0)
	o1 = t.autoOutputSink(self, 1, i.x, i.y, 1)
	o2 = t.autoOutputSink(self, 2, i.x, i.y, 1)
	o3 = t.autoOutputSink(self, 3, i.x, i.y, 1)
	thread.ops.splitCS({i, o1, o2, o3}, self)
end

local function genSplit(cs)
	return function (x, y)
		local n = node:new(channelNames[cs][1])
		n:addPortIn(0, cs)
		n:addPortOut(1, "Y"):addElem("text", 1, "", channelNames[cs][2])
		n:addPortOut(2, "Y"):addElem("text", 2, "", channelNames[cs][3])
		n:addPortOut(3, "Y"):addElem("text", 3, "", channelNames[cs][4])
		n.process = splitProcess
		n.w = 75
		n:setPos(x, y)
		return n
	end
end

ops.splitSRGB = genSplit("SRGB")
ops.splitLRGB = genSplit("LRGB")
ops.splitXYZ = genSplit("XYZ")
ops.splitLAB = genSplit("LAB")
ops.splitLCH = genSplit("LCH")

local function mergeProcess(self)
	self.procType = "dev"
	local i1, i2, i3, o
	i1 = t.inputParam(self, 1)
	i2 = t.inputParam(self, 2)
	i3 = t.inputParam(self, 3)
	local x, y, z = data.superSize(i1, i2, i3)
	o = t.autoOutput(self, 0, x, y, 3)
	thread.ops.mergeCS({i1, i2, i3, o}, self)
end

local function genMerge(cs)
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
		n.process = mergeProcess
		n.w = 75
		n:setPos(x, y)
		return n
	end
end

ops.mergeSRGB = genMerge("SRGB")
ops.mergeLRGB = genMerge("LRGB")
ops.mergeXYZ = genMerge("XYZ")
ops.mergeLAB = genMerge("LAB")
ops.mergeLCH = genMerge("LCH")




local function mixRGBProcess(self)
	self.procType = "dev"
	local r = t.autoTempBuffer(self, 1, 1, 1, 3)
	local g = t.autoTempBuffer(self, 2, 1, 1, 3)
	local b = t.autoTempBuffer(self, 3, 1, 1, 3)
	r:set(0, 0, 0, self.elem[1].value)
	r:set(0, 0, 1, self.elem[2].value)
	r:set(0, 0, 2, self.elem[3].value)
	g:set(0, 0, 0, self.elem[4].value)
	g:set(0, 0, 1, self.elem[5].value)
	g:set(0, 0, 2, self.elem[6].value)
	b:set(0, 0, 0, self.elem[7].value)
	b:set(0, 0, 1, self.elem[8].value)
	b:set(0, 0, 2, self.elem[9].value)
	local i, o, r, g, b
	i = t.inputSourceBlack(self, 0)
	r = t.inputData(self, 1)
	g = t.inputData(self, 2)
	b = t.inputData(self, 3)
	o = t.autoOutput(self, 0, data.superSize(i, r, g, b))
	thread.ops.mixrgb({i, o, r, g, b}, self)
end

function ops.mixRGB(x, y)
	local n = node:new("Mix RGB")
	n:addPortIn(0, "LRGB")
	n:addPortIn(1, "LRGB")
	n:addPortIn(2, "LRGB")
	n:addPortIn(3, "LRGB")
	n:addPortOut(0, "LRGB")
	n.portIn[1].toggle = {[1] = false, [2] = false, [3] = false}
	n.portIn[2].toggle = {[4] = false, [5] = false, [6] = false}
	n.portIn[3].toggle = {[7] = false, [8] = false, [9] = false}

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

	n.elem.cols = 3
	n.w = 200
	n:setPos(x, y)

	return n
end

local function mixBWProcess(self)
	self.procType = "dev"
	local r = t.inputParam(self, 1)
	local g = t.inputParam(self, 2)
	local b = t.inputParam(self, 3)
	local i, o
	i = t.inputSourceBlack(self, 0)
	local x, y, z = data.superSize(i, r, g, b)
	o = t.autoOutput(self, 0, x, y, 1)
	o.cs = "Y"
	thread.ops.mixbw({i, o, r, g, b}, self)
end

function ops.mixBW(x, y)
	local n = node:new("Mix RGB")
	n:addPortIn(0, "LRGB")
	n:addPortIn(1, "Y")
	n:addPortIn(2, "Y")
	n:addPortIn(3, "Y")
	n:addPortOut(0, "Y")

	n:addElem("float", 1, "Red", - 2, 3, 1)
	n:addElem("float", 2, "Green", - 2, 3, 1)
	n:addElem("float", 3, "Blue", - 2, 3, 1)
	n.process = mixBWProcess

	n:setPos(x, y)
	return n
end

local downsize = require "tools.downsize"

-- TODO: allocate temporary buffers in scheduler only
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
	local n = t.autoTempBuffer(self, -1, 1, 1, 1)
	n:set(0, 0, 0, self.elem[1].value) -- CPU-only buffer, no sync!
	thread.ops.blur({i, o, n}, self)
end

function ops.blur(x, y)
	local n = node:new("Blur")
	n:addPortIn(0, "LRGB")
	n:addPortOut(0, "LRGB")
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
	thread.ops.bokeh({i, r, o, h}, self)
end

function ops.bokeh(x, y)
	local n = node:new("Bokeh")
	n:addPortIn(0, "LRGB")
	n:addPortOut(0, "LRGB")
	n:addPortIn(1, "Y"):addElem("float", 1, "Radius", 0, 1, 0.1)
	n:addElem("bool", 2, "Hexagonal", false)
	n.process = bokehProcess
	n:setPos(x, y)
	return n
end

local function RLdeconvolutionProcess(self)
	self.procType = "dev"
	local i, o, w, f, d, oc, it, aa
	i = t.inputSourceBlack(self, 0)
	o = t.autoOutput(self, 0, i:shape())
	w = t.inputParam(self, 1)
	f = t.inputParam(self, 2)
	d = t.inputParam(self, 3)
	local oc_val = math.tan(self.elem[4].value*0.5*math.pi)
	oc = t.autoTempBuffer(self, 4, 1, 1, 1)
	it = t.plainParam(self, 5)
	aa = t.plainParam(self, 6)
	oc:set(0, 0, 0, oc_val):syncDev()
	thread.ops.sharpen_deconv({i, o, w, f, d, oc, it, aa}, self)
end

function ops.RLdeconvolution(x, y)
	local n = node:new("RL-Deconv.")
	n:addPortIn(0, "LAB")
	n:addPortOut(0, "LAB")
	n:addPortIn(1, "Y"):addElem("float", 1, "Radius", 0, 2, 0.8)
	n:addPortIn(2, "Y"):addElem("float", 2, "Strength", 0, 5, 2)
	n:addPortIn(3, "Y"):addElem("float", 3, "Dampen", 0, 0.5, 0)
	n:addElem("float", 4, "Overshoot", 0, 1, 0.5)
	n:addElem("int", 5, "Iterations", 5, 50, 10, 5)
	n:addElem("bool", 6, "OLPF kernel", false)
	n.process = RLdeconvolutionProcess
	n:setPos(x, y)
	return n
end

local function shockFilterProcess(self)
	self.procType = "dev"
	local i, o, w, f, oc
	i = t.inputSourceBlack(self, 0)
	o = t.autoOutput(self, 0, i:shape())
	w = t.inputParam(self, 1)
	f = t.inputParam(self, 2)
	oc = t.plainParam(self, 3)
	thread.ops.shockFilter({i, o, w, f, oc}, self)
end

function ops.shockFilter(x, y)
	local n = node:new("Shock Filter")
	n:addPortIn(0, "LAB")
	n:addPortOut(0, "LAB")
	n:addPortIn(1, "Y"):addElem("float", 1, "Radius", 0, 1, 0.5)
	n:addPortIn(2, "Y"):addElem("float", 2, "Strength", 0, 1, 0.2)
	n:addElem("float", 3, "Overshoot", 0, 2, 0.5)
	n.process = shockFilterProcess
	n:setPos(x, y)
	return n
end

local function sharpenProcess(self)
	self.procType = "dev"
	local i, r, s, o
	i = t.inputSourceBlack(self, 0)
	r = t.inputParam(self, 1)
	s = t.inputParam(self, 2)
	o = t.autoOutput(self, 0, i:shape())
	thread.ops.sharpen_usm({i, r, s, o}, self)
end

function ops.sharpen(x, y)
	local n = node:new("Sharpen")
	n:addPortIn(0, "LAB")
	n:addPortOut(0, "LAB")
	n:addPortIn(1, "Y"):addElem("float", 1, "Radius", 0, 2, 0.8)
	n:addPortIn(2, "Y"):addElem("float", 2, "Strength", 0, 5, 1)
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

	local p5 = t.plainParam(self, 5)

	local p4 = t.autoTempBuffer(self, 4, 1, 1, 3)
	p4:set(0, 0, 0, self.elem[7].value)
	p4:set(0, 0, 1, self.elem[8].value)
	local kernel = t.autoTempBuffer(self, 5, 1, 1, 15)
	local sum = 0
	for i = -7, 7 do
		local v = math.norm(i, self.elem[6].value)
		sum = sum + v
		kernel:set(0, 0, i+7, v)
	end
	for i = 0, 14 do
		local v = kernel:get(0, 0, i)
		v = v / sum
		kernel:set(0, 0, i, v)
	end
	kernel:syncDev(true)

	local x, y, z = data.superSize(i, p1, p2, p3)

	local o = t.autoOutput(self, 0, x, y, z)
	thread.ops.nlmeans({i, p1, p2, p3, p4, p5, kernel, o}, self)
end

function ops.nlmeans(x, y)
	local n = node:new("Denoise")
	n:addPortIn(0, "XYZ")
	n:addPortOut(0, "XYZ")
	n:addPortIn(1, "Y"):addElem("float", 1, "Luminance", 0, 1, 0.5)
	n:addPortIn(2, "Y"):addElem("float", 2, "Chrominance", 0, 1, 0.5)
	n:addPortIn(3, "Y"):addElem("float", 3, "Mask", 0, 1, 1)
	n:addElem("label", 4, "Advanced")
	n:addElem("float", 5, "Gaussian Mix", 0, 1, 0)
	n:addElem("float", 6, "Kernel Size", 1, 5, 3)
	n:addElem("int", 7, "Range", 5, 50, 10, 5)
	n:addElem("bool", 8, "Random Sample", false)
	n.process = nlmeansProcess
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
		thread.ops[fn]({i1, i2, o}, self)
	end

	ops.math[name] = function(x, y)
		local n = node:new(name)
		n:addPortIn(0, "LRGB")
		n:addPortIn(1, "LRGB"):addElem("float", 1, "", min or -2, max or 2, init)
		n:addPortOut(0, "LRGB")
		n.process = process
		n.w = 75
		n:setPos(x, y)
		return n
	end
end

genMath1("Absolute", "ivy_abs")
genMath1("Negative", "ivy_neg")
genMath1("Invert", "ivy_inv")
genMath1("Clamp", "ivy_clamp")

genMath2("Add", "ivy_add", 0)
genMath2("Subtract", "ivy_sub", 0)
genMath2("Multiply", "ivy_mul", 1)
genMath2("Divide", "ivy_div", 1)
genMath2("Power", "ivy_pow", 1, 0, 2)
genMath2("Maximum", "ivy_max", 0, 0, 1)
genMath2("Minimum", "ivy_min", 1, 0, 1)
genMath2("Average", "ivy_average", 0, 0, 1)
genMath2("Difference", "ivy_difference", 0, 0, 1)
genMath2("Greater", "ivy_GT", 0.5, 0, 1)
genMath2("Less", "ivy_LT", 0.5, 0, 1)

local function processValue(self)
	local o = t.autoOutput(self, 0, 1, 1, 1)
	local v = tonumber(self.elem[1].value)
	o:set(0, 0, 0, v)
	o:syncDev()
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
	end

	ops.blend[func] = function(x, y)
		local n = node:new(name)
		n:addPortIn(0, "LRGB")
		n:addPortIn(1, "LRGB"):addElem("text", 1, "Blend Layer")
		n:addPortIn(2, "Y"):addElem("float", 2, "Mix", 0, 1, 1)
		n:addPortOut(0, "LRGB")
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
