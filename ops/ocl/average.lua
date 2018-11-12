--[[
  Copyright (C) 2011-2018 G. Bajlekov

    ImageFloat is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ImageFloat is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local proc = require "lib.opencl.process".new()

local source = [[
inline void atomic_add_f(volatile global float *addr, float val) {
	union {
		unsigned int u32;
		float        f32;
	} next, expected, current;
	current.f32 = *addr;

	do {
		expected.f32 = current.f32;
		next.f32 = expected.f32 + val;
		current.u32  = atomic_cmpxchg( (volatile __global unsigned int *)addr, expected.u32, next.u32);
	} while( current.u32 != expected.u32 );
}

kernel void set_zero(global float *O) {
	const int z = get_global_id(2);
	O[z] = 0.0f;
}

kernel void average(global float *I, global float *O) {
	const int y = get_global_id(1);
	const int z = get_global_id(2);

	float s = 0.0f;
	for (int x = 0; x<$I.x$; x++) {
		s += $I[x, y, z];
	}

	atomic_add_f(O + z, s/($I.x$*$I.y$));
}
]]

local function execute()
	proc:getAllBuffers("I", "O")
	proc.buffers.I.__write = false
	proc.buffers.O.__read = false

	local size = proc:size3D("I")
	size[1] = 1

	proc:executeKernel("set_zero", proc:size3D("O"), {"O"})
	proc:executeKernel("average", size)
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
