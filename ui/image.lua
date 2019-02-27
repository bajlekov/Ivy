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

-- draw image data to screen

local cs = require "tools.cs"
local ffi = require "ffi"

local image = {type="image"}
image.meta = {__index = image}

-- create quivalent to float data

function image:new(x, y)
  x = x or self.x or 1               -- default dimensions or inherit
	y = y or self.y or 1

  local data = love.image.newImageData(x, y)
  local img = love.graphics.newImage(data)
  img:setFilter("linear", "nearest")

	local o = {
		data = ffi.cast("uint8_t*", data:getPointer()),		   -- pointer to data
		x = x, y = y, z = 3,			       -- set extents
		sx = 4, sy = x*4, sz = 1,        -- set strides
    ox = 0, oy = 0, oz = 0,          -- set offsets
		cs = "SRGB",			               -- default CS or inherit
    image = img,                    -- reference for image operations
		imageData = data,								-- reference for picel storage
    scale = 1,
    drawOffset = {x=0, y=0}
	}
  ffi.fill(o.data, x*y*4, 255)       -- fill white
	setmetatable(o, image.meta)         -- inherit data methods
	return o
end

function image.meta.__tostring(a)
	return "Image["..a.x..", "..a.y..", "..a.z.."] ("..a.cs..")"
end

-- conversion to and from c structures
ffi.cdef[[
	typedef struct{
		uint8_t *data;		// buffer data
		int x, y, z;	  // dimensions
		int sx, sy, sz;	// strides
		int ox, oy, oz; // offsets
		int cs;					// color space
	} imageStruct;
]]
image.CStruct = ffi.typeof("imageStruct")

function image:toCStruct()
	-- remember to anchor data allocation!!!
	return self.CStruct(self.data,
		self.x, self.y, self.z,
		self.sx, self.sy, self.sz,
		self.ox, self.oy, self.oz,
		0) -- FIXME export color space
end

function image:fromCStruct()
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
	setmetatable(o, self.meta) -- inherit data methods
	return o
end


function image:idx(x, y, z)
  return (x*self.sx+(self.y-y-1)*self.sy+z*self.sz)
end

--[[
function image:set(x, y, z, v)
  if v<-1 then v = -1 elseif v>2 then v = 2 end
  v = cs.LRGB.SRGB(v)
  self.data[self:idx(x, y, z)] = v*255
end
--]]

function image:get(x, y, z)
  return self.data[self:idx(x, y, z)]
end

function image:refresh()
  self.image:replacePixels(self.imageData)
  return self
end

function image:draw(x, y)
  love.graphics.draw(self.image, x + self.drawOffset.x, y+self.drawOffset.y, 0, self.scale, self.scale)
end

function image:toChTable()
  local o = {
		data = tonumber(ffi.cast("uintptr_t", self.data)),
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

function image:fromChTable()
  local o = {
		data = ffi.cast("uint8_t*", self.data),
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
  setmetatable(o, image.meta)
  return o
end

return image
