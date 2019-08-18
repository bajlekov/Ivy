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
#include "range.cl"

constant float G7[15] = {0.009033, 0.018476, 0.033851, 0.055555, 0.08167, 0.107545, 0.126854, 0.134032, 0.126854, 0.107545, 0.08167, 0.055555, 0.033851, 0.018476, 0.009033};

kernel void paintSmart(global float *O, global float *I, global float *P) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float px = P[0]; // brush x
	float py = P[1]; // brush y
	float ps = P[4]; // brush size

	float ix = px - ps + x; // image x
	float iy = py - ps + y; // image y

	if (ix<0 || ix>=$O.x$ || iy<0 || iy>=$O.y$) return; // clamp to image

	float mask;
	if (P[6]<0.0f) { // negative values disable smart paint
		mask = 1.0f;
	} else if (P[8]<0.5f) {
		float sx = P[9];
		float sy = P[10];
		float3 i = $I[ix, iy];
		float3 s = $I[sx, sy];
		float d = sqrt(pown(i.x-s.x, 2) + pown(i.y-s.y, 2) + pown(i.z-s.z, 2));
		mask = range(d, P[6], P[7]);
	} else {
		float sx = P[9];
		float sy = P[10];
		float d = 0;
		// collect 15x15 area around sample
		for (int j=-7; j<8; j++)
			for (int k=-7; k<8; k++) {
				float3 i = $I[ix+j, iy+k];
				float3 s = $I[sx+j, sy+k];
				d += (pown(i.x-s.x, 2) + pown(i.y-s.y, 2) + pown(i.z-s.z, 2))*G7[j+7]*G7[k+7];
			}
		mask = range(sqrt(d), P[6], P[7]);
	}

	float d = sqrt( pown(x-ps, 2) + pown(y-ps, 2) ); // distance from center
	float brush = range(d, ps/(1 + P[5]), P[5]);

	float f = mask*brush*P[3];
	float o = $O[ix, iy];
	o = o + f*(P[2] - o);

	$O[ix, iy] = clamp(o, 0.0f, 1.0f);
}
]]

--[[
	P[0] - x position
	P[1] - y position
	P[2] - brush value
	P[3] - brush flow
	p[4] - brush size
	p[5] - brush fall-off
	p[6] - smart range
	p[7] - smart range fall-off
	p[7] - smart patch
	p[9] - sample x
	p[10] - sample y
--]]

local function execute()
	proc:getAllBuffers("O", "I", "P")
	proc.buffers.P.__write = false
	proc.buffers.I.__write = false
	local ps = math.ceil(proc.buffers.P:get(0, 0, 4)) -- brush size
	proc:executeKernel("paintSmart", {ps*2+1, ps*2+1})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
