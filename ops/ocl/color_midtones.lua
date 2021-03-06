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
kernel midtones(I, P, O)
	const x = get_global_id(0)
	const y = get_global_id(1)

	var i = I[x, y]
	var p = P[x, y]

	var v = clamp(LRGBtoL(i), 0.0, 1.0)
	v = range(0.25, 0.25, abs(0.5-v))

	O[x, y] = i + p*v
end
]]

local function execute()
	local I, P, O = proc:getAllBuffers(3)
	proc:executeKernel("midtones", proc:size2D(O), {I, P, O})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
