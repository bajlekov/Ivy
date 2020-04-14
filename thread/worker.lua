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

local ffi = require "ffi"

local profile = settings.openclProfile
local size = settings.openclWorkgroupSize

local dataCh = love.thread.getChannel("dataCh_scheduler")
local syncCh = love.thread.getChannel("syncCh_scheduler")

local ops = {}
ops.cache = {}
ops.meta = {}
setmetatable(ops, ops.meta)


local function demand()
	local buf = dataCh:demand()
	assert(type(buf) == "table" or buf == "execute", buf)
	return buf
end

function ops.init(device, context, queue)
	local data = require "data"
	local image = require "ui.image"

	ops.cache = {}

	local function register(name)
		local fun = require("ops.ocl."..name)(device, context, queue)
		ops.cache[name] = function()
			fun(demand, {size, size}, profile)
		end
	end

	-- try to auto-register when not available
	ops.meta.__index = function(t, k)
		if not ops.cache[k] then
			register(k)
		end
		return ops.cache[k]
	end

	local function gen1(name, fn)
		local fun = require("ops.ocl.gen1")(device, context, queue, name, fn)
		ops.cache[name] = function()
			fun(demand, {size, size}, profile)
		end
	end

	local function gen2(name, fn)
		local fun = require("ops.ocl.gen2")(device, context, queue, name, fn)
		ops.cache[name] = function()
			fun(demand, {size, size}, profile)
		end
	end

	local function genCS(name, fn)
		local fun = require("ops.ocl.genCS")(device, context, queue, name, "ops/ocl/cs_kernels.cl")
		ops.cache[name] = function()
			fun(demand, {size, size}, profile)
		end
	end

	local function genBlend(name, fn)
		local fun = require("ops.ocl.genBlend")(device, context, queue, name)
		ops.cache[name] = function()
			fun(demand, {size, size}, profile)
		end
	end

	gen1("ivy_abs", "math_kernels_1.ivy")
	gen1("ivy_neg", "math_kernels_1.ivy")
	gen1("ivy_inv", "math_kernels_1.ivy")
	gen1("ivy_clamp", "math_kernels_1.ivy")
	gen1("ivy_copy", "math_kernels_1.ivy")

	gen2("ivy_add", "math_kernels_2.ivy")
	gen2("ivy_mul", "math_kernels_2.ivy")
	gen2("ivy_sub", "math_kernels_2.ivy")
	gen2("ivy_div", "math_kernels_2.ivy")
	gen2("ivy_pow", "math_kernels_2.ivy")
	gen2("ivy_min", "math_kernels_2.ivy")
	gen2("ivy_max", "math_kernels_2.ivy")
	gen2("ivy_average", "math_kernels_2.ivy")
	gen2("ivy_difference", "math_kernels_2.ivy")
	gen2("ivy_diff", "math_kernels_2.ivy")
	gen2("ivy_GT", "math_kernels_2.ivy")
	gen2("ivy_LT", "math_kernels_2.ivy")
	gen2("ivy_closer", "math_kernels_2.ivy")
	gen2("ivy_farther", "math_kernels_2.ivy")

	genCS("SRGB")
	genCS("LRGB")
	genCS("XYZ")
	genCS("LAB")
	genCS("LCH")
	genCS("Y")
	genCS("L")

	for k, v in ipairs{"negate", "exclude", "screen", "overlay", "hardlight", "softlight", "dodge", "burn", "softdodge", "softburn", "linearlight", "vividlight", "pinlight"} do
		genBlend(v)
	end

	function ops.sync()
		queue:finish()
		syncCh:push("sync")
	end

	require "ops.custom"("ocl", device, context, queue)
end

return ops
