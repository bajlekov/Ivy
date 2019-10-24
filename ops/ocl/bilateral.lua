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

local proc = require "lib.opencl.process.ivy".new()

local source = [[
const eps = 0.000001

kernel bilateral(I, D, S, O)
  const x = get_global_id(0)
  const y = get_global_id(1)

	var w = 0.0
	var o = vec(0.0)

	var i = I[x, y]
	var df = max(D[x, y, 0], eps)^2*5.0
	var sf = max(S[x, y, 0], eps)^2*0.01

	for ox = -9, 9 do
		for oy = -9, 9 do
			var j = I[x+ox, y+oy]

			var d = ox^2 + oy^2
			var s = (i.x-j.x)^2 + (i.y-j.y)^2 + (i.z-j.z)^2
			var f = exp(-d/df - s/sf)

			o = o + f*j
			w = w + f
		end
  end

	O[x, y] = o / w
end
]]

local function execute()
	local I, D, S, O = proc:getAllBuffers(4)
	proc:executeKernel("bilateral", proc:size2D(O), {I, D, S, O})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
