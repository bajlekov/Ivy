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

local source = [[
kernel void contrast(global float *I, global float *C, global float *CF, global float *O)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float3 i = $I[x, y];
	float c = $C[x, y, 0] + 1.0f;

 	float o = i.x*2.0f-1.0f;
	float s = sign(o);
	o = (1 - c)*pown(fabs(o), 2) + fabs(o)*c;
	o = (s*o+1.0f)*0.5f;

	float cf = CF[0] > 0.5f ? o/i.x : 1.0f; // preserves saturation when scaling linear values

  $O[x, y] = (float3)(o, i.y*cf, i.z*cf);
}
]]

local function execute()
	proc:getAllBuffers("I", "C", "CF", "O")
	proc:executeKernel("contrast", proc:size2D("O"))
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
