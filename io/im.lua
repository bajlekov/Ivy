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
local ppm = require "io.ppm"

local raw = {}

function raw.read(name)
	if type(name) ~= "string" then
		name = name:getFilename()
	end

	local op = "-depth 16"
	local file
	if ffi.os == "Windows" then
		file = io.popen("lib\\magick\\magick convert \""..name.."\" "..op.." ppm:- ", "rb")
	elseif ffi.os == "Linux" then
		file = io.popen("magick convert \""..name.."\" "..op.." ppm:- ", "r")
	end
	return ppm.readStream(file, false, 2^16)
end

return raw
