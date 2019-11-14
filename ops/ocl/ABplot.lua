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
local data = require "data"

local proc = require "lib.opencl.process.ivy".new()

local source = [[
kernel clearPlot(C)
  const x = get_global_id(0)
	const y = get_global_id(1)

  C[x, y].int = 0
end

kernel plot(I, C, clip)
  const x = get_global_id(0)
  const y = get_global_id(1)

	var i = vec(0)
	if clip[0]>0.5 then
		i = I[x, y].LRGB
		i = clamp(i, 0.0, 1.0)
		i = LRGBtoLAB(i)
	else
		i = I[x, y].LAB
	end

	if abs(i.y)<1.0 and abs(i.z)<1.0 then
		var a = int( i.y*C.x*0.5 + 73) -- tuned offset to match display
		var b = int(-i.z*C.y*0.5 + 71) -- tuned offset to match display
		atomic_inc(C[a, b].intptr)
	end
end

kernel scalePlot(C, S, W, I)
	const x = get_global_id(0)
	const y = get_global_id(1)

	var s = S[0]
	var c = C[x, y].int

	if c>0.0 then
		s = s*2048*5/(I.x*I.y) -- add I to arguments to force recompile on change
		var v = clamp(c*s, 0.0, 255.0)

		var a = (x - 73.0)*2.0/C.x;
		var b = -(y - 71.0)*2.0/C.x;

		var srgb = LABtoSRGB(vec(1.0 - 0.5*sqrt(a^2 + b^2), a, b))
		srgb = srgb*clamp(s*c, 0.0, 1.0)

    W[x, y] = RGBA(srgb, 1.0)
	else
    W[x, y] = RGBA(vec(0.0), 1.0)
	end
end
]]

local function execute()
	local I, W, S, clip = proc:getAllBuffers(4)

	W.dataOCL = proc.context:create_buffer("write_only", W.x * W.y * ffi.sizeof("cl_float"))
  W.z = 1
  W.sx = 1
  W.sy = W.x
  W.sz = 1

	local C = data:new(W.x, W.y, 1)

	proc:executeKernel("clearPlot", proc:size2D(C), {C})
	proc:executeKernel("plot", proc:size2D(I), {I, C, clip})
	proc:executeKernel("scalePlot", proc:size2D(C), {C, S, W, I})

  W:freeDev(true)
  C:free()
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
