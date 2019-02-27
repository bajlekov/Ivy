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
local ppm = require "io.ppm"

local raw = {}

function raw.read(name)
	if type(name) ~= "string" then
		name = name:getFilename()
	end

	local raw = false

	local op
	if not raw then
		op = "-h -o 1 -6 -g 1 1 -w -W" -- TODO: -w for camera white balance, -W to preserve original brightness
	else
		op = "-h -E -4"
	end


	--[[
	-v        Print verbose messages
	-c        Write image data to standard output
	-e        Extract embedded thumbnail image
	-i        Identify files without decoding them
	-i -v     Identify files and show metadata
	-z        Change file dates to camera timestamp
	-w        Use camera white balance, if possible
	-a        Average the whole image for white balance
	-A <x y w h> Average a grey box for white balance
	-r <r g b g> Set custom white balance
	+M/-M     Use/don't use an embedded color matrix
	-C <r b>  Correct chromatic aberration
	-P <file> Fix the dead pixels listed in this file
	-K <file> Subtract dark frame (16-bit raw PGM)
	-k <num>  Set the darkness level
	-S <num>  Set the saturation level
	-n <num>  Set threshold for wavelet denoising
	-H [0-9]  Highlight mode (0=clip, 1=unclip, 2=blend, 3+=rebuild)
	-t [0-7]  Flip image (0=none, 3=180, 5=90CCW, 6=90CW)
	-o [0-6]  Output colorspace (raw,sRGB,Adobe,Wide,ProPhoto,XYZ,ACES)
	-d        Document mode (no color, no interpolation)
	-D        Document mode without scaling (totally raw)
	-j        Don't stretch or rotate raw pixels
	-W        Don't automatically brighten the image
	-b <num>  Adjust brightness (default = 1.0)
	-g <p ts> Set custom gamma curve (default = 2.222 4.5)
	-q [0-3]  Set the interpolation quality
	-h        Half-size color image (twice as fast as "-q 0")
	-f        Interpolate RGGB as four colors
	-m <num>  Apply a 3x3 median filter to R-G and B-G
	-s [0..N-1] Select one raw image or "all" from each file
	-6        Write 16-bit instead of 8-bit
	-4        Linear 16-bit, same as "-6 -W -g 1 1"
	-T        Write TIFF instead of PPM
	--]]
	local file
	if ffi.os == "Windows" then
		file = io.popen("lib\\dcraw\\Windows\\dcraw -c "..op.." \""..name.."\"", "r"..(ffi.os == "Windows" and "b" or ""))
	elseif ffi.os == "Linux" then
		file = io.popen("dcraw -c "..op.." \""..name.."\"", "r"..(ffi.os == "Windows" and "b" or ""))
	end

	if not raw then
		return ppm.readStream(file, true, 2^16)
	else
		return ppm.readStream(file, true, 4096)
	end
end

return raw
