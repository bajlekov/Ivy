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

local proc = require "lib.opencl.process".new()

local source = [[
kernel void parametric(global float * I, global float * P1, global float * P2, global float * P3, global float * P4, global float * O)
{
	const int x = get_global_id(0);
	const int y = get_global_id(1);

	float i = $I[x, y, 0];

	float p1 = $P1[x, y, 0];
	float p2 = $P2[x, y, 0];
	float p3 = $P3[x, y, 0];
	float p4 = $P4[x, y, 0];

	float g1 = i<0.5f ? p1*i*pown(2.0f*i-1.0f, 2) : 0.0f;
	float g2 = p2*pown(i-1.0f, 2)*i;
	float g3 = -p3*(i-1.0f)*pown(i, 2);
	float g4 = i>0.5f ? -p4*(i-1.0f)*pown(2.0f*i-1.0f, 2) : 0.0f;

	float g = i + g2 + g3;
	g = g + g1*g/(i+0.00001) + g4*(1-g)/(1-i+0.00001);

	$O[x, y, 0] = g;
	$O[x, y, 1] = $I[x, y, 1] * g/i;
	$O[x, y, 2] = $I[x, y, 2] * g/i;
}
]]

local function execute()
	proc:getAllBuffers("I", "P1", "P2", "P3", "P4", "O")
	proc:executeKernel("parametric", proc:size2D("O"))
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
