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

local proc = require "lib.opencl.process.ivy".new()

local source = [[
function gaussian(x, s)
	return exp(-0.5 * (x/s)^2 )
end

function blur(T, x, y, w)
	var t = 0.0
	if w==0.0 then
		t = T[x, y, 0]
	else
		var g = {gaussian(0, w), gaussian(1, w), gaussian(2, w), gaussian(3, w)}
		var n = g[0] + 2*g[1] + 2*g[2] + 2*g[3]
		g[0] = g[0]/n
		g[1] = g[1]/n
		g[2] = g[2]/n
		g[3] = g[3]/n

		t = 0
		for i = -3, 3 do
			for j = -3, 3 do
				t = t + T[x+i, y+j, 0] * g[abs(i)]*g[abs(j)]
			end
		end
	end

	return t
end

kernel blur_div(I, T, O, W)
	const x = get_global_id(0)
	const y = get_global_id(1)

	var w = W[x, y]
	var t = blur(T, x, y, w)

	O[x, y, 0] = I[x, y, 0]/(t + 0.000001)
end

kernel blur_mul(I, T, O, W)
	const x = get_global_id(0)
	const y = get_global_id(1)

	var w = W[x, y]
	var t = blur(T, x, y, w)

	O[x, y, 0] = I[x, y, 0]*t
end

kernel post(I, O, F, oc)
	const x = get_global_id(0)
	const y = get_global_id(1)

	var o = O[x, y, 0]
	var i = I[x, y, 0]
	var f = F[x, y]

	o = i + f*(o-i)

	o = overshoot_clamp(I, x, y, o, oc[0])

	O[x, y, 0] = o
	O[x, y, 1] = I[x, y, 1]
	O[x, y, 2] = I[x, y, 2]
end
]]

local function execute()
	local I, O, W, F, oc = proc:getAllBuffers(5) -- iterations, radius and strength

	local x, y, z = I:shape()
	local T = I:new(x, y, 1)

	proc:executeKernel("blur_div", proc:size2D(I), {I, I, T, W})
	proc:executeKernel("blur_mul", proc:size2D(I), {I, T, O, W})

	for n = 2, 5 do
		proc:executeKernel("blur_div", proc:size2D(I), {I, O, T, W})
		proc:executeKernel("blur_mul", proc:size2D(I), {I, T, O, W})
	end

	proc:executeKernel("post", proc:size2D(I), {I, O, F, oc})

	T:free()
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceFile("overshoot.ivy")
	proc:loadSourceString(source)
	return execute
end

return init
