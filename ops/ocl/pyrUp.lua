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

local proc = require "lib.opencl.process.ivy".new()

local function execute()
	local L, G, O, f = proc:getAllBuffers(4)
	local x, y, z = O:shape()
	x = math.ceil(x/2)
	y = math.ceil(y/2)
	proc:executeKernel("pyrUpG", {x, y, z}, {L, G, O, f})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceFile("pyr.ivy")
	return execute
end

return init
