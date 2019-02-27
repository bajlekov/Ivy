--[[
  Copyright (C) 2011-2018 G. Bajlekov

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

local ppm = {}

local function skipComment(file)
	local position = file:seek()
	local str = file:read("*l")
	while str:len() == 0 or str:byte() < 49 or str:byte() > 57 do
		position = file:seek()
		str = file:read("*l")
	end
	file:seek("set", position)
end

local SRGBtoLRGB = require "tools.cs".SRGB.LRGB

local function fromString3(stringData, sx, sy, scale, linear)
	local depth = scale < 256 and 1 or 2
	local byteSize = sx * sy * 3 * depth
	local byteData = ffi.new("uint8_t[?]", byteSize, stringData) -- TODO: check if ffi.copy is more appropriate
	local bufferData = data:new(sx, sy, 3)
	local scale = 1 / scale
	for x = 0, sx - 1 do
		for y = 0, sy - 1 do
			local r, g, b
			if depth == 2 then
				r = (byteData[y * sx * 6 + x * 6 + 0] * 256 + byteData[y * sx * 6 + x * 6 + 1]) * scale
				g = (byteData[y * sx * 6 + x * 6 + 2] * 256 + byteData[y * sx * 6 + x * 6 + 3]) * scale
				b = (byteData[y * sx * 6 + x * 6 + 4] * 256 + byteData[y * sx * 6 + x * 6 + 5]) * scale
			else
				r = byteData[y * sx * 3 + x * 3 + 0] * scale
				g = byteData[y * sx * 3 + x * 3 + 1] * scale
				b = byteData[y * sx * 3 + x * 3 + 2] * scale
			end
			if not linear then r, g, b = SRGBtoLRGB(r, g, b) end
			bufferData:set(x, sy - y-1, 0, r)
			bufferData:set(x, sy - y-1, 1, g)
			bufferData:set(x, sy - y-1, 2, b)
		end
	end
	return bufferData
end

local function fromString1(stringData, sx, sy, scale, linear)
	local depth = scale < 256 and 1 or 2
	local byteSize = sx * sy * depth
	local byteData = ffi.new("uint8_t[?]", byteSize, stringData) -- TODO: check if ffi.copy is more appropriate
	local bufferData = data:new(sx, sy, 1)
	local scale = 1 / scale
	for x = 0, sx - 1 do
		for y = 0, sy - 1 do
			local v
			if depth == 2 then
				v = (byteData[y * sx * 2 + x * 2] * 256 + byteData[y * sx * 2 + x * 2 + 1]) * scale
			else
				v = byteData[y * sx + x] * scale
			end
			if not linear then v = SRGBtoLRGB(v) end
			bufferData:set(x, sy - y-1, 0, v)
		end
	end
	return bufferData
end

function ppm.read(fileName, linear)
	local file = io.open(fileName, (ffi.os == "Windows" and "rb" or "r"))
	assert(file:read("*l") == "P6", "wrong image format!")
	skipComment(file)
	local sx, sy, scale = file:read("*n", "*n", "*n", "*l")
	local stringData = file:read("*a")
	file:close()
	return fromString3(stringData, sx, sy, scale, linear)
end


function ppm.readStream(file, linear, scaleOverride)
	-- P5 for B/W raw image
	local fileType = file:read("*l")

	assert(fileType == "P6" or fileType == "P5", "wrong image format!")

	local str = ""
	while str:len() == 0 or str:byte() < 49 or str:byte() > 57 do
		str = file:read("*l")
	end
	local sx, sy = str:match("(%d+)%s(%d+)")
	str = file:read("*l")
	local scale = str:match("(%d+)")
	sx, sy, scale = tonumber(sx), tonumber(sy), tonumber(scale)

	local stringData = file:read("*a")
	file:close()
	if fileType == "P6" then
		return fromString3(stringData, sx, sy, scaleOverride or scale, linear)
	elseif fileType == "P5" then
		return fromString1(stringData, sx, sy, scaleOverride or scale, linear)
	end
end

return ppm
