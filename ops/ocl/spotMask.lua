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

kernel void spotMask(global float *I, global float *O, global float *P, int idx) {
	const int x = get_global_id(0);
	const int y = get_global_id(1);
	const int z = get_global_id(2);

	int s = $P[0, idx, 4];		// spot size
	float f = $P[0, idx, 5];		// spot falloff

	int sx = floor($P[0, idx, 0]*$O.x$) - s + x;	// source x
	int sy = floor($P[0, idx, 1]*$O.y$) - s + y;	// source y
	int dx = floor($P[0, idx, 2]*$O.x$) - s + x;	// destination x
	int dy = floor($P[0, idx, 3]*$O.y$) - s + y;	// destination y

	if (dx<0 || dx>=$O.x$ || dy<0 || dy>=$O.y$) return; // clamp to image

	float d = sqrt( (float)((x-s)*(x-s) + (y-s)*(y-s)) ); // distance from center
	float mask = range(d, s/(1 + f), f);

	float o = $O[dx, dy, z];
	float i = $I[sx, sy, z];

	$O[dx, dy, z] = (1-mask)*o + mask*i;
}
]]

local ffi = require "ffi"
local idx = ffi.new("cl_int[1]", 0)

local function execute()
	proc:getAllBuffers("O", "I", "P")
	proc.buffers.P.__write = false
	proc.buffers.I.__write = false
	for i = 0, proc.buffers.P.y-1 do
		idx[0] = i
		print("starting spot "..idx[0], proc.buffers.P:get(0, i, 0), proc.buffers.P:get(0, i, 1))
		local ps = math.ceil(proc.buffers.P:get(0, i, 4)) -- brush size
		proc:executeKernel("spotMask", {ps*2+1, ps*2+1, proc.buffers.O.z}, {"O", "I", "P", idx})
		proc.queue:finish()
	end
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
