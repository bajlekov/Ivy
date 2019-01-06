--[[
  Copyright (C) 2011-2018 G. Bajlekov

    ImageFloat is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ImageFloat is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local proc = require "lib.opencl.process".new()

local source = [[

kernel void vibrance(global float *I, global float *V, global float *P, global float *O)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float3 i = $I[x, y];
	float v = $V[x, y, 0]*i.x + 1.0f;

	i.y = clamp(i.y, 0.0f, 1.0f);
	float o = (1-v)*pown(i.y, 2) + v*i.y;
	i.x *= 1.0f - $P[x, y]*(o - i.y)*0.25f;

  $O[x, y] = (float3)(i.x, o, i.z);
}
]]

local function execute()
	proc:getAllBuffers("I", "V", "P", "O")
	proc:executeKernel("vibrance", proc:size2D("O"))
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
