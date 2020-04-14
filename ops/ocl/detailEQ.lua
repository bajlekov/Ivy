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

local ffi = require "ffi"
local proc = require "lib.opencl.process".new()

local source = [[

constant float filter[5][5] = {
  {0.00390625, 0.015625, 0.0234375, 0.015625, 0.00390625},
  {0.015625  , 0.0625  , 0.09375  , 0.0625  , 0.015625  },
  {0.0234375 , 0.09375 , 0.140625 , 0.09375 , 0.0234375 },
  {0.015625  , 0.0625  , 0.09375  , 0.0625  , 0.015625  },
  {0.00390625, 0.015625, 0.0234375, 0.015625, 0.00390625}
};

float weight(const float3 c1, const float3 c2, const float sharpen) {
  return exp(-(pown(c1.x - c2.x, 2) + pown(c1.y - c2.y, 2) + pown(c1.z - c2.z, 2)) * sharpen);
}

kernel void edgeAwareDown(
	global float *H,
	global float *P,
	global float *L,
	global float *D,
	const int lvl) {

  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float3 sum = (float3) 0.0f;
	float3 wgt = (float3) 0.0f;

	float3 i = $H[x, y];
	float s = $P[lvl, 4, 0] * 10.0f;

	const int step = 1<<lvl;

	for (int xx = 0; xx<5; xx++)
		for (int yy = 0; yy<5; yy++) {
			float3 j = $H[x + (xx - 2)*step, y + (yy - 2)*step];
			float w = filter[xx][yy] * weight(i, j, s);

			sum += w * j;
			wgt += w;
		}

	sum = sum / wgt;

	$L[x, y] = sum;
	$D[x, y] = i - sum;
}

kernel void edgeAwareUp(
	global float *O,
	global float *P,
	global float *D,
	const int lvl) {

  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float3 boost = (float3)($P[lvl, 0, 0], $P[lvl, 1, 0], $P[lvl, 1, 0]) * 2.0f;
	float3 threshold = (float3)($P[lvl, 2, 0], $P[lvl, 3, 0], $P[lvl, 3, 0]) * 0.01f;

	float3 d = $D[x, y];
	d = copysign(max(0.0f, fabs(d) - threshold), d);

	float3 o = $O[x, y] + d * boost;

	$O[x, y] = o;
}

]]

local function execute()
	proc:getAllBuffers("I", "P", "O")

	proc.buffers.P.__write = false

	proc.buffers.T = proc.buffers.I:new()

	local D = {}
	for i = 1, 8 do
		D[i] = proc.buffers.I:new()
	end

	proc.buffers.H = proc.buffers.I
	proc.buffers.L = proc.buffers.T

	local lvl = ffi.new("cl_int[1]", 0)
	for i = 1, 8 do
		proc.buffers.D = D[i]

		lvl[0] = i-1

		proc.buffers.H.__read = true
		proc.buffers.L.__read = false
		proc.buffers.D.__read = false
		proc.buffers.H.__write = false
		proc.buffers.L.__write = true
		proc.buffers.D.__write = true

		proc:executeKernel("edgeAwareDown", proc:size2D("I"), {"H", "P", "L", "D", lvl})

		if proc.buffers.L==proc.buffers.T then
			proc.buffers.H = proc.buffers.T
			proc.buffers.L = proc.buffers.O
		else
			proc.buffers.H = proc.buffers.O
			proc.buffers.L = proc.buffers.T
		end
	end
	assert(proc.buffers.L==proc.buffers.T)
	proc.buffers.T:free()
	proc.buffers.T = nil

	proc.buffers.O.__read = true
	proc.buffers.O.__write = true
	local lvl = ffi.new("cl_int[1]", 0)
	for i = 8, 1, -1 do
		proc.buffers.D = D[i]

		lvl[0] = i-1
		proc.buffers.D.__read = true
		proc.buffers.D.__write = false
		proc:executeKernel("edgeAwareUp", proc:size2D("I"), {"O", "P", "D", lvl})
		D[i]:free()
		D[i] = nil
	end
	proc.buffers.H = nil
	proc.buffers.L = nil
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
