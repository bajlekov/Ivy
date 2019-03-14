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

local ffi = require "ffi"
local data = require "data"

local raw = {}

local libraw = ffi.load("lib/libraw/Windows/libraw.dll")

do
	local f = io.open("lib/libraw/Windows/libraw.h", "r")
	ffi.cdef(f:read("*all"))
	f:close()
end

function raw.read(name)
	local rawData = libraw.libraw_init(0);
	if type(name) ~= "string" then
		name = name:getFilename()
	end
	assert(libraw.libraw_open_file(rawData, name)==0)

	libraw.libraw_set_output_bps(rawData, 16) -- 16-bit output
	libraw.libraw_set_output_color(rawData, 0) -- RAW color space
	libraw.libraw_set_demosaic(rawData, 11) -- DHT interpolation

	libraw.libraw_set_gamma(rawData, 0, 1) -- no gamma correction
	libraw.libraw_set_gamma(rawData, 1, 1)

	libraw.libraw_set_no_auto_bright(rawData, 1)

	libraw.libraw_unpack(rawData)

	libraw.libraw_dcraw_process(rawData)

	local img = libraw.libraw_dcraw_make_mem_image(rawData, NULL)
	local w = img.width
	local h = img.height

	local M = ffi.new("float[3][4]") -- RAW to sRGB matrix
	for i = 0, 2 do
		for j = 0, 3 do
			M[i][j] = rawData.color.rgb_cam[i][j]
		end
	end

	local W = ffi.new("float[3]", {
		rawData.color.cam_mul[0] / rawData.color.pre_mul[0],
		rawData.color.cam_mul[1] / rawData.color.pre_mul[1],
		rawData.color.cam_mul[2] / rawData.color.pre_mul[2],
	}) -- WB coefficients in RAW space
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
	print(W[0], W[1], W[2])

	local buffer = data:new(w, h, 3)

	local WB = false
	local sRGB = false

	for x = 0, w-1 do
		for y = 0, h-1 do
			local ri = (img.data[((x+y*w)*3 + 0)*2] + img.data[((x+y*w)*3 + 0)*2 + 1]*256)/65535
			local gi = (img.data[((x+y*w)*3 + 1)*2] + img.data[((x+y*w)*3 + 1)*2 + 1]*256)/65535
			local bi = (img.data[((x+y*w)*3 + 2)*2] + img.data[((x+y*w)*3 + 2)*2 + 1]*256)/65535

			if WB then
				ri = ri * W[0]
				gi = gi * W[1]
				bi = bi * W[2]
			end

			local ro = ri
			local go = gi
			local bo = bi
			if sRGB then
				ro = ri*M[0][0] + gi*M[0][1] + bi*M[0][2]
				go = ri*M[1][0] + gi*M[1][1] + bi*M[1][2]
				bo = ri*M[2][0] + gi*M[2][1] + bi*M[2][2]
			end

			buffer:set(x, h-y-1, 0, ro)
			buffer:set(x, h-y-1, 1, go)
			buffer:set(x, h-y-1, 2, bo)
		end
	end

	local SRGBmatrix = data:new(3, 4, 1)
	local WBmultipliers = data:new(1, 1, 3)

	for i = 0, 2 do
		WBmultipliers:set(0, 0, i, W[i])
		for j = 0, 3 do
			SRGBmatrix:set(i, j, 0, M[i][j])
		end
	end

	libraw.libraw_dcraw_clear_mem(img)
	libraw.libraw_close(rawData)

	return buffer, SRGBmatrix, WBmultipliers
end

return raw
