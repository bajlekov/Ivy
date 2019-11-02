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
#include "cs.cl"

kernel void convert(global float *I, global float *M, global float *W, global float *P, global float *flags)
{
	const int x = get_global_id(0);
	const int y = get_global_id(1);

	float3 i = $I[x, y];

	bool c = i.x>0.95f || i.y>0.95f || i.z>0.95f;

	if (flags[3]>0.5f)
		i = i * $P[0, 0];

	if (c && flags[5]>0.5f)
		i = (float3)(LRGBtoY(i));

	if (flags[4]>0.5f)
		i = i * $W[0, 0];

	if (flags[3]>0.5f) {
		if (c && flags[5]<0.5f)
			i = clamp(i, 0.0f, 1.0f);

		float3 o = i;
		o.x = i.x*$M[0, 0, 0] + i.y*$M[0, 1, 0] + i.z*$M[0, 2, 0];
		o.y = i.x*$M[1, 0, 0] + i.y*$M[1, 1, 0] + i.z*$M[1, 2, 0];
		o.z = i.x*$M[2, 0, 0] + i.y*$M[2, 1, 0] + i.z*$M[2, 2, 0];

		if (c && flags[5]>0.5f)
			o = (float3)(LRGBtoY(o));

		$I[x, y] = o;
	} else {
		$I[x, y] = i;
	}
}
]]

local function execute()
	proc:getAllBuffers("I", "M", "W", "P", "flags")
	proc.buffers.M.__write = false
	proc.buffers.W.__write = false
	proc:executeKernel("convert", proc:size2D("I"))
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
