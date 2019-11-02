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
local proc = require "lib.opencl.process.ivy".new()
local data = require "data"

local ox = ffi.new("cl_int[1]", 0)
local oy = ffi.new("cl_int[1]", 0)

local function execute()
	local I, p1, p2, p3, p4, p5, K, O = proc:getAllBuffers(8)

	local x, y, z = O:shape()
	local T1 = data:new(x, y, 1)
	local T2 = data:new(x, y, 1)
	local T3 = data:new(x, y, z)
	local T4 = data:new(x, y, z)
	local W = data:new(x, y, z) -- keep largest weight for scaling

	proc:executeKernel("init", proc:size2D(O), {T3, T4, W})

	local r = p4:get(0, 0, 0) -- adjustable range

	if p4:get(0, 0, 1)<0.5 or p4:get(0, 0, 0)<=8 then
		for x = 1, r do
			ox[0] = x
			-- circular clipping:
			--local r = math.round(math.cos(math.abs(x) / r * math.pi / 2) * r)
			for y = -r, r do
				oy[0] = y
				proc:executeKernel("dist", proc:size2D(O), {I, T1, p1, p2, p5, ox, oy})
				proc:executeKernel("horizontal", proc:size2D(O), {T1, T2, K})
				proc:executeKernel("vertical", proc:size2D(O), {T2, T1, K})
				proc:executeKernel("accumulate", proc:size2D(O), {I, T1, T3, T4, W, p1, p2, ox, oy})
			end
		end
		local x = 0
		ox[0] = x
		for y = -r, -1 do
			oy[0] = y
			proc:executeKernel("dist", proc:size2D(O), {I, T1, p1, p2, p5, ox, oy})
			proc:executeKernel("horizontal", proc:size2D(O), {T1, T2, K})
			proc:executeKernel("vertical", proc:size2D(O), {T2, T1, K})
			proc:executeKernel("accumulate", proc:size2D(O), {I, T1, T3, T4, W, p1, p2, ox, oy})
		end
	else
		math.haltonSeed()
		for i = 1, 100 do
			-- use halton sequence
			local rx, ry = math.halton2()
			ox[0] = rx*r
			oy[0] = ry*r*2-r
			--ox[0] = math.random(0, r)
			--oy[0] = math.random(-r, r)
			if not (ox[0]==0 and oy[0]==0) then
				proc:executeKernel("dist", proc:size2D(O), {I, T1, p1, p2, p5, ox, oy})
				proc:executeKernel("horizontal", proc:size2D(O), {T1, T2, K})
				proc:executeKernel("vertical", proc:size2D(O), {T2, T1, K})
				proc:executeKernel("accumulate", proc:size2D(O), {I, T1, T3, T4, W, p1, p2, ox, oy})
			end
		end
	end
	proc:executeKernel("norm", proc:size2D(O), {I, T3, T4, W, O, p3})

	T1:free()
	T2:free()
	T3:free()
	T4:free()
	W:free()
	T1 = nil
	T2 = nil
	T3 = nil
	T4 = nil
	W = nil
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceFile("nlmeans.ivy")
	return execute
end

return init
