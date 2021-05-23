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

local source = [[
kernel set_high(O)
	const z = get_global_id(2)
	O[z] = float(INFINITY)
end

kernel minimum(I, O)
	const x = get_global_id(0)
	const y = get_global_id(1)
	const z = get_global_id(2)

	atomic_min(O[z].ptr, I[x, y, z])
end
]]

local function execute()
	local I, O = proc:getAllBuffers(2)
	local size = proc:size3D(I)
	proc:executeKernel("set_high", proc:size3D(O), {O})
	proc:executeKernel("minimum", proc:size3D(I), {I, O})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
