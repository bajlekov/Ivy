--[[
  Copyright (C) 2011-2018 G. Bajlekov

    ImageFloat is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ImageFloat is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local ffi = require "ffi"
local proc = require "lib.opencl.process".new()
local data = require "data"

--local ox = ffi.new("cl_int[1]", 0)
--local oy = ffi.new("cl_int[1]", 0)

local function downsize(x, y, z)
	if not y then
		x, y, z = x:shape()
	end
	x = math.ceil(x / 2)
	y = math.ceil(y / 2)
	return x, y, z
end

local function execute()
	proc:getAllBuffers("I", "D", "S", "H", "R", "O") -- input, detail, shadow, highlight, range, output

	-- allocate buffers
	local T = {}
	local G = {}
	local L = {}

	local I = proc.buffers.I
	local O = proc.buffers.O
	local x, y, z = I:shape()

	T[1] = data:new(x, y, 1)
	L[1] = T[1]:new()
	for i = 2, 8 do
		T[i] = data:new(downsize(T[i-1]))
		L[i] = T[i]:new()
		G[i-1] = T[i]:new()
	end
	T[9] = data:new(downsize(T[8]))
	G[8] = T[9]:new()

	-- clear L output pyramid
	for i = 1, 8 do
		proc.buffers.L = L[i]
		proc:executeKernel("zero_LL", proc:size3D("L"), {"L"})
	end

	-- generate gaussian pyramid
	proc.buffers.I = I
	proc.buffers.G = G[1]
	proc:executeKernel("pyrDown", proc:size3D("G"), {"I", "G"})
	for i = 2, 8 do
		proc.buffers.I = G[i-1]
		proc.buffers.G = G[i]
		proc:executeKernel("pyrDown", proc:size3D("G"), {"I", "G"})
	end

	local lvl = 15
	local cl_m = ffi.new("cl_float[1]", 0) -- midpoint
	local cl_i = ffi.new("cl_int[1]", 0)
	local cl_lvl = ffi.new("cl_int[1]", lvl)
	-- loop over levels
	for i = 0, lvl do
		cl_m[0] = i/lvl
		cl_i[0] = i

		proc.buffers.I = I
		proc.buffers.O = O -- transformed
		proc:executeKernel("transform", proc:size2D("I"), {"I", "D", "S", "H", "R", "O", cl_m}) -- 1st channel

		-- generate transformed laplacian pyramid
		proc.buffers.I = O
		proc.buffers.G = T[2]
		proc.buffers.L = T[1]
		proc:executeKernel("pyrDown", proc:size3D("G"), {"I", "G"})
		proc:executeKernel("pyrUpL", proc:size3D("G"), {"I", "L", "G"})
		for i = 2, 8 do
			proc.buffers.I = T[i]
			proc.buffers.G = T[i+1]
			proc.buffers.L = T[i]
			proc:executeKernel("pyrDown", proc:size3D("G"), {"I", "G"})
			proc:executeKernel("pyrUpL", proc:size3D("G"), {"I", "L", "G"})
		end

		-- apply appropriate laplacians from T to L according to G
		proc.buffers.G = I
		proc.buffers.T = T[1]
		proc.buffers.O = L[1]
		proc:executeKernel("apply_LL", proc:size3D("T"), {"G", "T", "O", cl_i, cl_lvl})
		for i = 2, 8 do
			proc.buffers.G = G[i-1]
			proc.buffers.T = T[i]
			proc.buffers.O = L[i]
			proc:executeKernel("apply_LL", proc:size3D("T"), {"G", "T", "O", cl_i, cl_lvl})
		end

	end

	-- combine L + G pyramids
	proc.buffers.f = data.one
	for i = 8, 2, -1 do
		proc.buffers.L = L[i]
		proc.buffers.G = G[i]
		proc.buffers.O = G[i-1]
		proc:executeKernel("pyrUpG", proc:size3D("G"), {"L", "G", "O", "f"})
	end
	proc.buffers.L = L[1]
	proc.buffers.G = G[1]
	proc.buffers.O = O
	proc:executeKernel("pyrUpG", proc:size3D("G"), {"L", "G", "O", "f"})

	proc.buffers.L = nil
	proc.buffers.G = nil
	proc.buffers.T = nil
	proc.buffers.I = I
	proc.buffers.O = O

	proc:executeKernel("post_LL", proc:size2D("I"), {"I", "O"})

	for i = 1, 8 do
		T[i]:free()
		T[i] = nil
		L[i]:free()
		L[i] = nil
		G[i]:free()
		G[i] = nil
	end

end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceFile("localLaplacian.cl", "pyr.cl")
	return execute
end

return init
