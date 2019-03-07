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
kernel void clearWaveform(global uint *W) {
  const int x = get_global_id(0);
	const int y = get_global_id(1);

  W[0*$W.sz$ + y*$W.sy$ + x*$W.sx$] = 0;
  W[1*$W.sz$ + y*$W.sy$ + x*$W.sx$] = 0;
  W[2*$W.sz$ + y*$W.sy$ + x*$W.sx$] = 0;
  W[3*$W.sz$ + y*$W.sy$ + x*$W.sx$] = 0;
}

kernel void waveform(global float *I, global uint *W) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float3 v = $I[x, y]SRGB;

  uchar r = (uchar)round(clamp(v.x, 0.0f, 1.0f)*99.0f);
  uchar g = (uchar)round(clamp(v.y, 0.0f, 1.0f)*99.0f);
  uchar b = (uchar)round(clamp(v.z, 0.0f, 1.0f)*99.0f);
  uchar l = (uchar)round(clamp($I[x, y]L, 0.0f, 1.0f)*99.0f);

	uint xf = (x*149)/$I.x$;

	atomic_inc(W + 0*$W.sz$ + r*$W.sy$ + xf*$W.sx$);
	atomic_inc(W + 1*$W.sz$ + g*$W.sy$ + xf*$W.sx$);
	atomic_inc(W + 2*$W.sz$ + b*$W.sy$ + xf*$W.sx$);
  atomic_inc(W + 3*$W.sz$ + l*$W.sy$ + xf*$W.sx$);
}
]]

local previewBuffer
local previewX
local previewY

local function execute()
	proc:getAllBuffers("I", "W")

	proc:executeKernel("clearWaveform", {150, 100}, {"W"})
	proc:executeKernel("waveform", proc:size2D("I"))

	local event3 = proc.queue:enqueue_read_buffer(proc.buffers.W.dataOCL, true, proc.buffers.W.data)

	if proc.profile() then
		tools.profile("copyWaveform", event3, proc.queue)
	end
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
