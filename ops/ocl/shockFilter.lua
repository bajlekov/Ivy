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
float gaussian(float x, float s) {
	return exp(-0.5f*pown(x/s, 2));
}

kernel void blur(global float *I, global float *T, global float *W) {
	const int x = get_global_id(0);
	const int y = get_global_id(1);

	float w = $W[x, y];

	// blur I
	float v;
	if (w==0.0f) {
		v = $I[x, y, 0];
	} else {
		float g[4] = {gaussian(0, w), gaussian(1, w), gaussian(2, w), gaussian(3, w)};
		float n = g[0] + 2*g[1] + 2*g[2] + 2*g[3];
		g[0] /= n; g[1] /= n; g[2] /= n; g[3] /= n;

		v = 0;
		for (int i = -3; i<=3; i++)
			for (int j = -3; j<=3; j++)
				v += $I[x+i, y+j, 0] * g[abs(i)]*g[abs(j)];
	}

	$T[x, y, 0] = v;
}

kernel void sharpen(global float *T, global float *O, global float *F) {
	const int x = get_global_id(0);
	const int y = get_global_id(1);

	float t = $T[x, y];
	float xp = $T[x+1, y];
	float xn = $T[x-1, y];
	float yp = $T[x, y+1];
	float yn = $T[x, y-1];

	float gx = xp - xn;
	float gy = yp - yn;
	float n = sqrt(pown(gx, 2) + pown(gy, 2));
	n = (t > (xp+xn+yp+yn)*0.25f) ? n : -n;
	$O[x, y, 0] = t + $F[x, y]*n;
}

kernel void post(global float *I, global float *O) {
	const int x = get_global_id(0);
	const int y = get_global_id(1);

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

	proc:executeKernel("blur", proc:size2D("I"), {"I", "T", "W"})
	proc:executeKernel("sharpen", proc:size2D("I"), {"T", "O", "F"})

	proc.buffers.I = O
	for n = 2, 3 do
		proc:executeKernel("blur", proc:size2D("I"), {"I", "T", "W"})
		proc:executeKernel("sharpen", proc:size2D("I"), {"T", "O", "F"})
	end
	proc.buffers.I = I

	proc:executeKernel("post", proc:size2D("I"), {"I", "O"})

	proc.buffers.T:free()
	proc.buffers.T = nil
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
