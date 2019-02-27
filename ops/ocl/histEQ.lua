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

local ffi = require "ffi"
local tools = require "lib.opencl.tools"

local proc = require "lib.opencl.process".new()

local source = [[
kernel void clearHist(global uint *H) {
  const int x = get_global_id(0);
  H[x] = 0;
}

kernel void buildHist(global float *I, global uint *H) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float v = $I[x, y, 0]; // Y channel of XYZ image
  uint i = (uint)round(clamp(v, 0.0f, 1.0f)*1022.0f) + 1;
	atomic_inc(H + i);
}

kernel void cumulativeHist(global uint *H) {
	float v = 0.0f;
	float n = 1.0f/($I.x$*$I.y$);

	global float* Hf = (global float*)H;

	for (uint i = 0; i<1024; i++) {
		v += H[i];
		Hf[i] = v*n;
	}
}

kernel void applyHist(global float *I, global float *H, global float *O) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

  float3 i = $I[x, y];

	float j = clamp(i.x, 0.0f, 1.0f)*1023.0f;

  uint lowIdx = clamp(floor(j), 0.0f, 1023.0f);
	uint highIdx = clamp(ceil(j), 0.0f, 1023.0f);

	float lowVal = H[lowIdx];
	float highVal = H[highIdx];

	float factor = lowIdx==highIdx ? 1.0f : (j-lowIdx)/(highIdx-lowIdx);
	j = lowVal*(1.0f - factor) + highVal*factor;

	float3 o;
	o.x = j;
	o.y = i.y*j/i.x;
	o.z = i.z*j/i.x;

  $O[x, y] = o;
}
]]

local previewBuffer
local previewX
local previewY

local function execute()
	proc:getAllBuffers("I", "H", "O")

	proc:executeKernel("clearHist", {1024}, {"H"})
	proc:executeKernel("buildHist", proc:size2D("I"), {"I", "H"})
	proc:executeKernel("cumulativeHist", {1}, {"H"})
	proc:executeKernel("applyHist", proc:size2D("O"), {"I", "H", "O"})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
