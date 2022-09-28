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
local fs = require "lib.fs"

local stb = {}

local format = {}

local SRGBtoLRGB = require "tools.cs".SRGB.LRGB

local formats = love.graphics.getImageFormats()
assert(formats.rgba32f, "RGBA32F format not supported")

function format.rgba8(image)
	love.graphics.push()
	love.graphics.origin()
	local x, y = image:getPixelDimensions()

	local canvas = love.graphics.newCanvas(x, y, {format = "rgba32f"})

	love.graphics.setCanvas(canvas)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(image)
	love.graphics.setCanvas()

	local canvasData = canvas:newImageData()
	local canvasDataPtr = canvasData:getPointer()

	local buf = ffi.cast("float*", canvasDataPtr)

	local data = data:new(x, y, 3):allocHost()

	for i = 0, x - 1 do
		for j = 0, y - 1 do
			local r, g, b
			r = buf[i * 4 + (y - j-1) * x * 4 ]
			g = buf[i * 4 + (y - j-1) * x * 4 + 1]
			b = buf[i * 4 + (y - j-1) * x * 4 + 2]

			r, g, b = SRGBtoLRGB(r, g, b)
			data:set(i, j, 0, math.max(r, 0))
			data:set(i, j, 1, math.max(g, 0))
			data:set(i, j, 2, math.max(b, 0))
		end
	end

	love.graphics.pop()
	return data
end

function stb.read(fileName)
	if type(fileName) == "string" and love.filesystem.isFused() then
		if love.filesystem.mount(love.filesystem.getSourceBaseDirectory(), "base") then
			fileName = "base/"..fileName
		end
	end
	
	-- load file data first as love.graphics.newImage can't access non-local resources
	if type(fileName) ~= "string" then
		fileName = fileName:getFilename()
	end
	local file = fs.open(fileName, "r")
	local fileSize = file:attr("size")
	local fileData = love.data.newByteData( fileSize )
	file:read(fileData:getFFIPointer(), fileSize)

	local status, image = pcall(love.graphics.newImage, fileData)

	if status then
		return format[image:getFormat()](image)
	else -- try raw file reading
		local raw = require "io.raw"
		return raw.read(fileName)
	end

end

return stb
