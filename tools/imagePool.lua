--[[
  Copyright (C) 2011-2019 G. Bajlekov

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

-- create image pool which allows using a cropped view while preserving the full image

local ffi = require "ffi"
local data = require "data"
local thread = require "thread"

local pool = {}
pool.images = {}
pool.sx = 0
pool.sy = 0
pool.x = 0
pool.y = 0
pool.w = 0
pool.h = 0

function pool.resize(x, y) -- resize full image
	if not(pool.x==x and pool.y==y) then
		pool.sx = x
		pool.sy = y

		for k, v in pairs(pool.images) do
			v.full = data:new(x, y, v.full.z)
		end
	end
end

function pool.crop(x, y, w, h) -- select new crop for views
	pool.x = x
	pool.y = y
	pool.w = w
	pool.h = h

	for k, v in pairs(pool.images) do
		--
	end
end

local offset = data:new(1, 1, 3)
offset:set(0, 0, 2, 1) -- no scaling!


local function get(image, write)
	if write==nil then write = true end -- TODO: decide on proper default

	if image.view and image.x==pool.x and image.y==pool.y and image.w==pool.w and image.h==pool.h then
		return image.view
	else
		if image.view and write then
			offset:set(0, 0, 0, image.x)
			offset:set(0, 0, 1, image.y)
			offset:toDevice()
			thread.ops.paste({image.view, image.full, offset}, "dev")
			print(image.view, image.full)
		end
		if not (image.w==pool.w and image.h==pool.h) then
			image.view = data:new(pool.w, pool.h, image.full.z)
			image.w = pool.w
			image.h = pool.h
		end
		offset:set(0, 0, 0, pool.x)
		offset:set(0, 0, 1, pool.y)
		offset:toDevice()
		thread.ops.crop({image.full, image.view, offset}, "dev")
		image.x = pool.x
		image.y = pool.y
		return image.view
	end
end

function pool.add(fullImage)
	print(fullImage.x, fullImage.y)
	local image = {}
	image.full = fullImage
	image.view = false
	image.x = false
	image.y = false
	image.w = false
	image.h = false
	image.get = get

	pool[fullImage] = image

	return image
end

return pool
