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
inline void atomic_max_f(volatile global float *addr, float val) {
	union {
		unsigned int u32;
		float        f32;
	} next, expected, current;

	current.f32 = *addr;
	next.f32 = val;

	do {
		if (current.f32 >= val) return;
		expected.f32 = current.f32;
		current.u32  = atomic_cmpxchg( (volatile __global unsigned int *)addr, expected.u32, next.u32);
	} while( current.u32 != expected.u32 );
}

kernel void set_low(global float *O) {
	const int z = get_global_id(2);
	O[z] = -INFINITY;
}

kernel void maximum(global float *I, global float *O) {
	const int x = get_global_id(0);
	const int y = get_global_id(1);
	const int z = get_global_id(2);

	atomic_max_f(O + z, $I[x, y, z]);
}
]]

local function execute()
	proc:getAllBuffers("I", "O")
	proc.buffers.I.__write = false
	proc.buffers.O.__read = false
	proc:executeKernel("set_low", proc:size3D("O"), {"O"})
	proc:executeKernel("maximum", proc:size3D("I"))
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
