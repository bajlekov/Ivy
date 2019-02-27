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

kernel void lightnessAdjust(global float *P, global float *S, global float *R, global float *C) {
	const int z = get_global_id(2);

  float p = -P[3]/1000.0f;
	float a = S[0];
	float b = z/255.0f;

	float r = 1.0f/R[0];
	float f = range(a, b, r);

	float i = C[z];

	float o = i + f*p;

	C[z] = clamp(o, 0.0f, 1.0f);
}
]]

local function execute()
	proc:getAllBuffers("P", "S", "R", "C")
	proc:executeKernel("lightnessAdjust", {1, 1, 256})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
