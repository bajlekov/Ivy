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

-- domain transform filter
-- based on the recursive implementation of:

-- Domain Transform for Edge-Aware Image and Video Processing
-- Eduardo S. L. Gastal  and  Manuel M. Oliveira
-- ACM Transactions on Graphics. Volume 30 (2011), Number 4.
-- Proceedings of SIGGRAPH 2011, Article 69.

local ffi = require "ffi"
local proc = require "lib.opencl.process.ivy".new()
local data = require "data"

local source = [[
const eps = 0.0001

kernel derivative(J, dHdx, dVdy, S, R)
  const x = get_global_id(0)
  const y = get_global_id(1)

	var jo = J[x, y].LAB
	var jx = J[x+1, y].LAB
	var jy = J[x, y+1].LAB

	var s = S[x, y]
	var r = R[x, y]
	var sr = s/max(r, eps)

	var h3 = abs(jx-jo)
	var h = 1.0 + sr*(h3.x + h3.y + h3.z)

	var v3 = abs(jy-jo)
	var v = 1.0 + sr*(v3.x + v3.y + v3.z)

	dHdx[x+1, y] = h
	dVdy[x, y+1] = v
end

kernel horizontal(I, dHdx, O, S, h)
	const y = get_global_id(1)

	O[0, y] = I[0, y]
	for x = 1, O.x-1 do
		var io = I[x, y]
		var ix = O[x-1, y]
		var a = exp( -sqrt(2.0) / (S[x, y]*h) )
		var v = a ^ dHdx[x, y]
    O[x, y] = io + v * (ix - io)
	end

	for x = O.x - 2, 0, -1 do
		var io = O[x, y]
		var ix = O[x+1, y]
		var a = exp( -sqrt(2.0) / (S[x+1, y]*h) )
		var v = a ^ dHdx[x+1, y]
    O[x, y] = io + v * (ix - io)
	end
end

kernel vertical(I, dVdy, O, S, h)
	const x = get_global_id(0)

	O[x, 0] = I[x, 0]
	for y = 1, O.y-1 do
		var io = I[x, y]
		var iy = O[x, y-1]
		var a = exp( -sqrt(2.0) / (S[x, y]*h) )
		var v = a ^ dVdy[x, y]
    $O[x, y] = io + v * (iy - io)
	end

	for y = O.y - 2, 0, -1 do
		var io = O[x, y]
		var iy = O[x, y+1]
		var a = exp( -sqrt(2.0) / (S[x, y+1]*h) )
		var v = a ^ dVdy[x, y+1]
    O[x, y] = io + v * (iy - io)
	end
end

]]

local function execute()
	local I, J, S, R, O = proc:getAllBuffers(5)
  if J.x==1 and J.y==1 then J = I end -- use input as guide if guide is missing

	local x, y, z = O:shape()

	-- allocate and calculate dHdx, dVdy
	local dHdx = data:new(x, y, 1)
	local dVdy = data:new(x, y, 1)
	proc:executeKernel("derivative", proc:size2D(O), {J, dHdx, dVdy, S, R})

	local N = 5 -- number of iterations
	local h = ffi.new("float[1]")
	for i = 1, N do
		h[0] = math.sqrt(3) * 2^(N - i) / math.sqrt(4^N - 1)
		-- vertical pass optimizes the slower initial copy from I to O better (memory locality?)
		-- read from input buffer in first pass of first iteration
		-- in-place transform for all subsequent passes
    proc:setWorkgroupSize({16, 1, 1}) -- dynamically optimize these?
		proc:executeKernel("vertical", {x, 1}, {i==1 and I or O, dVdy, O, S, h})
    proc:setWorkgroupSize({1, 16, 1})
		proc:executeKernel("horizontal", {1, y}, {O, dHdx, O, S, h})
    proc:clearWorkgroupSize()
	end
	dHdx:free()
	dVdy:free()
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
