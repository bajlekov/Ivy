--[[
  Copyright (C) 2011-2020 G. Bajlekov

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
kernel preview(I, P)
  const x = get_global_id(0)
  const y = get_global_id(1)

	var xi = int(floor(float(x)/P.x*I.x))
	var yi = int(floor(float(y)/P.y*I.y))

	var v = I[xi, yi].SRGB

  P[x, P.y-y-1] = RGBA(v, 1.0)
end
]]

local function execute()
	local I, P = proc:getAllBuffers(2)
  P:allocDev()

	proc:executeKernel("preview", proc:size2D(P), {I, P})
  P:devWritten()
  P:syncHost(true)
  P:freeDev()
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
