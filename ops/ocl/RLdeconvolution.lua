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
float gaussian(float x, float s) {
	return exp(-0.5f*pown(x/s, 2));
}

kernel void blur_div(global float *I, global float *O, global float *T, global float *W) {
	const int x = get_global_id(0);
	const int y = get_global_id(1);

	float w = $W[x, y];

	// blur O
	float o;
	if (w==0.0f) {
		o = $O[x, y, 0];
	} else {
		float g[4] = {gaussian(0, w), gaussian(1, w), gaussian(2, w), gaussian(3, w)};
		float n = g[0] + 2*g[1] + 2*g[2] + 2*g[3];
		g[0] /= n; g[1] /= n; g[2] /= n; g[3] /= n;

		o = 0;
		for (int i = -3; i<=3; i++)
			for (int j = -3; j<=3; j++)
				o += $O[x+i, y+j, 0] * g[abs(i)]*g[abs(j)];
	}

	// T = I/blur(O)
	$T[x, y, 0] = $I[x, y, 0]/(o + 1e-5f);
}

kernel void blur_mul(global float *I, global float *T, global float *O, global float *W) {
	const int x = get_global_id(0);
	const int y = get_global_id(1);

	float w = $W[x, y];

	// blur T
	float t;
	if (w==0.0f) {
		t = $T[x, y, 0];
	} else {
		float g[4] = {gaussian(0, w), gaussian(1, w), gaussian(2, w), gaussian(3, w)};
		float n = g[0] + 2*g[1] + 2*g[2] + 2*g[3];
		g[0] /= n; g[1] /= n; g[2] /= n; g[3] /= n;

		t = 0;
		for (int i = -3; i<=3; i++)
			for (int j = -3; j<=3; j++)
				t += $T[x+i, y+j, 0] * g[abs(i)]*g[abs(j)];
	}

	// O = I*blur(T)
	$O[x, y, 0] = $I[x, y, 0]*t;
}

kernel void post(global float *I, global float *O, global float *F) {
	const int x = get_global_id(0);
	const int y = get_global_id(1);

	float o = $O[x, y, 0];
	float i = $I[x, y, 0];
	float f = $F[x, y];

	o = i + f*(o-i);

	/*
	float xp = $I[x+1, y, 0];
	float xn = $I[x-1, y, 0];
	float yp = $I[x, y+1, 0];
	float yn = $I[x, y-1, 0];
	float m;
	m = fmax(fmax(fmax(fmax(xp, xn), yp), yn), i);
	o = fmin(o, m);
	m = fmin(fmin(fmin(fmin(xp, xn), yp), yn), i);
	o = fmax(o, m);
	*/

	$O[x, y, 0] = o;
	$O[x, y, 1] = $I[x, y, 1];
	$O[x, y, 2] = $I[x, y, 2];
}
]]

local function execute()
	proc:getAllBuffers("I", "O", "W", "F") -- iterations, radius and strength

	local I = proc.buffers.I
	local O = proc.buffers.O
	do
		local x, y, z = proc.buffers.I:shape()
		proc.buffers.T = proc.buffers.I:new(x, y, 1)
	end

	proc.buffers.O = I -- first iteration
	proc:executeKernel("blur_div", proc:size2D("I"), {"I", "O", "T", "W"})
	proc.buffers.O = O
	proc:executeKernel("blur_mul", proc:size2D("I"), {"I", "T", "O", "W"})

	for n = 2, 25 do
		proc:executeKernel("blur_div", proc:size2D("I"), {"I", "O", "T", "W"})
		proc:executeKernel("blur_mul", proc:size2D("I"), {"I", "T", "O", "W"})
	end

	proc:executeKernel("post", proc:size2D("I"), {"I", "O", "F"})

	proc.buffers.T:free()
	proc.buffers.T = nil
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
