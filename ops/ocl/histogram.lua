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

local proc = require "lib.opencl.process.ivy".new()

local source = [[
kernel clearHist(H)
  const x = get_global_id(0)
  const z = get_global_id(2)

  H[x, 0, z].int = 0
end

kernel histogram(I, H)
  const x = get_global_id(0)*8
  const y = get_global_id(1)*8

	var v = I[x, y].SRGB

  var r = clamp(int(v.r*255), 0, 255)
  var g = clamp(int(v.g*255), 0, 255)
  var b = clamp(int(v.b*255), 0, 255)
  var a = clamp(int(I[x, y].L*255), 0, 255)

  var lh = local_int_array(256, 4)
  if int(get_local_size(0))==256 then
    const lx = int(get_local_id(0))

    lh[lx, 0] = 0
    lh[lx, 1] = 0
    lh[lx, 2] = 0
    lh[lx, 3] = 0
    barrier(CLK_LOCAL_MEM_FENCE)

    atomic_inc(lh[r, 0].ptr)
    atomic_inc(lh[g, 1].ptr)
    atomic_inc(lh[b, 2].ptr)
    atomic_inc(lh[a, 3].ptr)
    barrier(CLK_LOCAL_MEM_FENCE)

    atomic_add(H[lx, 0, 0].intptr, lh[lx, 0])
    atomic_add(H[lx, 0, 1].intptr, lh[lx, 1])
    atomic_add(H[lx, 0, 2].intptr, lh[lx, 2])
    atomic_add(H[lx, 0, 3].intptr, lh[lx, 3])

  else

    atomic_inc(H[r, 0, 0].intptr)
    atomic_inc(H[g, 0, 1].intptr)
    atomic_inc(H[b, 0, 2].intptr)
    atomic_inc(H[a, 0, 3].intptr)

  end
end
]]

local previewBuffer
local previewX
local previewY

local function execute()
	local I, H = proc:getAllBuffers(2)

	local s = proc:size2D(I)
	local x, y = math.floor(s[1] / 8), math.floor(s[2] / 8)

	if x > 0 and y > 0 then
    H:allocDev()
		proc:executeKernel("clearHist", {256, 1, 4}, {H})
		proc:executeKernel("histogram", {x, y}, {I, H})
    H:devWritten()
    H:syncHost(true)
    H:freeDev()
	end
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
