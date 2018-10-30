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
kernel void bilateral(global float *I, global float *D, global float *S, global float *O)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float w = 0.0f;
	float3 o = (float3)0.0f;

	float3 i = $I[x, y];
	float df = pown(max($D[x, y, 0], 0.000001f), 2)*5.0f;
	float sf = pown(max($S[x, y, 0], 0.000001f), 2)*0.01f;

	for (int ox = -7; ox<=7; ox++)
		for (int oy = -7; oy<=7; oy++) {
			float3 j = $I[x+ox, y+oy];

			float d = pown((float)ox, 2) + pown((float)oy, 2);
			float s = pown(i.x-j.x, 2) + pown(i.z-j.z, 2) + pown(i.z-j.z, 2);
			float f = exp(-d/df -s/sf);

			o += f*j;
			w += f;
		}
	o = o/w;

	$O[x, y] =  o;
}
]]

local function execute()
	proc:getAllBuffers("I", "D", "S", "O")
	proc:executeKernel("bilateral", proc:size2D("O"))
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
