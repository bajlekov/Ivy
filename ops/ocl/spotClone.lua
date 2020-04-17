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

local proc = require "lib.opencl.process.ivy".new()

local source = [[
kernel spotClone(I, O, P, idx)
	const x = get_global_id(0)
	const y = get_global_id(1)
	const z = get_global_id(2)

	var s = P[0, idx, 4] -- spot size
	var f = P[0, idx, 5] -- spot falloff

	var sx = floor(P[0, idx, 0]) - s + x -- source x
	var sy = floor(P[0, idx, 1]) - s + y -- source y
	var dx = floor(P[0, idx, 2]) - s + x -- destination x
	var dy = floor(P[0, idx, 3]) - s + y -- destination y

	if dx<0 or dx>=O.x or dy<0 or dy>=O.y then
		return
	end

	var d = sqrt((x-s)^2 + (y-s)^2) -- distance from center
	var mask = range(1.0-f*0.5, f*0.5, d/s)

	var o = O[dx, dy, z]
	var i = I[sx, sy, z]

	O[dx, dy, z] = mix(o, i, mask)
end
]]

local ffi = require "ffi"
local idx = ffi.new("cl_int[1]", 0)

local function execute()
	local I, O, P = proc:getAllBuffers(3)
	for i = 0, P.y-1 do
		idx[0] = i
		local ps = math.ceil(P:get(0, i, 4)) -- brush size
		proc:executeKernel("spotClone", {ps*2+1, ps*2+1, O.z}, {I, O, P, idx})
		proc.queue:finish()
	end
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
