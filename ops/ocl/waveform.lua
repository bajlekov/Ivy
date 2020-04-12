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

local proc = require "lib.opencl.process.ivy".new()

local source = [[
kernel clearWaveform(C)
  const x = get_global_id(0)
	const y = get_global_id(1)

  C[x, y, 0].int = 0
  C[x, y, 1].int = 0
  C[x, y, 2].int = 0
end

kernel waveform(I, C, L)
  const x = get_global_id(0)
  const y = get_global_id(1)

  var cx = clamp(int(x*C.x/I.x), 0, C.x-1)

	if L[0]>0.5 then
		var v = I[x, y].L
		var l = round(clamp(I[x, y].L, 0.0, 1.0)*(C.y-1))
		atomic_inc(C[cx, l, 0].intptr)
	else
		var v = I[x, y].SRGB
		var r = round(clamp(v.x, 0.0, 1.0)*(C.y-1))
		var g = round(clamp(v.y, 0.0, 1.0)*(C.y-1))
		var b = round(clamp(v.z, 0.0, 1.0)*(C.y-1))
		atomic_inc(C[cx, r, 0].intptr)
		atomic_inc(C[cx, g, 1].intptr)
		atomic_inc(C[cx, b, 2].intptr)
	end
end

kernel scaleWaveform(C, S, W, L, I)
  const x = get_global_id(0)
	const y = get_global_id(1)

	var s = S[0]
	s = s*4096/(I.x*I.y)

	if L[0]>0.5 then
		W[x, W.y-1-y] = RGBA(C[x, y, 0].int*s, 1.0)
	else
    W[x, W.y-1-y] = RGBA(vec(C[x, y, 0].int, C[x, y, 1].int, C[x, y, 2].int)*s, 1.0)
	end
end
]]

local function execute()
	local I, W, S, L = proc:getAllBuffers(4)

	local x = W.x
	local y = W.y

	-- allocate temporary count buffer
	local C = data:new(x, y, 4)
  W:allocDev()
  C:allocDev()

	proc:executeKernel("clearWaveform", proc:size2D(C), {C})
	proc:executeKernel("waveform", proc:size2D(I), {I, C, L})
	proc:executeKernel("scaleWaveform", proc:size2D(C), {C, S, W, L, I})

  C:free()

  W:devWritten()
  W:syncHost(true)
  W:freeDev()
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
