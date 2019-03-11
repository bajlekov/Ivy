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
//#include "cs.cl"

kernel void clearPlot(global uint *C) {
  const int x = get_global_id(0);
	const int y = get_global_id(1);

  C[0*$C.sz$ + y*$C.sy$ + x*$C.sx$] = 0;
}

kernel void plot(global float *I, global uint *C, global float *clip) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float3 i;
	if (clip[0]>0.5f) {
		i = $I[x, y]LRGB;
		i = clamp(i, 0.0f, 1.0f);
		i = LRGBtoLAB(i);
	} else {
		i = $I[x, y]LAB;
	}

	if (fabs(i.y)<1.0f && fabs(i.z)<1.0f) {
		uint a = i.y * $C.x$ * 0.5f + 73.0f; // tuned offset to match display
		uint b = -i.z * $C.y$ * 0.5f + 71.0f; // tuned offset to match display
		atomic_inc(C + 0*$C.sz$ + b*$C.sy$ + a*$C.sx$);
	}
}

kernel void scalePlot(global uint *C, global float *S, global uchar *W, global float *I) {
	const int x = get_global_id(0);
	const int y = get_global_id(1);

	const int idx = x*4 + ($W.y$-y-1)*$W.x$*4;

	float s = S[0];
	float c = $C[x, y, 0];

	if (c>0.0f) {
		s = s * $$2048*5/(I.x*I.y)$$; // add I to arguments to force recompile on change
		float v = clamp(c*s, 0.0f, 255.0f);

		float a = (x - 73.0f) *2.0f / $C.x$;
		float b = -(y - 71.0f) *2.0f / $C.x$;

		float3 srgb = LABtoSRGB((float3)(1.0f-0.5f*sqrt(a*a + b*b), a, b));
		srgb = srgb * clamp(s * c, 0.0f, 1.0f);

		W[idx + 0] = (uchar)round(clamp(srgb.x*255.0f, 0.0f, 255.0f));
		W[idx + 1] = (uchar)round(clamp(srgb.y*255.0f, 0.0f, 255.0f));
		W[idx + 2] = (uchar)round(clamp(srgb.z*255.0f, 0.0f, 255.0f));
		W[idx + 3] = 255;
	} else {
		W[idx + 0] = 0;
		W[idx + 1] = 0;
		W[idx + 2] = 0;
		W[idx + 3] = 255;
	}
}

]]

local function execute()
	proc:getAllBuffers("I", "W", "S", "clip")

	local x = proc.buffers.W.x
	local y = proc.buffers.W.y

	-- allocate openCL buffer to image
	proc.buffers.W.dataOCL = proc.context:create_buffer("write_only", x * y * 4 * ffi.sizeof("cl_uchar"))

	-- allocate temporary count buffer
	proc.buffers.C = data:new(x, y, 1)

	proc:executeKernel("clearPlot", proc:size2D("C"), {"C"})
	proc:executeKernel("plot", proc:size2D("I"), {"I", "C", "clip"})
	proc:executeKernel("scalePlot", proc:size2D("C"), {"C", "S", "W", "I"})

	local event3 = proc.queue:enqueue_read_buffer(proc.buffers.W.dataOCL, true, proc.buffers.W.data)

	if proc.profile() then
		tools.profile("copyPlot", event3, proc.queue)
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
