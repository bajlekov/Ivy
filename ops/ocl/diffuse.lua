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

local proc = require "lib.opencl.process".new()

local source = [[
float range(float a, float b, float s) {
  float x = (a-b)*s;
  x = clamp(x, -1.0f, 1.0f);
  float x2 = x*x;
  float x4 = x2*x2;
  return (1.0f-2.0f*x2+x4);
}

kernel void diffuse(global float *I, global float *F, global float *S, global float *O)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float i = $I[x, y, 0];
	float xp = $I[x+1, y, 0];
	float xn = $I[x-1, y, 0];
	float yp = $I[x, y+1, 0];
	float yn = $I[x, y-1, 0];
	float d1 = $I[x+1, y+1, 0];
	float d2 = $I[x-1, y-1, 0];
	float d3 = $I[x+1, y-1, 0];
	float d4 = $I[x-1, y+1, 0];

	float f = $F[x, y, 0] * 0.1f;

	// attenuate f dependent on noise
	float att = 2.5f/$S[x, y, 0];

	float a = (xp + xn - 2.0f*i);
	a = a*(1.0f - range(0.0f, a, att));
	float b = ( yp + yn - 2.0f*i);
	b = b*(1.0f - range(0.0f, b, att));
	float c = (d1 + d2 - 2.0f*i);
	c = c*(1.0f - range(0.0f, c, att));
	float d = (d3 + d4 - 2.0f*i);
	d = d*(1.0f - range(0.0f, d, att));

	float o = i - f*a - f*b - 0.5f*f*c - 0.5f*f*d;

	// ignore diagonals during clamping due to mosaicing artifacts
	float m;
	m = fmax(fmax(fmax(fmax(xp, xn), yp), yn), i);
	//m = fmax(fmax(fmax(fmax(d1, d2), d3), d4), m);
	o = fmin(o, m);
	m = fmin(fmin(fmin(fmin(xp, xn), yp), yn), i);
	//m = fmin(fmin(fmin(fmin(d1, d2), d3), d4), m);
	o = fmax(o, m);

	$O[x, y, 0] = o;
	$O[x, y, 1] = $I[x, y, 1];
	$O[x, y, 2] = $I[x, y, 2];
}
]]

local function execute()
	proc:getAllBuffers("I", "F", "S", "O")
	proc:executeKernel("diffuse", proc:size2D("O"))
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
