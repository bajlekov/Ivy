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
local mutex = require "tools.mutex"
local ocl = require "lib.opencl"

local data = {type="data"}
data.meta = {__index = data}

local devContext, devQueue
function data.initDev(c, q)
  if c == NULL then
		devContext = nil
		devQueue = nil
	else
		devContext = c
		devQueue = q
	end

  data.sink = data:new(1, 1, 3):allocHost()
  data.sink:hostWritten()
  data.sink:syncDev()

  data.oneCS = {}
  data.zeroCS = {}

  data.oneCS.SRGB = data:new(1, 1, 3)
  data.oneCS.SRGB:set(0, 0, 0, 1)
  data.oneCS.SRGB:set(0, 0, 1, 1)
  data.oneCS.SRGB:set(0, 0, 2, 1)
  data.oneCS.SRGB:syncDev()
  data.oneCS.SRGB.cs = "SRGB"
  data.oneCS.LRGB = data:new(1, 1, 3)
  data.oneCS.LRGB:set(0, 0, 0, 1)
  data.oneCS.LRGB:set(0, 0, 1, 1)
  data.oneCS.LRGB:set(0, 0, 2, 1)
  data.oneCS.LRGB:syncDev()
  data.oneCS.LRGB.cs = "LRGB"
  data.oneCS.XYZ = data:new(1, 1, 3)
  data.oneCS.XYZ:set(0, 0, 0, 0.95047)
  data.oneCS.XYZ:set(0, 0, 1, 1)
  data.oneCS.XYZ:set(0, 0, 2, 1.08883)
  data.oneCS.XYZ:syncDev()
  data.oneCS.XYZ.cs = "XYZ"
  data.oneCS.LAB = data:new(1, 1, 3)
  data.oneCS.LAB:set(0, 0, 0, 1)
  data.oneCS.LAB:set(0, 0, 1, 0)
  data.oneCS.LAB:set(0, 0, 2, 0)
  data.oneCS.LAB:syncDev()
  data.oneCS.LAB.cs = "LAB"
  data.oneCS.LCH = data:new(1, 1, 3)
  data.oneCS.LCH:set(0, 0, 0, 1)
  data.oneCS.LCH:set(0, 0, 1, 0)
  data.oneCS.LCH:set(0, 0, 2, 0)
  data.oneCS.LCH:syncDev()
  data.oneCS.LCH.cs = "LCH"
  data.oneCS.Y = data:new(1, 1, 1)
  data.oneCS.Y:set(0, 0, 0, 1)
  data.oneCS.Y:syncDev()
  data.oneCS.Y.cs = "Y"
  data.oneCS.L = data:new(1, 1, 1)
  data.oneCS.L:set(0, 0, 0, 1)
  data.oneCS.L:syncDev()
  data.oneCS.L.cs = "L"

  data.zeroCS.SRGB = data:new(1, 1, 3)
  data.zeroCS.SRGB:set(0, 0, 0, 0)
  data.zeroCS.SRGB:set(0, 0, 1, 0)
  data.zeroCS.SRGB:set(0, 0, 2, 0)
  data.zeroCS.SRGB:syncDev()
  data.zeroCS.SRGB.cs = "SRGB"
  data.zeroCS.LRGB = data:new(1, 1, 3)
  data.zeroCS.LRGB:set(0, 0, 0, 0)
  data.zeroCS.LRGB:set(0, 0, 1, 0)
  data.zeroCS.LRGB:set(0, 0, 2, 0)
  data.zeroCS.LRGB:syncDev()
  data.zeroCS.LRGB.cs = "LRGB"
  data.zeroCS.XYZ = data:new(1, 1, 3)
  data.zeroCS.XYZ:set(0, 0, 0, 0)
  data.zeroCS.XYZ:set(0, 0, 1, 0)
  data.zeroCS.XYZ:set(0, 0, 2, 0)
  data.zeroCS.XYZ:syncDev()
  data.zeroCS.XYZ.cs = "XYZ"
  data.zeroCS.LAB = data:new(1, 1, 3)
  data.zeroCS.LAB:set(0, 0, 0, 0)
  data.zeroCS.LAB:set(0, 0, 1, 0)
  data.zeroCS.LAB:set(0, 0, 2, 0)
  data.zeroCS.LAB:syncDev()
  data.zeroCS.LAB.cs = "LAB"
  data.zeroCS.LCH = data:new(1, 1, 3)
  data.zeroCS.LCH:set(0, 0, 0, 0)
  data.zeroCS.LCH:set(0, 0, 1, 0)
  data.zeroCS.LCH:set(0, 0, 2, 0)
  data.zeroCS.LCH:syncDev()
  data.zeroCS.LCH.cs = "LCH"
  data.zeroCS.Y = data:new(1, 1, 1)
  data.zeroCS.Y:set(0, 0, 0, 0)
  data.zeroCS.Y:syncDev()
  data.zeroCS.Y.cs = "Y"
  data.zeroCS.L = data:new(1, 1, 1)
  data.zeroCS.L:set(0, 0, 0, 0)
  data.zeroCS.L:syncDev()
  data.zeroCS.L.cs = "L"

  data.one = data.oneCS.Y
  data.zero = data.zeroCS.Y

  data.oneCS.ANY = data.one
  data.zeroCS.ANY = data.zero
end

ffi.cdef[[
	void * malloc ( size_t size );
	void free ( void * ptr );

  typedef float host_float __attribute__((aligned(32)));
  typedef int32_t host_int __attribute__((aligned(32)));
  typedef float cl_float __attribute__((aligned(4)));
  typedef int32_t cl_int __attribute__((aligned(4)));
  typedef struct _cl_mem *cl_mem;

  typedef struct {
    host_float *dataHost;
    cl_mem dataDev;
    host_int *strHost;
    cl_mem strDev;
    int32_t dirtyHost;
    int32_t dirtyDev;
  } ivy_buffer;
]]

local function ivyBufferFree(buffer)
  if buffer[0].dataHost~=NULL then
    ffi.C.free(buffer[0].dataHost)
    buffer[0].dataHost = NULL
  end
  if buffer[0].strHost~=NULL then
    ffi.C.free(buffer[0].strHost)
    buffer[0].strHost = NULL
  end
  if buffer[0].dataDev~=NULL then
    devContext.release_mem_object(buffer[0].dataDev)
    buffer[0].dataDev = NULL
  end
  if buffer[0].strDev~=NULL then
    devContext.release_mem_object(buffer[0].strDev)
    buffer[0].strDev = NULL
  end
  ffi.C.free(buffer)
end

function data:new(x, y, z)
  local d = {}
  d.x = x or self.x or 1
  d.y = y or self.y or 1
  d.z = z or self.z or 1

	d.sx = self.sx or 1
	d.sy = self.sy or d.x
	d.sz = self.sz or d.x * d.y

  d.cs = self.cs or (d.z==3 and "LRGB") or "Y"

  d.buffer = ffi.cast("ivy_buffer *", ffi.C.malloc(ffi.sizeof("ivy_buffer")))
  ffi.gc(d.buffer, ivyBufferFree)
	d.buffer[0].dataHost = NULL
	d.buffer[0].dataDev = NULL
	d.buffer[0].strHost = NULL
	d.buffer[0].strDev = NULL

	d.buffer[0].dirtyHost = 1
	d.buffer[0].dirtyDev = 1

	d.mutex = mutex:new()

  setmetatable(d, self.meta)
  return d
end

function data:set_cs(cs)
  self.cs = cs
  return self
end

function data:allocHost(transfer)
  self:lock()
  if self.buffer[0].dataHost==NULL then
    assert(self.buffer[0].strHost==NULL)
    self.buffer[0].dataHost = ffi.cast("host_float *", ffi.C.malloc(ffi.sizeof("host_float") * self.x * self.y * self.z))
    self.buffer[0].strHost = ffi.cast("host_int *", ffi.C.malloc(ffi.sizeof("host_int") * 6))
		self.buffer[0].strHost[0] = self.x
		self.buffer[0].strHost[1] = self.y
		self.buffer[0].strHost[2] = self.z
		self.buffer[0].strHost[3] = self.sx
		self.buffer[0].strHost[4] = self.sy
		self.buffer[0].strHost[5] = self.sz
    self.buffer[0].dirtyHost = 1
  end
  if transfer then
    self:syncHost()
  end
  self:unlock()
  return self
end

local strDev = ffi.new("cl_int[6]")
function data:allocDev(transfer)
  assert(devContext, "No OpenCL device detected")
	self:lock()
  if self.buffer[0].dataDev==NULL then
    assert(self.buffer[0].strDev==NULL)
    self.buffer[0].dataDev = ffi.gc(devContext:create_buffer(ffi.sizeof("cl_float") * self.x * self.y * self.z), nil)
    self.buffer[0].strDev = ffi.gc(devContext:create_buffer(ffi.sizeof("cl_int") * 6), nil)
    strDev[0] = self.x
    strDev[1] = self.y
    strDev[2] = self.z
    strDev[3] = self.sx
    strDev[4] = self.sy
    strDev[5] = self.sz
    devQueue:enqueue_write_buffer(self.buffer[0].strDev, true, strDev)
    self.buffer[0].dirtyDev = 1
  end
  if transfer then
    self:syncDev()
  end
  self:unlock()
  return self
end

function data:freeHost(transfer)
  self:lock()
  if transfer then
    self:allocDev(true)
  end
  if self.buffer[0].dataHost~=NULL then
    assert(self.buffer[0].strHost~=NULL)
    ffi.C.free(self.buffer[0].dataHost)
    ffi.C.free(self.buffer[0].strHost)
    self.buffer[0].dataHost = NULL
    self.buffer[0].strHost = NULL
  end
  self:unlock()
  return self
end

function data:freeDev(transfer)
  assert(devContext, "No OpenCL device detected")
  self:lock()
  if transfer then
    self:allocHost(true)
  end
	if self.buffer[0].dataDev~=NULL then
    assert(self.buffer[0].strDev~=NULL)
    devContext.release_mem_object(self.buffer[0].dataDev)
    devContext.release_mem_object(self.buffer[0].strDev)
    self.buffer[0].dataDev = NULL
    self.buffer[0].strDev = NULL
  end
  self:unlock()
  return self
end

function data:free()
	self:freeHost()
  self:freeDev()
  return self
end

function data:sync(blocking)
  self:lock()
  local h = self.buffer[0].dirtyHost==1
  local d = self.buffer[0].dirtyDev==1
  assert(not (h and d))
  if h then
    self:syncHost(true, blocking)
  end
  if d then
    self:syncDev(true, blocking)
  end
  self:unlock()
  return self
end

function data:syncHost(blocking)
  if blocking==nil then blocking = true end
  self:lock()
  self:allocHost()
  if self.buffer[0].dirtyHost==1 then
    assert(self.buffer[0].dataDev~=NULL)
    assert(self.buffer[0].dirtyDev==0)
	  devQueue:enqueue_read_buffer(self.buffer[0].dataDev, blocking and 1 or 0, self.buffer[0].dataHost)
    self.buffer[0].dirtyHost = 0
  end
  self:unlock()
  return self
end

function data:forceSyncHost(blocking)
  if blocking==nil then blocking = true end
  self:lock()
  assert(self.buffer[0].dataDev~=NULL)
  assert(self.buffer[0].dirtyDev==0)
  self:allocHost()
  devQueue:enqueue_read_buffer(self.buffer[0].dataDev, blocking and 1 or 0, self.buffer[0].dataHost)
  self.buffer[0].dirtyHost = 0
  self:unlock()
  return self
end

function data:syncDev(blocking)
  self:lock()
  self:allocDev()
  if self.buffer[0].dirtyDev==1 then
    assert(self.buffer[0].dataHost~=NULL)
    assert(self.buffer[0].dirtyHost==0)
    devQueue:enqueue_write_buffer(self.buffer[0].dataDev, blocking and 1 or 0, self.buffer[0].dataHost)
    self.buffer[0].dirtyDev = 0
  end
  self:unlock()
  return self
end

function data:forceSyncDev(blocking)
  self:lock()
  assert(self.buffer[0].dataHost~=NULL)
  assert(self.buffer[0].dirtyHost==0)
  self:allocDev()
  devQueue:enqueue_write_buffer(self.buffer[0].dataDev, blocking and 1 or 0, self.buffer[0].dataHost)
  self.buffer[0].dirtyDev = 0
  self:unlock()
  return self
end

function data.meta.__tostring(self)
	local host = self.buffer[0].dataHost~=NULL and "Host" or ""
	local dev = self.buffer[0].dataDev~=NULL and (host=="Host" and "/Device" or "Device") or ""
	return "Data["..self.x..", "..self.y..", "..self.z.."]"..self.cs.." ("..host..dev..")"
end

function data:shape()
	return self.x, self.y, self.z
end


function data:toTable()
	return {
		x = self.x,
		y = self.y,
		z = self.z,
		sx = self.sx,
		sy = self.sy,
		sz = self.sz,
    cs = self.cs,
		buffer = tonumber(ffi.cast("uintptr_t", self.buffer)),
		mutex = self.mutex:ptr(),
	}
end

function data:fromTable(t)
	local d = {}
  d.x = t.x
  d.y = t.y
  d.z = t.z
	d.sx = t.sx
	d.sy = t.sy
	d.sz = t.sz
  d.cs = t.cs
  d.buffer = ffi.cast("ivy_buffer *", t.buffer)
	d.mutex = mutex:new(t.mutex)
  setmetatable(d, self.meta)
  return d
end

function data:lock()
	self.mutex:lock()
  return self
end

function data:unlock()
	self.mutex:unlock()
  return self
end

function data:setDirtyHost()
  self:lock()
	self.buffer[0].dirtyHost = 1
  self:unlock()
  return self
end

function data:setDirtyDev()
  self:lock()
	self.buffer[0].dirtyDev = 1
  self:unlock()
  return self
end

function data:clearDirtyHost()
  self:lock()
	self.buffer[0].dirtyHost = 0
  self:unlock()
  return self
end

function data:clearDirtyDev()
  self:lock()
	self.buffer[0].dirtyDev = 0
  self:unlock()
  return self
end

function data:hostWritten()
  self:lock()
  self.buffer[0].dirtyHost = 0
  self.buffer[0].dirtyDev = 1
  self:unlock()
  return self
end

function data:devWritten()
  self:lock()
  self.buffer[0].dirtyHost = 1
  self.buffer[0].dirtyDev = 0
  self:unlock()
  return self
end

local function clamp(x, a, b)
	return math.min(math.max(x, a), b)
end

function data:get(x, y, z)
  assert(self.buffer[0].dataHost~=NULL, "Host data not allocated for read")
  assert(self.buffer[0].dirtyHost==0, "Host data not synchronised")
	x = clamp(x, 0, self.x-1)
	y = clamp(y, 0, self.y-1)
	z = clamp(z, 0, self.z-1)
	return self.buffer[0].dataHost[x*self.sx + y*self.sy + z*self.sz]
end

local i32 = ffi.typeof("int32_t*")
function data:get_i32(x, y, z)
  assert(self.buffer[0].dataHost~=NULL, "Host data not allocated for read")
  assert(self.buffer[0].dirtyHost==0, "Host data not synchronised")
	x = clamp(x, 0, self.x-1)
	y = clamp(y, 0, self.y-1)
	z = clamp(z, 0, self.z-1)
	return ffi.cast(i32, self.buffer[0].dataHost)[x*self.sx + y*self.sy + z*self.sz]
end

local u32 = ffi.typeof("uint32_t*")
function data:get_u32(x, y, z)
  assert(self.buffer[0].dataHost~=NULL, "Host data not allocated for read")
  assert(self.buffer[0].dirtyHost==0, "Host data not synchronised")
	x = clamp(x, 0, self.x-1)
	y = clamp(y, 0, self.y-1)
	z = clamp(z, 0, self.z-1)
	return ffi.cast(u32, self.buffer[0].dataHost)[x*self.sx + y*self.sy + z*self.sz]
end

function data:set(x, y, z, v)
  if self.buffer[0].dataHost==NULL then
    self:allocHost()
  end
	if x<0 or x>=self.x or y<0 or y>=self.y or z<0 or z>=self.z then
    return
  end
	self.buffer[0].dataHost[x*self.sx + y*self.sy + z*self.sz] = v
  self:hostWritten()
  return self
end


function data.superSize(...)
  local buffers = {...}
  local x, y, z = 1, 1, 1
  for _, t in ipairs(buffers) do
    x = math.max(x, t.x)
    y = math.max(y, t.y)
    z = math.max(z, t.z)
  end
  return x, y, z
end

return data
