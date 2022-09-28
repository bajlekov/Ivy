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
local data = require "data"

local source = [[
function range(a, b, s)
  var x = (a-b)*s
  x = clamp(x, -1, 1)
  var x2 = x*x
  var x4 = x2*x2
  return (1-2*x2+x4)
end

kernel diffuse(I, F, S, O)
  const x = get_global_id(0)
  const y = get_global_id(1)

	var i  = I[x, y, 0]
	var xp = I[x+1, y, 0]
	var xn = I[x-1, y, 0]
	var yp = I[x, y+1, 0]
	var yn = I[x, y-1, 0]
	var d1 = I[x+1, y+1, 0]
	var d2 = I[x-1, y-1, 0]
	var d3 = I[x+1, y-1, 0]
	var d4 = I[x-1, y+1, 0]

	var f = F[x, y, 0] * 0.1

	-- attenuate f dependent on noise
	var att = 10/S[x, y, 0]

	var a = xp + xn - 2*i
	a = a*(1 - range(0, a, att))
	var b = yp + yn - 2*i
	b = b*(1 - range(0, b, att))
	var c = d1 + d2 - 2*i
	c = c*(1 - range(0, c, att))
	var d = d3 + d4 - 2*i
	d = d*(1 - range(0, d, att))

	var o = i - f*a - f*b - 0.5*f*c - 0.5*f*d

	-- ignore diagonals during clamping due to mosaicing artifacts
	var m = max(max(max(max(xp, xn), yp), yn), i)
	m = max(max(max(max(d1, d2), d3), d4), m)
	o = min(o, m)
	m = min(min(min(min(xp, xn), yp), yn), i)
	m = min(min(min(min(d1, d2), d3), d4), m)
	o = max(o, m)

	O[x, y, 0] = o
	O[x, y, 1] = I[x, y, 1]
	O[x, y, 2] = I[x, y, 2]
end
]]

local function execute()
	local I, F, S, O = proc:getAllBuffers(4)

	local T = O:new()

	proc:executeKernel("diffuse", proc:size2D(O), {I, F, S, O})
	for i = 2, 5 do
		proc:executeKernel("diffuse", proc:size2D(O), {O, F, S, T})
		proc:executeKernel("diffuse", proc:size2D(O), {T, F, S, O})
	end

	T:free()
	T = nil
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
