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

local proc = require "lib.opencl.process".new()
local data = require "data"

local function downsize(x, y, z)
	if not y then
		x, y, z = x:shape()
	end
	x = math.ceil(x / 2)
	y = math.ceil(y / 2)
	return x, y, z
end

local function execute()
	proc:getAllBuffers("I", "O", "n")

	local n = proc.buffers.n:get(0, 0, 0)
	local G = {}
	G[0] = proc.buffers.I

	for i = 1, n do
		G[i] = data:new(downsize(G[i-1]:shape()))
		proc.buffers.I = G[i-1]
		proc.buffers.G = G[i]
		proc:executeKernel("pyrDown", proc:size3D("G"), {"I", "G"})
	end

	G[0] = proc.buffers.O
	for i = n, 1, -1 do
		proc.buffers.G = G[i]
		proc.buffers.O = G[i-1]
		proc:executeKernel("pyrUp", proc:size3D("G"), {"G", "O"})
		G[i]:free()
		G[i] = nil
	end
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceFile("pyr.cl")
	return execute
end

return init
