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

local downsize = require "tools.downsize"

local function execute()
	local I, D, R, O, hq = proc:getAllBuffers(5) -- input, detail, range, output

	-- allocate buffers
	local T = {}
	local G = {}
	local L = {}

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
		proc:executeKernel("zero_LL", proc:size2D(L[i]), {L[i]})
	end

	-- generate gaussian pyramid
	proc:executeKernel("pyrDown", proc:size2D(G[1]), {I, G[1]})
	--proc:executeKernel("pyrUpL", proc:size2D(G[1]), {I, G[1], L[1]})
	for i = 2, 8 do
		proc:executeKernel("pyrDown", proc:size2D(G[i]), {G[i-1], G[i]})
		--proc:executeKernel("pyrUpL", proc:size2D(G[i]), {G[i-1], G[i], L[i]})
	end

	local lvl = hq:get(0, 0, 0)<0.5 and 15 or 127
	local cl_m = ffi.new("cl_float[1]", 0) -- midpoint
	local cl_i = ffi.new("cl_int[1]", 0) -- current lvl
	local cl_lvl = ffi.new("cl_int[1]", lvl) -- max lvl

	-- loop over levels
	for i = 0, lvl do
		cl_m[0] = i/lvl
		cl_i[0] = i

		proc:executeKernel("transform", proc:size2D(I), {I, D, R, O, cl_m})

		-- generate transformed laplacian pyramid
		proc:executeKernel("pyrDown", proc:size2D(T[2]), {O, T[2]})
		proc:executeKernel("pyrUpL", proc:size2D(T[2]), {O, T[2], T[1]})
		for i = 2, 8 do
			proc:executeKernel("pyrDown", proc:size2D(T[i+1]), {T[i], T[i+1]})
			proc:executeKernel("pyrUpL", proc:size2D(T[i+1]), {T[i], T[i+1], T[i]})
		end

		-- apply appropriate laplacians from T to L according to G
		proc:executeKernel("apply_LL", proc:size2D(T[1]), {I, T[1], L[1], cl_i, cl_lvl})
		for i = 2, 8 do
			proc:executeKernel("apply_LL", proc:size2D(T[i]), {G[i-1], T[i], L[i], cl_i, cl_lvl})
		end

	end

	-- combine L + G pyramids
	for i = 8, 2, -1 do
		proc:executeKernel("pyrUpG", proc:size2D(G[i]), {L[i], G[i], G[i-1], data.one})
	end
	proc:executeKernel("pyrUpG", proc:size2D(G[1]), {L[1], G[1], O, data.one})

	proc:executeKernel("post_LL", proc:size2D(I), {I, O})

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
	proc:loadSourceFile("localLaplacian.ivy", "pyr_c_2d.ivy")
	return execute
end

return init
