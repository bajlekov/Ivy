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
local data = require "data"

local ox = ffi.new("cl_int[1]", 0)
local oy = ffi.new("cl_int[1]", 0)

local function execute()
	proc:getAllBuffers("in", "p1", "p2", "p3", "p4", "p5", "k", "out")

	local x, y, z = proc.buffers.out:shape()
	proc.buffers.t1 = data:new(x, y, 1)
	proc.buffers.t2 = data:new(x, y, 1)
	proc.buffers.t3 = data:new(x, y, z)
	proc.buffers.t4 = data:new(x, y, z)
	proc.buffers.wmax = data:new(x, y, z) -- keep largest weight for scaling

	proc:executeKernel("init", proc:size2D("out"), {"out", "t3", "t4", "wmax"})

	local r = proc.buffers.p4:get(0, 0, 0) -- adjustable range

	if proc.buffers.p4:get(0, 0, 1)<0.5 or proc.buffers.p4:get(0, 0, 0)<=8 then
		for x = 1, r do
			ox[0] = x
			-- circular clipping:
			--local r = math.round(math.cos(math.abs(x) / r * math.pi / 2) * r)
			for y = -r, r do
				oy[0] = y
				proc:executeKernel("dist", proc:size2D("out"), {"in", "t1", "p1", "p2", "p5", ox, oy})
				proc:executeKernel("horizontal", proc:size2D("out"), {"t1", "t2", "k"})
				proc:executeKernel("vertical", proc:size2D("out"), {"t2", "t1", "k"})
				proc:executeKernel("accumulate", proc:size2D("out"), {"in", "t1", "t3", "t4", "wmax", "p1", "p2", ox, oy})
			end
		end
		local x = 0
		ox[0] = x
		for y = -r, -1 do
			oy[0] = y
			proc:executeKernel("dist", proc:size2D("out"), {"in", "t1", "p1", "p2", "p5", ox, oy})
			proc:executeKernel("horizontal", proc:size2D("out"), {"t1", "t2", "k"})
			proc:executeKernel("vertical", proc:size2D("out"), {"t2", "t1", "k"})
			proc:executeKernel("accumulate", proc:size2D("out"), {"in", "t1", "t3", "t4", "wmax", "p1", "p2", ox, oy})
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
				proc:executeKernel("dist", proc:size2D("out"), {"in", "t1", "p1", "p2", "p5", ox, oy})
				proc:executeKernel("horizontal", proc:size2D("out"), {"t1", "t2", "k"})
				proc:executeKernel("vertical", proc:size2D("out"), {"t2", "t1", "k"})
				proc:executeKernel("accumulate", proc:size2D("out"), {"in", "t1", "t3", "t4", "wmax", "p1", "p2", ox, oy})
			end
		end
	end
	proc:executeKernel("norm", proc:size2D("out"), {"in", "t3", "t4", "wmax", "p3", "out"})

	proc.buffers.t1:free()
	proc.buffers.t2:free()
	proc.buffers.t3:free()
	proc.buffers.t4:free()
	proc.buffers.wmax:free()
	proc.buffers.t1 = nil
	proc.buffers.t2 = nil
	proc.buffers.t3 = nil
	proc.buffers.t4 = nil
	proc.buffers.wmax = nil
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceFile("nlmeans.cl")
	return execute
end

return init
