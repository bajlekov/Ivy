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
local data = require "data"
local fs = require "lib.fs"

local raw = {}

local libraw
if ffi.os=="Windows" then
	libraw = ffi.load("lib/libraw/Windows/libraw.dll")
elseif ffi.os=="Linux" then
	libraw = ffi.load("raw")
end

do
	local f
	if ffi.os=="Windows" then
		f = io.open("lib/libraw/Windows/libraw.h", "r")
	elseif ffi.os=="Linux" then
		f = io.open("lib/libraw/Linux/libraw.h", "r")
	end
	ffi.cdef(f:read("*all"))
	f:close()
end

function raw.read(name)
	local rawData = libraw.libraw_init(0)
	if type(name) ~= "string" then
		name = name:getFilename()
	end

	local file = fs.open(name, "r")
	local fileSize = file:attr("size")

	local fileData = ffi.new("uint8_t[?]", fileSize)
	file:read(fileData, fileSize)

	assert(libraw.libraw_open_buffer(rawData, fileData, fileSize)==0)

	libraw.libraw_set_output_bps(rawData, 16) -- 16-bit output
	libraw.libraw_set_output_color(rawData, 0) -- RAW color space
	libraw.libraw_set_demosaic(rawData, 11) -- DHT interpolation

	libraw.libraw_set_gamma(rawData, 0, 1) -- no gamma correction
	libraw.libraw_set_gamma(rawData, 1, 1)

	libraw.libraw_set_no_auto_bright(rawData, 1)

	libraw.libraw_unpack(rawData)

	rawData.rawdata.ioparams.raw_color = 1 -- always force raw output!
	rawData.params.no_auto_scale = 1 -- do not rescale values!

	libraw.libraw_dcraw_process(rawData)

	local img = libraw.libraw_dcraw_make_mem_image(rawData, NULL)
	local w = img.width
	local h = img.height

	local range = rawData.color.maximum - rawData.color.black
	local mr, mg, mb = rawData.color.pre_mul[0], rawData.color.pre_mul[1], rawData.color.pre_mul[2]
	local wr, wg, wb = rawData.color.cam_mul[0], rawData.color.cam_mul[1], rawData.color.cam_mul[2]

	local buffer = data:new(w, h, 3)

	for x = 0, w-1 do
		for y = 0, h-1 do
			local r = (img.data[((x+y*w)*3 + 0)*2] + img.data[((x+y*w)*3 + 0)*2 + 1]*256)/range
			local g = (img.data[((x+y*w)*3 + 1)*2] + img.data[((x+y*w)*3 + 1)*2 + 1]*256)/range
			local b = (img.data[((x+y*w)*3 + 2)*2] + img.data[((x+y*w)*3 + 2)*2 + 1]*256)/range

			buffer:set(x, h-y-1, 0, r)
			buffer:set(x, h-y-1, 1, g)
			buffer:set(x, h-y-1, 2, b)
		end
	end

	local P = ffi.new("float[3]") -- pre-multiply coefficients
	local mm = math.min(mr, mg, mb)
	P[0] = mr/mm
	P[1] = mg/mm
	P[2] = mb/mm

	local M = ffi.new("float[3][4]") -- RAW to sRGB matrix
	for i = 0, 2 do
		for j = 0, 3 do
			M[i][j] = rawData.color.rgb_cam[i][j]
		end
	end

	local W = ffi.new("float[3]", wr/mr, wg/mg, wb/mb) -- WB coefficients in RAW space
	do
		local W_min = math.min(
			W[0]*M[0][0] + W[1]*M[0][1] + W[2]*M[0][2],
			W[0]*M[1][0] + W[1]*M[1][1] + W[2]*M[1][2],
			W[0]*M[2][0] + W[1]*M[2][1] + W[2]*M[2][2]
		)
		W[0] = W[0]/W_min
		W[1] = W[1]/W_min
		W[2] = W[2]/W_min
	end

	local SRGBmatrix = data:new(3, 4, 1)
	local WBmultipliers = data:new(1, 1, 3)
	local PREmultipliers = data:new(1, 1, 3)

	for i = 0, 2 do
		WBmultipliers:set(0, 0, i, W[i])
		PREmultipliers:set(0, 0, i, P[i])
		for j = 0, 3 do
			SRGBmatrix:set(i, j, 0, M[i][j])
		end
	end

	libraw.libraw_dcraw_clear_mem(img)
	libraw.libraw_close(rawData)

	return buffer, SRGBmatrix, WBmultipliers, PREmultipliers
end

return raw
