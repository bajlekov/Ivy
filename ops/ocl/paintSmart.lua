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

float range_s(float v, float t, float s) {
	float a = t - t*s;
	float b = t + t*s;
	float x = clamp((v - a)/(2*t*s), 0.0f, 1.0f);
  float x2 = x*x;
  float x4 = x2*x2;
  return (1.0f-2.0f*x2+x4);
}

kernel void paintSmart(global float *O, global float *I, global float *P) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float px = P[0]; // x-position
	float py = P[1]; // y-position
	float ps = P[4]; // brush size

	if (px - ps + x<0 || px - ps + x>=$O.x$ || py - ps + y<0 || py - ps + y>=$O.y$) return;

	float3 i = $I[px - ps + x, py - ps + y];
  float3 s = $I[px, py];

  float d = sqrt(pown(i.x-s.x, 2) + pown(i.y-s.y, 2) + pown(i.z-s.z, 2));

	float mask = range_s(d, P[2], P[3]); // P[2] = range, P[3] = sharpness

	d = sqrt((float)((x - ps)*(x - ps) + (y - ps)*(y - ps)))/ps;
	float d2 = d*d;
	float d4 = d2*d2;
	float f = d<1.0f ? 1.0f - 2.0f*d2 + d4 : 0.0f;

	float o = $O[px - ps + x, py - ps + y];

	$O[px - ps + x, py - ps + y] = clamp(mask*f*P[5] + o, 0.0f, 1.0f); // P[5] = value
}
]]

local function execute()
	proc:getAllBuffers("O", "I", "P")
	proc.buffers.P.__write = false
	local ps = math.ceil(proc.buffers.P:get(0, 0, 4))
	proc:executeKernel("paintSmart", {ps*2+1, ps*2+1})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
