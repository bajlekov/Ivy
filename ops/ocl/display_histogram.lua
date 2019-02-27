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
kernel void clearHist(global uint *p4) {
  const int x = get_global_id(0);

  p4[0*$p4.sz$ + x*$p4.sx$] = 0;
  p4[1*$p4.sz$ + x*$p4.sx$] = 0;
  p4[2*$p4.sz$ + x*$p4.sx$] = 0;
  p4[3*$p4.sz$ + x*$p4.sx$] = 0;
}

kernel void display(global float *p1, global uchar *p2, global float *p3, global uint *p4) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float3 v = $p1[x, y]SRGB;
	if ( p3[0]==1 && (v.x>1.0001f || v.y>1.0001f || v.z>1.0001f) ) {
		v = (float3)(0.0f);
	}
	if ( p3[0]==1 && (v.x<-0.0001f || v.y<-0.0001f || v.z<-0.0001f) ) {
		v = (float3)(1.0f);
	}

  uchar r = (uchar)round(clamp(v.x, 0.0f, 1.0f)*255.0f);
  uchar g = (uchar)round(clamp(v.y, 0.0f, 1.0f)*255.0f);
  uchar b = (uchar)round(clamp(v.z, 0.0f, 1.0f)*255.0f);

	const int idx = x*4 + ($p2.y$-y-1)*$p2.x$*4;
  p2[idx + 0] = r;
  p2[idx + 1] = g;
  p2[idx + 2] = b;
  p2[idx + 3] = 255;

  uchar l = (uchar)round(clamp($p1[x, y]L, 0.0f, 1.0f)*255.0f);

	atomic_inc(p4 + 0*$p4.sz$ + r*$p4.sx$);
	atomic_inc(p4 + 1*$p4.sz$ + g*$p4.sx$);
	atomic_inc(p4 + 2*$p4.sz$ + b*$p4.sx$);
  atomic_inc(p4 + 3*$p4.sz$ + l*$p4.sx$);
}
]]

local previewBuffer
local previewX
local previewY

local function execute()
	proc:getAllBuffers("p1", "p2", "p3", "p4")

	local x = proc.buffers.p2.x
	local y = proc.buffers.p2.y
	previewBuffer = proc.context:create_buffer("write_only", x * y * 4 * ffi.sizeof("cl_uchar"))
	proc.buffers.p2.dataOCL = previewBuffer

	proc.buffers.p1.__write = false
	proc.buffers.p3.__read = false
	proc.buffers.p4.__read = false
	proc:executeKernel("clearHist", {256}, {"p4"})
	proc:executeKernel("display", proc:size2D("p2"))

	proc.buffers.p2:toHost(true)
	proc.context.release_mem_object(proc.buffers.p2.dataOCL)
	proc.buffers.p2.dataOCL = nil
	proc.buffers.p4:toHost(true)
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
