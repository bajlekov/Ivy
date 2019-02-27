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
float range(float a, float b, float s) {
  float x = (a-b)*s;
  x = clamp(x, -1.0f, 1.0f);
  float x2 = x*x;
  float x4 = x2*x2;
  return (1.0f-2.0f*x2+x4);
}

float range_circular(float a, float b, float s) {
  return range(a, b, s) + range(a, b-1, s) + range(a, b+1, s);
}

kernel void smartSelect(global float *I, float global *R, float global *D,  global float *P, global float *S, global float *O, global float *M)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);

  float xs = P[0];
  float ys = P[1];

	float r = 1.0f/$R[x, y, 0];
	float d = 1.0f/$D[x, y, 0]/P[2];

  float3 s = $S[0, 0];
  float3 i = $I[x, y];

  float d1 = sqrt(pown(x-xs, 2) + pown(y-ys, 2));
  float d2 = sqrt(pown(i.x-s.x, 2) + pown(i.y-s.y, 2) + pown(i.z-s.z, 2));

  float mask = range(0.0f, d1, d)*range(0.0f, d2, r);

  $O[x, y, 0] = i.x;
  $O[x, y, 1] = i.y*mask;
  $O[x, y, 2] = i.z*mask;
  $M[x, y, 0] = mask;
}
]]

local function execute()
  proc:getAllBuffers("I", "R", "D", "P", "S", "O", "M")
  proc:executeKernel("smartSelect", proc:size2Dmax("O", "M"))
end

local function init(d, c, q)
  proc:init(d, c, q)
  proc:loadSourceString(source)
  return execute
end

return init
