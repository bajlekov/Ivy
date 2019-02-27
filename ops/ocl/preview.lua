--[[
  Copyright (C) 2011-2018 G. Bajlekov

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
kernel void preview(global float *I, global uchar *P) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

	int xi = floor((float)x/$P.x$*$I.x$);
	int yi = floor((float)y/$P.y$*$I.y$);

	float3 v = $I[xi, yi]SRGB;

	uchar r = (uchar)(clamp(v.x, 0.0f, 1.0f)*255);
	uchar g = (uchar)(clamp(v.y, 0.0f, 1.0f)*255);
	uchar b = (uchar)(clamp(v.z, 0.0f, 1.0f)*255);

	const int idx = x*4 + ($P.y$-y-1)*$P.x$*4;
  P[idx + 0] = r;
  P[idx + 1] = g;
  P[idx + 2] = b;
  P[idx + 3] = 255;
}
]]

local previewBuffer
local previewX
local previewY

local function execute()
	proc:getAllBuffers("I", "P")

	local x = proc.buffers.P.x
	local y = proc.buffers.P.y

	if not (previewX == x and previewY == y) then
		previewBuffer = proc.context:create_buffer("write_only", x * y * 4 * ffi.sizeof("cl_uchar"))
		previewX = x
		previewY = y
	end

	proc.buffers.P.dataOCL = previewBuffer
	proc:executeKernel("preview", proc:size2D("P"))
	local event2 = proc.queue:enqueue_read_buffer(proc.buffers.P.dataOCL, true, proc.buffers.P.data)

	if proc.profile() then
		tools.profile("copy", event2, proc.queue)
	end
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
