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
kernel void clearHist(global uint *H) {
  const int x = get_global_id(0);

  H[0*$H.sz$ + x*$H.sx$] = 0;
  H[1*$H.sz$ + x*$H.sx$] = 0;
  H[2*$H.sz$ + x*$H.sx$] = 0;
  H[3*$H.sz$ + x*$H.sx$] = 0;
}

kernel void histogram(global float *I, global uint *H) {
  const int x = get_global_id(0)*8;
  const int y = get_global_id(1)*8;

	float3 v = $I[x, y]SRGB;

  uchar r = (uchar)round(clamp(v.x, 0.0f, 1.0f)*255.0f);
  uchar g = (uchar)round(clamp(v.y, 0.0f, 1.0f)*255.0f);
  uchar b = (uchar)round(clamp(v.z, 0.0f, 1.0f)*255.0f);
  uchar l = (uchar)round(clamp($I[x, y]L, 0.0f, 1.0f)*255.0f);

	atomic_inc(H + 0*$H.sz$ + r*$H.sx$);
	atomic_inc(H + 1*$H.sz$ + g*$H.sx$);
	atomic_inc(H + 2*$H.sz$ + b*$H.sx$);
  atomic_inc(H + 3*$H.sz$ + l*$H.sx$);
}
]]

local previewBuffer
local previewX
local previewY

local function execute()
	proc:getAllBuffers("I", "H")

	local s = proc:size2D("I")
	local x, y = math.floor(s[1] / 8), math.floor(s[2] / 8)

	if x > 0 and y > 0 then
		proc:executeKernel("clearHist", {256}, {"H"})
		proc:executeKernel("histogram", {x, y})

		local event3 = proc.queue:enqueue_read_buffer(proc.buffers.H.dataOCL, true, proc.buffers.H.data)

		if proc.profile() then
			tools.profile("copyHist", event3, proc.queue)
		end
	end
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
