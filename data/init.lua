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

local ffi = require "ffi"
--local cl = require "lib.opencl"
ffi.cdef[[
	typedef float cl_float __attribute__((aligned(4)));
	typedef struct _cl_mem *cl_mem;
]]

local onDemandMemory = settings.openclLowMemory
local oclDebug = settings.openclDebug

require "lib.opencl"

local unroll = require "tools.unroll"
local filter = require "tools.filter"
local alloc = require "data.alloc"

local data = {type = "data/OCL"}
data.meta = {__index = data}

data.CS = {
	"SRGB",
	"LRGB",
	"XYZ",
	"LAB",
	"LCH",
	"Y",
	"L",
}
for k, v in ipairs(data.CS) do
	data.CS[v] = k
end

local context, queue
function data.initDev(c, q)
	if c == NULL then
		context = nil
		queue = nil
	else
		context = c
		queue = q
	end

	data.sink = data:new()
	data.one = data:new()
	data.one:set(0, 0, 0, 1)
	data.one:toDevice()
	data.one.cs = "Y"
	data.zero = data:new()
	data.zero:set(0, 0, 0, 0)
	data.zero:toDevice()
	data.zero.cs = "Y"
end

function data:new(x, y, z) -- new image data
	x = x or self.x or 1 -- default dimensions or inherit
	y = y or self.y or 1
	z = z or self.z or 1

	local o = {
		x = x, y = y, z = z, -- set extents
		sx = self.sx or 1, sy = self.sy or x, sz = self.sz or x * y, -- set strides
		ox = self.ox or 0, oy = self.oy or 0, oz = self.oz or 0, -- set offsets
		cs = self.cs or "LRGB", -- default CS or inherit

		-- TODO: clean up implementation
		__cpuDirty = false,
		__gpuDirty = false,
		__csDirty = false,
		__read = true,
		__write = true,
	}

	if not settings.hostLowMemory then
		o.data = alloc.trace.float32(x * y * z)
		o.data_u32 = ffi.cast("uint32_t*", o.data)
		o.data_i32 = ffi.cast("int32_t*", o.data)
	end

	setmetatable(o, self.meta) -- inherit data methods
	if not onDemandMemory then
		o:allocDev(false)
	end

	return o
end

function data:allocHost()
	if not self.data then
		self.data = alloc.trace.float32(self.x * self.y * self.z)
		self.data_u32 = ffi.cast("uint32_t*", self.data)
		self.data_i32 = ffi.cast("int32_t*", self.data)
	end
	return self
end

function data:allocDev(transfer)
	--print("Allocate device memory", tonumber(ffi.cast("uintptr_t", self.data)))
	if transfer==nil then transfer = self.__read end
	assert(context, "No OpenCL device detected")

	-- helps with CPU/iGPU memory transfers, significantly degrades performance on dGPU
	--self.dataOCL = context:create_buffer("use_host_ptr", self.x * self.y * self.z * ffi.sizeof("cl_float"), self.data) -- allocate OCL data

	self.dataOCL = context:create_buffer(self.x * self.y * self.z * ffi.sizeof("cl_float")) -- allocate OCL data

	if transfer then self:toDevice(true) end
	return self
end

function data:freeDev(transfer)
	--print("Free device memory", tonumber(ffi.cast("uintptr_t", self.data)))
	if transfer==nil then transfer = self.__write end
	assert(context, "No OpenCL device detected")
	if transfer then self:toHost(true) end
	if self.dataOCL then context.release_mem_object(self.dataOCL) end
	self.dataOCL = nil
	return self
end

function data:free()
	if self.data then alloc.free(self.data) end
	if self.dataOCL then context.release_mem_object(self.dataOCL) end
	self.data = nil
	self.dataOCL = nil
end

function data:toDevice(blocking)
	self:allocHost()
	blocking = blocking or false
	if queue and self.dataOCL then
		if oclDebug then print(">>>", self.dataOCL, tostring(self), tonumber(ffi.cast("uintptr_t", self.data))) end
		queue:enqueue_write_buffer(self.dataOCL, blocking, self.data)
	end
	return self
end

function data:toHost(blocking)
	self:allocHost()
	blocking = blocking or false
	if queue and self.dataOCL then
		if oclDebug then print("<<<", self.dataOCL, tostring(self), tonumber(ffi.cast("uintptr_t", self.data))) end
		queue:enqueue_read_buffer(self.dataOCL, blocking, self.data)
	end
	return self
end

function data.meta.__tostring(a)
	return "Data/OCL["..a.x..", "..a.y..", "..a.z.."] ("..a.cs..")"
end

function data:shape()
	return self.x, self.y, self.z
end

-- conversion to and from c structures
ffi.cdef[[
	typedef struct{
		float *data;		// buffer data
		int x, y, z;	  // dimensions
		int sx, sy, sz;	// strides
		int ox, oy, oz; // offsets
		int cs;					// color space
	} dataStruct;
]]
data.CStruct = ffi.typeof("dataStruct")

function data:toCStruct()
	-- remember to anchor data allocation!!!
	return self.CStruct(self.data,
		self.x, self.y, self.z,
		self.sx, self.sy, self.sz,
		self.ox, self.oy, self.oz,
	0) -- FIXME export color space
end

function data:fromCStruct()
	local o = {
		data = self.data,
		x = self.x,
		y = self.y,
		z = self.z,
		sx = self.sx,
		sy = self.sy,
		sz = self.sz,
		ox = self.ox,
		oy = self.oy,
		oz = self.oz,
		cs = self.CS[self.cs],
	}
	o.data_i32 = ffi.cast("int32_t*", o.data)
	o.data_u32 = ffi.cast("uint32_t*", o.data)
	setmetatable(o, self.meta) -- inherit data methods
	return o
end

-- conversion to and from flat tables to send across channels
function data:toChTable()
	local o = {
		data = tonumber(ffi.cast("uintptr_t", self.data)),
		dataOCL = tonumber(ffi.cast("uintptr_t", self.dataOCL)),
		x = self.x,
		y = self.y,
		z = self.z,
		sx = self.sx,
		sy = self.sy,
		sz = self.sz,
		ox = self.ox,
		oy = self.oy,
		oz = self.oz,
		cs = self.cs,
		type = self.type,
	}
	return o
end

function data:fromChTable()
	local o = {
		data = ffi.cast("float*", self.data),
		dataOCL = ffi.cast("cl_mem", self.dataOCL),
		x = self.x,
		y = self.y,
		z = self.z,
		sx = self.sx,
		sy = self.sy,
		sz = self.sz,
		ox = self.ox,
		oy = self.oy,
		oz = self.oz,
		cs = self.cs,
		type = self.type,
	}
	if self.__read==nil then o.__read = true else o.__read = self.__read end
	if self.__write==nil then o.__write = true else o.__write = self.__write end

	o.data_i32 = ffi.cast("int32_t*", o.data)
	o.data_u32 = ffi.cast("uint32_t*", o.data)
	setmetatable(o, data.meta)
	return o
end

-- CPU data access
function data:abc(x, y, z) -- array bounds checking
	assert(x < (self.x + self.ox), "x out of bounds")
	assert(x >= self.ox, "x out of bounds")
	assert(y < (self.y + self.oy), "y out of bounds")
	assert(y >= self.oy, "y out of bounds")
	assert(z < (self.z + self.oz), "z out of bounds")
	assert(z >= self.oz, "z out of bounds")
	return x, y, z
end

function data:broadcastCheck(x, y, z)
	x = self.x == 1 and 0 or x
	y = self.y == 1 and 0 or y
	z = self.z == 1 and 0 or z
	x, y, z = self:abc(x, y, z)
	return x, y, z
end

function data:broadcastUnsafe(x, y, z)
	x = self.x == 1 and 0 or x
	y = self.y == 1 and 0 or y
	z = self.z == 1 and 0 or z
	return x, y, z
end

function data:broadcastExtend(x, y, z)
	x = math.max(math.min(x, self.x - 1), 0)
	y = math.max(math.min(y, self.y - 1), 0)
	z = math.max(math.min(z, self.z - 1), 0)
	return x, y, z
end

function data:idx(x, y, z)
	x, y, z = self:broadcastExtend(x, y, z)
	return ((x + self.ox) * self.sx + (y + self.oy) * self.sy + (z + self.oz) * self.sz)
end

-- TODO: differentiate between idx functions
function data:get(x, y, z)
	self:allocHost()
	return self.data[self:idx(x, y, z)]
end

function data:set(x, y, z, v)
	self:allocHost()
	self.data[self:idx(x, y, z)] = v
end

function data:get_i32(x, y, z)
	self:allocHost()
	return self.data_i32[self:idx(x, y, z)]
end

function data:set_i32(x, y, z, v)
	self:allocHost()
	self.data_i32[self:idx(x, y, z)] = v
end

function data:get_u32(x, y, z)
	self:allocHost()
	return self.data_u32[self:idx(x, y, z)]
end

function data:set_u32(x, y, z, v)
	self:allocHost()
	self.data_u32[self:idx(x, y, z)] = v
end

function data:transferTo(new)
	local function fun(z, x, y)
		new:set(x, y, z, self:get(x, y, z))
	end

	-- TODO: optimize based on layout
	for x = 0, self.x - 1 do
		for y = 0, self.y - 1 do
			unroll.fixed(self.z, 2)(fun, x, y)
		end
	end
	return new
end

function data:copy()
	return self:transferTo(self:new())
end

-- data operators

function data.operator(fun)
	return function(a, b)
		local c = a:new()

		local innerFunction
		if type(a) == "table" and type(b) == "table" then
			function innerFunction(z, x, y)
				c:set(x, y, z, fun(a:get(x, y, z), b:get(x, y, z)))
			end
		elseif type(a) == "table" and type(b) == "number" then
			function innerFunction(z, x, y)
				c:set(x, y, z, fun(a:get(x, y, z), b))
			end
		elseif type(a) == "number" and type(b) == "table" then
			function innerFunction(z, x, y)
				c:set(x, y, z, fun(a, b:get(x, y, z)))
			end
		elseif type(a) == "table" and b == nil then
			function innerFunction(z, x, y)
				c:set(x, y, z, fun(a:get(x, y, z)))
			end
		else
			error("wrong argument type to operator: "..type(a)..", "..type(b))
		end

		--jit.flush(1)
		local unrolled = unroll.fixed(c.z, 2)
		for x = 0, c.x - 1 do
			for y = 0, c.y - 1 do
				unrolled(innerFunction, x, y)
			end
		end

		return c
	end
end

data.meta.__add = data.operator(function(a, b) return a + b end)
data.meta.__sub = data.operator(function(a, b) return a - b end)
data.meta.__mul = data.operator(function(a, b) return a * b end)
data.meta.__div = data.operator(function(a, b) return a / b end)
data.meta.__pow = data.operator(function(a, b) return a^b end)
data.meta.__unm = data.operator(function(a) return - a end)
data.meta.__mod = data.operator(function(a, b) return a%b end)
-- "..", "#" "()" definition?
-- comparisons do not work properly due to requirement to return single boolean value

local math = math
data.abs = data.operator(function(a) return math.abs(a) end)
data.mod = data.operator(function(a, b) return a%b end)
data.floor = data.operator(function(a) return math.floor(a) end)
data.ceil = data.operator(function(a) return math.ceil(a) end)
data.sqrt = data.operator(function(a) return math.sqrt(a) end)
data.pow = data.operator(function(a, b) return a^b end)
data.exp = data.operator(function(a) return math.exp(a) end)
data.log = data.operator(function(a) return math.log(a) end)
data.log10 = data.operator(function(a) return math.log10(a) end)
data.deg = data.operator(function(a) return math.deg(a) end)
data.rad = data.operator(function(a) return math.rad(a) end)
data.sin = data.operator(function(a) return math.sin(a) end)
data.cos = data.operator(function(a) return math.cos(a) end)
data.tan = data.operator(function(a) return math.tan(a) end)
data.asin = data.operator(function(a) return math.asin(a) end)
data.acos = data.operator(function(a) return math.acos(a) end)
data.atan = data.operator(function(a) return math.atan(a) end)
data.atan2 = data.operator(function(a, b) return math.atan2(a, b) end)
data.random = data.operator(function() return math.random() end)

function data:map(fun, ...) -- z, x, y, params...
	local out = self:new()

	local unrolled = unroll.fixed(self.z, 2)
	for x = 0, self.x - 1 do
		for y = 0, self.y - 1 do
			unrolled(fun, x, y, ...)
		end
	end
end

function data.superSize(...) -- returns size of buffer needed to accomodate all argument buffers by broadcasting
	local buffers = {...}
	local x, y, z = 1, 1, 1
	for _, t in ipairs(buffers) do
		assert(t.x == x or t.x == 1 or x == 1, "Incompatible x dimension")
		assert(t.y == y or t.y == 1 or y == 1, "Incompatible y dimension")
		assert(t.z == z or t.z == 1 or z == 1, "Incompatible z dimension")
		if t.x > x then x = t.x end
		if t.y > y then y = t.y end
		if t.z > z then z = t.z end
	end
	return x, y, z
end

local function separable4(self, x, y, z, f)
	local xm = math.floor(x)
	local xf = x - xm
	local ym = math.floor(y)
	local yf = y - ym

	local v00, v01, v02, v03
	local v10, v11, v12, v13
	local v20, v21, v22, v23
	local v30, v31, v32, v33
	local v

	v00 = self:get(xm - 1, ym - 1, z)
	v01 = self:get(xm - 1, ym, z)
	v02 = self:get(xm - 1, ym + 1, z)
	v03 = self:get(xm - 1, ym + 2, z)
	v10 = self:get(xm, ym - 1, z)
	v11 = self:get(xm, ym, z)
	v12 = self:get(xm, ym + 1, z)
	v13 = self:get(xm, ym + 2, z)
	v20 = self:get(xm + 1, ym - 1, z)
	v21 = self:get(xm + 1, ym, z)
	v22 = self:get(xm + 1, ym + 1, z)
	v23 = self:get(xm + 1, ym + 2, z)
	v30 = self:get(xm + 2, ym - 1, z)
	v31 = self:get(xm + 2, ym, z)
	v32 = self:get(xm + 2, ym + 1, z)
	v33 = self:get(xm + 2, ym + 2, z)

	return f(
		f(v00, v01, v02, v03, yf),
		f(v10, v11, v12, v13, yf),
		f(v20, v21, v22, v23, yf),
		f(v30, v31, v32, v33, yf),
	xf)
end

function data:bicubic(x, y, z)
	return separable4(self, x, y, z, filter.cubic)
end

function data:lanczos(x, y, z)
	return separable4(self, x, y, z, filter.lanczos)
end

function data:bilinear(x, y, z)
	local xm = math.floor(x)
	local xf = x - xm
	local ym = math.floor(y)
	local yf = y - ym
	local v00, v01, v10, v11, v

	v00 = self:get(xm, ym, z)
	v01 = self:get(xm, ym + 1, z)
	v10 = self:get(xm + 1, ym, z)
	v11 = self:get(xm + 1, ym + 1, z)

	return filter.linear(filter.linear(v00, v01, yf), filter.linear(v10, v11, yf), xf)
end

function data:nearest(x, y, z)
	x = math.floor(x + 0.5)
	y = math.floor(y + 0.5)
	return self:get(x, y, z)
end

return data
