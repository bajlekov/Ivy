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
local proc = require "lib.opencl.process".new()

local ox = ffi.new("cl_int[1]", 0)
local oy = ffi.new("cl_int[1]", 0)

local function execute()
	proc:getAllBuffers("in", "t1", "t2", "t3", "t4", "p1", "p2", "p3", "out")


	proc:executeKernel("init", proc:size2D("out"), {"out", "t3", "t4"})

	local r = 5

	for x = 1, r do
		ox[0] = x
		local r = math.round(math.cos(math.abs(x) / r * math.pi / 2) * r)
		for y = -r, r do
			oy[0] = y
			proc:executeKernel("dist", proc:size2D("out"), {"in", "t1", ox, oy})
			proc:executeKernel("horizontal", proc:size2D("out"), {"t1", "t2"})
			proc:executeKernel("vertical", proc:size2D("out"), {"t2", "t1"})
			proc:executeKernel("accumulate", proc:size2D("out"), {"in", "t1", "t3", "t4", "p1", "p2", ox, oy})
		end
	end
	local x = 0
	ox[0] = x
	for y = -r, - 1 do
		oy[0] = y
		proc:executeKernel("dist", proc:size2D("out"), {"in", "t1", ox, oy})
		proc:executeKernel("horizontal", proc:size2D("out"), {"t1", "t2"})
		proc:executeKernel("vertical", proc:size2D("out"), {"t2", "t1"})
		proc:executeKernel("accumulate", proc:size2D("out"), {"in", "t1", "t3", "t4", "p1", "p2", ox, oy})
	end

	proc:executeKernel("norm", proc:size2D("out"), {"in", "t3", "t4", "p3", "out"})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceFile("nlmeans.cl")
	return execute
end

return init
