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

local proc = require "lib.opencl.process".new()

local source = [[
kernel void linear(global float *X, global float *Y, global float *T, global float *W, global float *O)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
	const int z = get_global_id(3);

	float w = 1024 * $W[x, y, z];

	float2 p = (float2)((float)x, (float)y);				// sampled point
	float2 xy = (float2)($X[x, y, z]*$O.x$, $Y[x, y, z]*$O.y$);	// center point

	float t = $T[x, y, z] + 0.5f; // angle of center line + pi/2

	float cos_t = cospi(t);
	float sin_t = sinpi(t);

	float2 n = (float2)(1.0f, 0.0f);	// x unit vector
	float2 r;													// t rotation matrix
	r.x = cos_t*n.x - sin_t*n.y;
	r.y = sin_t*n.x + cos_t*n.y;
	n = r;														// unit vector T + pi/2

	float d = (p-xy).x*n.x + (p-xy).y*n.y;			// project (p-xy) onto n to get distance from center line
	float o = clamp(d/w * 0.5f + 0.5f, 0.0f, 1.0f);

	$O[x, y, z] = o;
}
]]

local function execute()
	proc:getAllBuffers("X", "Y", "T", "W", "O")
	proc:executeKernel("linear", proc:size3Dmax("O"))
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
