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

local ffi = require "ffi"
local data = require "data"

local image = {type="image"}
image.meta = {__index = image}
image.stats = require "data.stats"

local devContext, devQueue
function image.initDev(c, q)
  if c == NULL then
		devContext = nil
		devQueue = nil
	else
		devContext = c
		devQueue = q
	end
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

local function ivyImageFree(buffer)
  if buffer[0].dataHost~=NULL then
    assert(buffer[0].strHost~=NULL)
    data.stats.freeHost(buffer[0].dataHost)
    data.stats.freeHost(buffer[0].strHost)
    -- imageData cleans up its own host memory
    ffi.C.free(buffer[0].strHost)
    buffer[0].strHost = NULL
    buffer[0].dataHost = NULL
  end
  if buffer[0].dataDev~=NULL then
    assert(buffer[0].strDev~=NULL)
    data.stats.freeDev(buffer[0].dataDev)
    data.stats.freeDev(buffer[0].strDev)
    devContext.release_mem_object(buffer[0].dataDev)
    devContext.release_mem_object(buffer[0].strDev)
    buffer[0].dataDev = NULL
    buffer[0].strDev = NULL
  end

  ffi.C.free(buffer)
end

local function allocHost()
  print("Warning: Allocating host data of Image is unsupported")
end

local function freeHost()
  print("Warning: Freeing host data of Image is unsupported")
end

function image:new(x, y)
  local i = {
    x = x or self.x or 1,
    y = y or self.y or 1,
  }

  i.imageData = love.image.newImageData(i.x, i.y)
  i.image = love.graphics.newImage(i.imageData)
  i.image:setFilter("linear", "nearest")
  ffi.fill(i.imageData:getPointer(), i.x*i.y*4, 255)

  -- regular data buffer allocation
  i.data = data:new(i.x, i.y, 1)
	i.data.buffer[0].dataHost = i.imageData:getPointer()
  i.data.buffer[0].strHost = ffi.cast("host_int *", ffi.C.malloc(ffi.sizeof("host_int") * 6))
	i.data.buffer[0].strHost[0] = i.x
	i.data.buffer[0].strHost[1] = i.y
	i.data.buffer[0].strHost[2] = 1
	i.data.buffer[0].strHost[3] = 1
	i.data.buffer[0].strHost[4] = i.x
	i.data.buffer[0].strHost[5] = 0

  image.stats.allocHost(i.data.buffer[0].dataHost, ffi.sizeof("uint32_t")*i.x*i.y + ffi.sizeof("host_int")*6)
  i.data.allocHost = allocHost -- disable host allocating
  i.data.freeHost = freeHost -- disable host freeing

  ffi.gc(i.data.buffer, ivyImageFree) -- free whole struct when not used

  i.data.cs = "SRGB"
  i.scale = 1
  i.drawOffset = {x=0, y=0}

	setmetatable(i, image.meta)
	return i
end

function image.meta.__tostring(a)
	return "Image["..a.x..", "..a.y..", 4]"
end

function image:idx(x, y, z)
  return (x*4 + (self.y-y-1)*self.x*4 + z)
end

function image:get(x, y, z)
  return ffi.cast("uint8_t *", self.data.buffer[0].dataHost)[self:idx(x, y, z)]
end

function image:refresh()
  self.data:lock()
  self.image:replacePixels(self.imageData)
  self.data:unlock()
  return self
end

function image:draw(x, y)
  love.graphics.draw(self.image, x + self.drawOffset.x, y+self.drawOffset.y, 0, self.scale, self.scale)
end

function image:toTable()
  return self.data:toTable()
end

function image:fromTable()
  return self.data:fromTable()
end

return image
