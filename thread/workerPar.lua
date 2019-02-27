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

require "setup"

global("settings")
if love.filesystem.isFused() then
	if love.filesystem.mount(love.filesystem.getSourceBaseDirectory(), "base") then
		settings = require "base.settings"
	end
else
	settings = require "settings"
end

-- OpenCL processing functions
local ffi = require "ffi"

local data = require "data"
local image = require "ui.image"

local cs = require "tools.cs"

local args = {...}

local threadNum = args[1]
local threadMax = args[2]

local dataCh = love.thread.getChannel("dataCh_worker"..threadNum)
local syncCh = love.thread.getChannel("syncCh_worker"..threadNum)

local function round(x)
	return math.floor(x+0.5)
end

-- ISPC implementation of display
assert(jit.arch=="x64", "Only x64 support yet")
local ispc
if jit.os == "Windows" then
	ispc = ffi.load "ops/ispc/Windows/preview.dll"
elseif jit.os == "Linux" then
	ispc = ffi.load "ops/ispc/Linux/preview.so"
end
ffi.cdef [[
  void preview(dataStruct*, imageStruct*, int, int);
	void crop(dataStruct*, dataStruct*, dataStruct*, int, int);
	void cropCorrect(dataStruct*, dataStruct*, dataStruct*, int, int);
]]

local ispc_cs
if jit.os == "Windows" then
	ispc_cs = ffi.load "ops/ispc/Windows/cs.dll"
elseif jit.os == "Linux" then
	ispc_cs = ffi.load "ops/ispc/Linux/cs.so"
end
ffi.cdef [[
	void LRGB_SRGB(dataStruct*, dataStruct*, int, int);
	void SRGB_LRGB(dataStruct*, dataStruct*, int, int);
	void LRGB_XYZ(dataStruct*, dataStruct*, int, int);
	void XYZ_LRGB(dataStruct*, dataStruct*, int, int);
	void LAB_XYZ(dataStruct*, dataStruct*, int, int);
	void XYZ_LAB(dataStruct*, dataStruct*, int, int);
	void LAB_LCH(dataStruct*, dataStruct*, int, int);
	void LCH_LAB(dataStruct*, dataStruct*, int, int);
]]


local function getData()
	local d = dataCh:demand()
	assert(type(d)=="table")
	return data.fromChTable(d)
end

local function getImage()
	local d = dataCh:demand()
	assert(type(d)=="table")
	return image.fromChTable(d)
end

local function getCData()
	local d = dataCh:demand()
	assert(type(d)=="table")
	return data.fromChTable(d):toCStruct()
end

local function getCImage()
	local d = dataCh:demand()
	assert(type(d)=="table")
	return image.fromChTable(d):toCStruct()
end


local ops = {}

function ops.sync()
	syncCh:supply("sync")
	assert(syncCh:demand()=="resume")
end


function ops.rmse()
	local p1 = getData()
	local p2 = getData()
	local p3 = getData()
	local p4 = getData()
	assert(dataCh:demand()=="execute")

	local xmax = math.max(p1.x, p2.x)
	local ymax = math.max(p1.y, p2.y)
	local zmax = math.max(p1.z, p2.z)

	local s = 0
	for y = threadNum, p1.y - 1, threadMax do
		for x = 0, p1.x - 1 do
			local v1 = p1:get(x, y, 0) - p2:get(x, y, 0)
			local v2 = p1:get(x, y, 1) - p2:get(x, y, 1)
			local v3 = p1:get(x, y, 2) - p2:get(x, y, 2)
			s = s + v1*v1 + v2*v2 + v3*v3
		end
	end
	-- store in temp buffer of 8 long
	p3:set(0, 0, threadNum, s)

	ops.sync()

	-- gather final
	if threadNum==0 then
		local s = 0
		for x = 0, threadMax - 1 do
			s = s + p3:get(0, 0, x)
		end
		p4:set(0, 0, 0, math.sqrt(s/(xmax*ymax*zmax)))
	end

	syncCh:supply("step")
end


function ops.add()
	local p1 = getData()
	local p2 = getData()
	local p3 = getData()
	assert(dataCh:demand()=="execute")

	for y = threadNum, p3.y - 1, threadMax do
		for x = 0, p3.x - 1 do
			p3:set(x, y, 0, p1:get(x, y, 0) + p2:get(x, y, 0))
			p3:set(x, y, 1, p1:get(x, y, 1) + p2:get(x, y, 1))
			p3:set(x, y, 2, p1:get(x, y, 2) + p2:get(x, y, 2))
		end
	end

	syncCh:supply("step")
end


function ops.xy()
	local X = getData()
	local Y = getData()
	assert(dataCh:demand()=="execute")

	local xmax = math.max(X.x, Y.x)
	local ymax = math.max(X.y, Y.y)
	local zmax = math.max(X.z, Y.z)

	for z = 0, zmax - 1 do
		for y = threadNum, ymax - 1, threadMax do
			for x = 0, xmax - 1 do
				X:set(x, y, z, x/xmax)
				Y:set(x, y, z, y/ymax)
			end
		end
	end

	syncCh:supply("step")
end


function ops.contrast()
	local p1 = getData()
	local p2 = getData()
	local p3 = getData()
	local p4 = getData()
	assert(dataCh:demand()=="execute")

	local step = p3.y/threadMax
	local y0 = round(step*threadNum)
	local y1 = round(step*(threadNum+1))

	for y = y0, y1-1 do
		for x = 0, p3.x-1 do
			local i = p1:get(x, y, 0)
			local a = p1:get(x, y, 1)
			local b = p1:get(x, y, 2)

			local factor = p2:get(x, y, 0)*0.5

			local balance = 0.5
			local width = 4
			local o = math.tanh(width*i-balance*width)*factor*0.5 + factor*0.5 + (1-factor)*i

			local cf = -factor + 0.5*balance*width*width*factor*math.cosh(balance*width-width*i)^(-2)
			cf = p4:get(x, y, 0)*cf + 1
			--local cf = p4:get(x, y, 0)*(1-math.tanh(4*i-2)^2)*c*0.5 + 1
			p3:set(x, y, 0, o)
			p3:set(x, y, 1, a*cf)
			p3:set(x, y, 2, b*cf)
		end
	end

	syncCh:supply("step")
end


function ops.brightness()
	local p1 = getData()
	local p2 = getData()
	local p3 = getData()
	assert(dataCh:demand()=="execute")

	local step = p3.y/threadMax
	local y0 = round(step*threadNum)
	local y1 = round(step*(threadNum+1))

	local s = 1/math.tanh(3)

	for z = 0, p3.z-1 do
		for y = y0, y1-1 do
			for x = 0, p3.x - 1 do
				local i = p1:get(x, y, z)
				local b = p2:get(x, y, 0)

				local o = math.tanh(i*3)*b*s + i*(1-b)

				p3:set(x, y, z, o)
			end
		end
	end

	syncCh:supply("step")
end

--[[
function ops.brightnessLAB()
	local p1 = getData()
	local p2 = getData()
	local p3 = getData()
	assert(dataCh:demand()=="execute")

	local step = p3.y/threadMax
	local y0 = round(step*threadNum)
	local y1 = round(step*(threadNum+1))

	ispc_cs.LRGB_XYZ(p1:toCStruct(), p3:toCStruct(), y0, y1)
	ispc_cs.XYZ_LAB(p3:toCStruct(), p3:toCStruct(), y0, y1)

	for y = y0, y1-1 do
		for x = 0, p3.x - 1 do
			local i = p3:get(x, y, 0)
			local b = p2:get(x, y, 0)

			local o = math.tanh(i*3)*b + i*(1-b)

			p3:set(x, y, 0, o)
		end
	end

	ispc_cs.LAB_XYZ(p3:toCStruct(), p3:toCStruct(), y0, y1)
	ispc_cs.XYZ_LRGB(p3:toCStruct(), p3:toCStruct(), y0, y1)

	syncCh:supply("step")
end
--]]

function ops.vibrance()
	local p1 = getData()
	local p2 = getData()
	local p3 = getData()
	assert(dataCh:demand()=="execute")

	local step = p3.y/threadMax
	local y0 = round(step*threadNum)
	local y1 = round(step*(threadNum+1))

	for y = y0, y1-1 do
		for x = 0, p3.x - 1 do
			local l = p1:get(x, y, 0)
			local i = p1:get(x, y, 1)
			local h = p1:get(x, y, 2)
			local v = p2:get(x, y, 0)

			v = v*l

			local o = math.tanh(i*3)*v + i*(1-v)

			p3:set(x, y, 0, l)
			p3:set(x, y, 1, o)
			p3:set(x, y, 2, h)
		end
	end

	syncCh:supply("step")
end


function ops.crop()
	local p1 = getData()
	local p2 = getData()
	local p3 = getData()
	assert(dataCh:demand()=="execute")

	local ox = p3:get(0, 0, 0)
	local oy = p3:get(0, 0, 1)
	local s  = p3:get(0, 0, 2)

	for y = threadNum, p2.y - 1, threadMax do
		for x = 0, p2.x - 1 do
			p2:set(x, y, 0, p1:nearest(x*s+ox, y*s+oy, 0))
			p2:set(x, y, 1, p1:nearest(x*s+ox, y*s+oy, 1))
			p2:set(x, y, 2, p1:nearest(x*s+ox, y*s+oy, 2))
		end
	end

	syncCh:supply("step")
end

-- TODO: get coefficients from lensfun database
-- TODO: include chromatic abberation
-- TODO: include vignetting
local a, b, c = 0.01989, -0.09761, 0.07461 -- implement undistortion (prototype for OLY 17mm f1.8)
local function rd(ru)
	return a*ru^4 + b*ru^3 + c*ru^2 + (1-a-b-c)*ru
end

local interpolation = "bilinear"
function ops.cropCorrect() -- distortion correction
	local p1 = getData()
	local p2 = getData()
	local p3 = getData()
	assert(dataCh:demand()=="execute")

	local ox = p3:get(0, 0, 0)
	local oy = p3:get(0, 0, 1)
	local s  = p3:get(0, 0, 2)

	local x_2 = p1.x/2
	local y_2 = p1.y/2
	local fn_1 = math.min(x_2, y_2) --normalization factor: half image height
	local fn = 1/fn_1 -- reverse factor

	-- TODO: additional scaling for maximizing image area

	-- FIXME: using different pixel access patterns requires a barrier between ops
	local step = p2.y/threadMax
	local y0 = round(step*threadNum)
	local y1 = round(step*(threadNum+1))

	for y = y0, y1 do
		local cy = y*s+oy

		for x = 0, p2.x - 1 do
			local cx = x*s+ox
			local cy = cy

			-- distortion correction
			local cxn, cyn = (cx - x_2)*fn, (cy - y_2)*fn -- normalized coordinates
			local r = math.sqrt(cxn^2 + cyn^2)
			-- FIXME: proper fix for division by 0!!!
			local sd = rd(r)/(r+1e-12) -- get scaling factor for r from the distortion correction function
			cx, cy = sd*cxn*fn_1 + x_2, sd*cyn*fn_1 + y_2 -- scale and revert normalization

			p2:set(x, y, 0, p1[interpolation](p1, cx, cy, 0))
			p2:set(x, y, 1, p1[interpolation](p1, cx, cy, 1))
			p2:set(x, y, 2, p1[interpolation](p1, cx, cy, 2))
		end
	end

	syncCh:supply("step")
end

local fwt = require "tools.freq.dwt"
function ops.fwtHaarForward()
	local p1 = getData()
	local p2 = getData()
	assert(dataCh:demand()=="execute")

	-- FIXME: threading issues, needs sync between horizontal and vertical pass, or single pass algorithm
	if threadNum==0 then
		fwt.haar.forward(p1, p2, 0, 0, 1)
		fwt.haar.forward(p2, p2, 1, 0, 1)
		fwt.haar.forward(p2, p2, 2, 0, 1)
		fwt.haar.forward(p2, p2, 3, 0, 1)
		fwt.haar.forward(p2, p2, 4, 0, 1)
	end

	syncCh:supply("step")
end

function ops.fwtHaarInverse()
	local p1 = getData()
	local p2 = getData()
	local f1 = getData()
	local f2 = getData()
	local f3 = getData()
	local f4 = getData()
	local f5 = getData()
	assert(dataCh:demand()=="execute")

	-- FIXME: threading issues
	if threadNum==0 then
		fwt.haar.inverse(p1, p2, 4, f5, 0, 1)
		fwt.haar.inverse(p2, p2, 3, f4, 0, 1)
		fwt.haar.inverse(p2, p2, 2, f3, 0, 1)
		fwt.haar.inverse(p2, p2, 1, f2, 0, 1)
		fwt.haar.inverse(p2, p2, 0, f1, 0, 1)
	end

	syncCh:supply("step")
end

--[[
function ops.adjustlch()
	local p1 = getData()
	local p2 = getData()
	local lf = getData()
	local cf = getData()
	local dh = getData()
	assert(dataCh:demand()=="execute")

	local step = p2.y/threadMax
	local y0 = round(step*threadNum)
	local y1 = round(step*(threadNum+1))

	ispc_cs.LRGB_XYZ(p1:toCStruct(), p2:toCStruct(), y0, y1)
	ispc_cs.XYZ_LAB(p2:toCStruct(), p2:toCStruct(), y0, y1)
	ispc_cs.LAB_LCH(p2:toCStruct(), p2:toCStruct(), y0, y1)

	for y = y0, y1-1 do
		for x = 0, p2.x - 1 do
			local l, c, h = p2:get(x, y, 0), p2:get(x, y, 1), p2:get(x, y, 2)

			local lf = lf:get(x, y, 0)
			local cf = cf:get(x, y, 0)
			local dh = dh:get(x, y, 0)
			l = l * lf
			c = c * cf
			h = h + dh

			p2:set(x, y, 0, l)
			p2:set(x, y, 1, c)
			p2:set(x, y, 2, h)
		end
	end

	ispc_cs.LCH_LAB(p2:toCStruct(), p2:toCStruct(), y0, y1)
	ispc_cs.LAB_XYZ(p2:toCStruct(), p2:toCStruct(), y0, y1)
	ispc_cs.XYZ_LRGB(p2:toCStruct(), p2:toCStruct(), y0, y1)

	syncCh:supply("step")
end
--]]

function ops.mixrgb()
	local p1 = getData()
	local p2 = getData()
	local r = getData()
	local g = getData()
	local b = getData()
	assert(dataCh:demand()=="execute")

	for y = threadNum, p1.y - 1, threadMax do
		for x = 0, p1.x - 1 do
			p2:set(x, y, 0, p1:get(x, y, 0) * r:get(x, y, 0) + p1:get(x, y, 1) * r:get(x, y, 1) + p1:get(x, y, 2) * r:get(x, y, 2))
			p2:set(x, y, 1, p1:get(x, y, 0) * g:get(x, y, 0) + p1:get(x, y, 1) * g:get(x, y, 1) + p1:get(x, y, 2) * g:get(x, y, 2))
			p2:set(x, y, 2, p1:get(x, y, 0) * b:get(x, y, 0) + p1:get(x, y, 1) * b:get(x, y, 1) + p1:get(x, y, 2) * b:get(x, y, 2))
		end
	end

	syncCh:supply("step")
end

function ops.mix()
	local p1 = getData()
	local p2 = getData()
	local p3 = getData()
	local p4 = getData()
	assert(dataCh:demand()=="execute")

	for y = threadNum, p1.y - 1, threadMax do
		for x = 0, p1.x - 1 do
			p4:set(x, y, 0, p1:get(x, y, 0)*p3:get(x, y, 0) + p2:get(x, y, 0)*(1-p3:get(x, y, 0)) )
			p4:set(x, y, 1, p1:get(x, y, 1)*p3:get(x, y, 1) + p2:get(x, y, 1)*(1-p3:get(x, y, 1)) )
			p4:set(x, y, 2, p1:get(x, y, 2)*p3:get(x, y, 2) + p2:get(x, y, 2)*(1-p3:get(x, y, 2)) )
		end
	end

	syncCh:supply("step")
end

function ops.invert()
	local p1 = getData()
	local p2 = getData()
	assert(dataCh:demand()=="execute")

	for y = threadNum, p1.y - 1, threadMax do
		for x = 0, p1.x - 1 do
			p2:set(x, y, 0, 1 - p1:get(x, y, 0))
			p2:set(x, y, 1, 1 - p1:get(x, y, 1))
			p2:set(x, y, 2, 1 - p1:get(x, y, 2))
		end
	end

	syncCh:supply("step")
end

function ops.gamma()
	local p1 = getData()
	local p2 = getData()
	local p3 = getData()
	assert(dataCh:demand()=="execute")

	for y = threadNum, p3.y - 1, threadMax do
		for x = 0, p3.x - 1 do
			p3:set(x, y, 0, math.pow(p1:get(x, y, 0), p2:get(x, y, 0)))
			p3:set(x, y, 1, math.pow(p1:get(x, y, 1), p2:get(x, y, 1)))
			p3:set(x, y, 2, math.pow(p1:get(x, y, 2), p2:get(x, y, 2)))
		end
	end

	syncCh:supply("step")
end

function ops.copy()
	local p1 = getData()
	local p2 = getData()
	assert(dataCh:demand()=="execute")

	for y = threadNum, p1.y - 1, threadMax do
		for x = 0, p1.x - 1 do
			p2:set(x, y, 0, p1:get(x, y, 0))
			p2:set(x, y, 1, p1:get(x, y, 1))
			p2:set(x, y, 2, p1:get(x, y, 2))
		end
	end

	syncCh:supply("step")
end

function ops.decompose()
	local p1 = getData()
	local p2 = getData()
	local p3 = getData()
	local p4 = getData()
	assert(dataCh:demand()=="execute")

	for y = threadNum, p1.y - 1, threadMax do
		for x = 0, p1.x - 1 do
			p2:set(x, y, 0, p1:get(x, y, 0))
			p3:set(x, y, 0, p1:get(x, y, 1))
			p4:set(x, y, 0, p1:get(x, y, 2))
		end
	end

	syncCh:supply("step")
end

function ops.compose()
	local p1 = getData()
	local p2 = getData()
	local p3 = getData()
	local p4 = getData()
	assert(dataCh:demand()=="execute")

	for y = threadNum, p4.y - 1, threadMax do
		for x = 0, p4.x - 1 do
			p4:set(x, y, 0, p1:get(x, y, 0))
			p4:set(x, y, 1, p2:get(x, y, 1))
			p4:set(x, y, 2, p3:get(x, y, 2))
		end
	end

	syncCh:supply("step")
end

function ops.display()
	local p1 = getData()
	local p2 = getImage()
	assert(dataCh:demand()=="execute")

	ops.sync()

	local step = p2.y/threadMax
	local y0 = round(step*threadNum)
	local y1 = round(step*(threadNum+1))

	ispc.preview(p1:toCStruct(), p2:toCStruct(), y0, y1)

	syncCh:push("done")
end

function ops.display_histogram()
	local p1 = getData()
	local p2 = getImage()
	local h = getData()
	assert(dataCh:demand()=="execute")

	jit.flush(true)

	ops.sync()

	local step = p2.y/threadMax
	local y0 = round(step*threadNum)
	local y1 = round(step*(threadNum+1))

	ispc.preview(p1:toCStruct(), p2:toCStruct(), y0, y1)

	for x = 0, 255 do
		h:set_u32(x, threadNum, 0, 0)
		h:set_u32(x, threadNum, 1, 0)
		h:set_u32(x, threadNum, 2, 0)
		h:set_u32(x, threadNum, 3, 0)
	end

	for y = y0, y1-1 do
		for x = 0, p2.x-1 do
			local r, g, b = p2:get(x, y, 0), p2:get(x, y, 1), p2:get(x, y, 2)
			local i = (0.2126*r + 0.7152*g + 0.0722*b) -- FIXME: implement luminance curve
			--r = math.clamp(r, 0, 255)
			--g = math.clamp(g, 0, 255)
			--b = math.clamp(b, 0, 255)
			--i = math.clamp(i, 0, 255)

			h:set_u32(r, threadNum, 0, h:get_u32(r, threadNum, 0) + 1)
			h:set_u32(g, threadNum, 1, h:get_u32(g, threadNum, 1) + 1)
			h:set_u32(b, threadNum, 2, h:get_u32(b, threadNum, 2) + 1)
			h:set_u32(i, threadNum, 3, h:get_u32(i, threadNum, 3) + 1)
		end
	end

	ops.sync()

	if threadNum==0 then
		for x = 0, 255 do
			for y = 1, threadMax-1 do
				h:set_u32(x, 0, 0, h:get_u32(x, 0, 0) + h:get_u32(x, y, 0))
				h:set_u32(x, 0, 1, h:get_u32(x, 0, 1) + h:get_u32(x, y, 1))
				h:set_u32(x, 0, 2, h:get_u32(x, 0, 2) + h:get_u32(x, y, 2))
				h:set_u32(x, 0, 3, h:get_u32(x, 0, 3) + h:get_u32(x, y, 3))
			end
		end
	end

	syncCh:push("done")
end

function ops.cropCorrect()
	local p1 = getCData()
	local p2 = getCData()
	local p3 = getCData()
	assert(dataCh:demand()=="execute")

	local step = p2.y/threadMax
	local y0 = round(step*threadNum)
	local y1 = round(step*(threadNum+1))

	ispc.cropCorrect(p1, p2, p3, y0, y1)

	syncCh:supply("step")
end

local pyr = require "tools.freq.pyr"
pyr.init(threadNum, threadMax, ops.sync)


function ops.clarity()
	local i = getData()
	local c = getData()
	local d = getData()
	local t = getData()
	local l0 = getData()
	local l1 = getData()
	local l2 = getData()
	local l3 = getData()
	local l4 = getData()
	local l5 = getData()
	local l6 = getData()
	local l7 = getData()
	local o = getData()
	assert(dataCh:demand()=="execute")

	pyr.down(i, t, l1)
	pyr.down(l1, t, l2)
	pyr.down(l2, t, l3)
	pyr.down(l3, t, l4)
	pyr.down(l4, t, l5)
	pyr.down(l5, t, l6)
	pyr.down(l6, t, l7)

	pyr.up(l7, t, l6)
	pyr.up(l6, t, l5)
	pyr.up(l5, t, l4)
	pyr.up(l4, t, l3)
	pyr.up(l3, t, l2)
	pyr.up(l2, t, l1)
	pyr.up(l1, t, o)

	local step = o.y/threadMax
	local y0 = round(step*threadNum)
	local y1 = round(step*(threadNum+1))

	for z = 0, o.z-1 do
		for y = y0, y1-1 do
			for x = 0, o.x-1 do
				local c = c:get(x, y, z)*2
				local d = d:get(x, y, z)
				local v = i:get(x, y, z)
				v = v + (1-v)*c*math.max(v - o:get(x, y, z), -d*0.2*v)

				o:set(x, y, z, v)
			end
		end
	end

	syncCh:supply("step")
end

-- TODO: combine highlight & shadow, add contrast
function ops.compress()
	local i = getData()
	local h = getData()
	local s = getData()
	local t = getData()
	local l0 = getData()
	local l1 = getData()
	local l2 = getData()
	local l3 = getData()
	local l4 = getData()
	local l5 = getData()
	local l6 = getData()
	local l7 = getData()
	local o = getData()
	assert(dataCh:demand()=="execute")

	local step = o.y/threadMax
	local y0 = round(step*threadNum)
	local y1 = round(step*(threadNum+1))

	pyr.down1(i, t, l1)
	pyr.down1(l1, t, l2)
	pyr.down1(l2, t, l3)
	pyr.down1(l3, t, l4)
	pyr.down1(l4, t, l5)
	pyr.down1(l5, t, l6)
	pyr.down1(l6, t, l7)

	pyr.up1(l7, t, l6)
	pyr.up1(l6, t, l5)
	pyr.up1(l5, t, l4)
	pyr.up1(l4, t, l3)
	pyr.up1(l3, t, l2)
	pyr.up1(l2, t, l1)
	pyr.up1(l1, t, o)

	for z = 0, 0 do
		for y = y0, y1-1 do
			for x = 0, o.x-1 do
				local j = i:get(x, y, z)
				local h = h:get(x, y, z)
				local s = s:get(x, y, z)
				local g = o:get(x, y, z)

				local vh = (1-h)*g + h*math.tanh(g) + (j-g)
				--vh = vh + (j-g)*(j-vh)

				local vs = (1-s)*g + s*(1+math.tanh(g-1)) + (j-g)
				--vs = vs + (g-j)*(j-vs)

				o:set(x, y, z, vh*j + vs*(1-j))
				o:set(x, y, 1, i:get(x, y, 1))
				o:set(x, y, 2, i:get(x, y, 2))
			end
		end
	end

	syncCh:supply("step")
end

function ops.structure()
	local i = getData()
	local h = getData()
	local t = getData()
	local l0 = getData()
	local l1 = getData()
	local l2 = getData()
	local l3 = getData()
	local l4 = getData()
	local l5 = getData()
	local l6 = getData()
	local l7 = getData()
	local o = getData()
	assert(dataCh:demand()=="execute")

	local step = o.y/threadMax
	local y0 = round(step*threadNum)
	local y1 = round(step*(threadNum+1))

	pyr.down1(i, t, l1)
	pyr.down1(l1, t, l2)
	pyr.down1(l2, t, l3)
	pyr.down1(l3, t, l4)
	pyr.down1(l4, t, l5)
	pyr.down1(l5, t, l6)
	pyr.down1(l6, t, l7)

	pyr.up1(l7, t, l6)
	pyr.up1(l6, t, l5)
	pyr.up1(l5, t, l4)
	pyr.up1(l4, t, l3)
	pyr.up1(l3, t, l2)
	pyr.up1(l2, t, l1)
	pyr.up1(l1, t, o)

	for z = 0, 0 do
		for y = y0, y1-1 do
			for x = 0, o.x-1 do
				local j = i:get(x, y, z)
				local h = h:get(x, y, z)
				local g = o:get(x, y, z)

				local d = h*2*(j-g)

				local v = j + math.min(d, 0)*(j) + math.max(d, 0)*(1-j)

				o:set(x, y, z, v)
				o:set(x, y, 1, i:get(x, y, 1))
				o:set(x, y, 2, i:get(x, y, 2))
				--if o.z==3 then --FIXME: 1-ch/3-ch data
				--end
			end
		end
	end

	syncCh:supply("step")
end

function ops.pyr2()
	local i = getData()
	local c = getData()
	local t = getData()
	local l0 = getData()
	local l1 = getData()
	local l2 = getData()
	local l3 = getData()
	local l4 = getData()
	local l5 = getData()
	local l6 = getData()
	local l7 = getData()
	local o = getData()
	assert(dataCh:demand()=="execute")

	local step = o.y/2/threadMax
	local y0 = round(step*threadNum)*2
	local y1 = round(step*(threadNum+1))*2

	laplacianPyrDown(i, t, l1, l0)
	laplacianPyrDown(l1, t, l2, l1)
	laplacianPyrDown(l2, t, l3, l2)
	laplacianPyrDown(l3, t, l4, l3)
	laplacianPyrDown(l4, t, l5, l4)
	laplacianPyrDown(l5, t, l6, l5)
	laplacianPyrDown(l6, t, l7, l6)

	laplacianPyrUp(l7, l6, t, l6, 1 + c:get(0, 0, 0)*0.4)
	laplacianPyrUp(l6, l5, t, l5, 1 + c:get(0, 0, 0)*0.5)
	laplacianPyrUp(l5, l4, t, l4, 1 + c:get(0, 0, 0)*0.6)
	laplacianPyrUp(l4, l3, t, l3, 1 + c:get(0, 0, 0)*0.7)
	laplacianPyrUp(l3, l2, t, l2, 1 + c:get(0, 0, 0)*0.8)
	laplacianPyrUp(l2, l1, t, l1, 1 + c:get(0, 0, 0)*0.9)
	laplacianPyrUp(l1, l0, t,  o, 1 + c:get(0, 0, 0)*1.0)

	syncCh:supply("step")
end

-- run process
while true do
	local op = dataCh:demand()
	assert(type(op)=="string")
	if ops[op] then
		require "jit".flush() -- FIXME: temporary fix for severe slowdowns
		ops[op]()
	else
		error("LUA WORKER ERROR: op ["..op.."] not a Native function!")
	end
end
