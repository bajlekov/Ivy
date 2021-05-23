--[[
  Copyright (C) 2011-2021 G. Bajlekov

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

local proc = require "lib.opencl.process.ivy".new()

local source = [[
kernel lightnessAdjust(P, S, R, C)
	const z = get_global_id(2)

	var p = -P[3]/1000.0
	var a = S[0]
	var b = z/255.0

	var w = R[0]
	var f = range(w, w, abs(a-b))

	var i = C[z]
	var o = 0.0
	if P[4]==1 then
		p = clamp(abs(p)*5.0, -1.0, 1.0)
		o = (1.0 - f*p)*i + f*p*0.5
	else
		o = i + f*p
	end

	C[z] = clamp(o, 0.0, 1.0)
end
]]

local function execute()
	local P, S, R, C = proc:getAllBuffers(4)
	proc:executeKernel("lightnessAdjust", {1, 1, 256}, {P, S, R, C})
	C:lock()
	C:devWritten():syncHost()
	C:unlock()
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
