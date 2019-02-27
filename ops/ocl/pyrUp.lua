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

local proc = require "lib.opencl.process".new()

local function execute()
	proc:getAllBuffers("L", "G", "O", "f")
	local x, y, z = proc.buffers.O:shape()
	x = math.ceil(x/2)
	y = math.ceil(y/2)
	proc:executeKernel("pyrUpG", {x, y, z})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceFile("pyr.cl")
	return execute
end

return init
