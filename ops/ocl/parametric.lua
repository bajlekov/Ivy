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
kernel parametric(I, P1, P2, P3, P4, O)
	const x = get_global_id(0)
	const y = get_global_id(1)

	var i = I[x, y, 0]

	var p1 = P1[x, y, 0]
	var p2 = P2[x, y, 0]
	var p3 = P3[x, y, 0]
	var p4 = P4[x, y, 0]

	var g1 = 0.0
	if i<0.5 then
		g1 = p1*i*(2.0*i-1.0)^2
	end
	var g2 = p2*i*(i-1.0)^2
	var g3 = -p3*(i-1.0)*i^2
	var g4 = 0.0
	if i>0.5 then
		g4 = -p4*(i-1.0)*(2.0*i-1.0)^2
	end

	var g = i + g2 + g3
	g = g + g1*g/(i+0.00001) + g4*(1-g)/(1-i+0.00001)

	O[x, y, 0] = g
	O[x, y, 1] = I[x, y, 1] * g/i
	O[x, y, 2] = I[x, y, 2] * g/i
end
]]

local function execute()
	local I, P1, P2, P3, P4, O = proc:getAllBuffers(6)
	proc:executeKernel("parametric", proc:size2D(O), {I, P1, P2, P3, P4, O})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
