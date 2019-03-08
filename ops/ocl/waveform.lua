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
local data = require "data"

local proc = require "lib.opencl.process".new()

local source = [[
kernel void clearWaveform(global uint *C) {
  const int x = get_global_id(0);
	const int y = get_global_id(1);

  C[0*$C.sz$ + y*$C.sy$ + x*$C.sx$] = 0;
  C[1*$C.sz$ + y*$C.sy$ + x*$C.sx$] = 0;
  C[2*$C.sz$ + y*$C.sy$ + x*$C.sx$] = 0;
}

kernel void waveform(global float *I, global uint *C, global float *L) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

	uint xf = clamp((x*($C.x$-1))/$I.x$, 0, ($C.x$-1));

	if (L[0]>0.5f) {
		float v = $I[x, y]L;
		uchar l = (uchar)round(clamp(v, 0.0f, 1.0f)*($C.y$-1));
		atomic_inc(C + 0*$C.sz$ + l*$C.sy$ + xf*$C.sx$);
	} else {
		float3 v = $I[x, y]SRGB;
		uchar r = (uchar)round(clamp(v.x, 0.0f, 1.0f)*($C.y$-1));
		uchar g = (uchar)round(clamp(v.y, 0.0f, 1.0f)*($C.y$-1));
		uchar b = (uchar)round(clamp(v.z, 0.0f, 1.0f)*($C.y$-1));
		atomic_inc(C + 0*$C.sz$ + r*$C.sy$ + xf*$C.sx$);
		atomic_inc(C + 1*$C.sz$ + g*$C.sy$ + xf*$C.sx$);
		atomic_inc(C + 2*$C.sz$ + b*$C.sy$ + xf*$C.sx$);
	}
}

kernel void scaleWaveform(global uint *C, global float *S, global uchar *W, global float *L, global float *I) {
	const int x = get_global_id(0);
	const int y = get_global_id(1);

	const int idx = x*4 + ($W.y$-y-1)*$W.x$*4;

	float s = S[0];
	s = s * $$2048*256/(I.x*I.y)$$; // add I to arguments to force recompile on change

	if (L[0]>0.5f) {
		float v = clamp($C[x, y, 0]*s, 0.0f, 255.0f);
		W[idx + 0] = v;
		W[idx + 1] = v;
		W[idx + 2] = v;
	} else {
		W[idx + 0] = clamp($C[x, y, 0]*s, 0.0f, 255.0f);
		W[idx + 1] = clamp($C[x, y, 1]*s, 0.0f, 255.0f);
		W[idx + 2] = clamp($C[x, y, 2]*s, 0.0f, 255.0f);
	}
	W[idx + 3] = 255;
}

]]

local function execute()
	proc:getAllBuffers("I", "W", "S", "L")

	local x = proc.buffers.W.x
	local y = proc.buffers.W.y

	-- allocate openCL buffer to image
	proc.buffers.W.dataOCL = proc.context:create_buffer("write_only", x * y * 4 * ffi.sizeof("cl_uchar"))

	-- allocate temporary count buffer
	proc.buffers.C = data:new(x, y, 4)

	proc:executeKernel("clearWaveform", proc:size2D("C"), {"C"})
	proc:executeKernel("waveform", proc:size2D("I"), {"I", "C", "L"})
	proc:executeKernel("scaleWaveform", proc:size2D("C"), {"C", "S", "W", "L", "I"})

	local event3 = proc.queue:enqueue_read_buffer(proc.buffers.W.dataOCL, true, proc.buffers.W.data)

	if proc.profile() then
		tools.profile("copyWaveform", event3, proc.queue)
	end

	-- remove image openCL buffer
	proc.context.release_mem_object(proc.buffers.W.dataOCL)
	proc.buffers.W.dataOCL = nil

	-- free temporary count buffer
	proc.buffers.C:free()
	proc.buffers.C = nil
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
