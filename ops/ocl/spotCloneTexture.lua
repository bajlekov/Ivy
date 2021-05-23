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

local ffi = require "ffi"
local proc = require "lib.opencl.process.ivy".new()
local data = require "data"

local source = [[
const pad = 32

kernel take(O, S, D, M, P, idx)
	const x = get_global_id(0)
	const y = get_global_id(1)

	var s = P[0, idx, 4] -- spot size
	var f = P[0, idx, 5] -- spot falloff
	var ct = P[0, idx, 6] -- spot rotation cos(t)
	var st = P[0, idx, 7] -- spot rotation sin(t)

	var xo = x - s - pad
	var yo = y - s - pad

	var xr = xo*ct - yo*st
	var yr = xo*st + yo*ct

	var sx = floor(P[0, idx, 0]) + xr -- source x
	var sy = floor(P[0, idx, 1]) + yr -- source y
	var dx = floor(P[0, idx, 2]) + xo -- destination x
	var dy = floor(P[0, idx, 3]) + yo -- destination y

	S[x, y] = lanczos(O, sx, sy)
	D[x, y] = O[dx, dy]

	var d = sqrt((xo)^2 + (yo)^2) -- distance from center
	M[x, y] = range(1.0-f*0.5, f*0.5, d/s)
end

kernel place(O, S, P, idx)
	const x = get_global_id(0)
	const y = get_global_id(1)

	var s = P[0, idx, 4] -- spot size

	var dx = floor(P[0, idx, 2]) - s - pad + x -- destination x
	var dy = floor(P[0, idx, 3]) - s - pad + y -- destination y
	O[dx, dy] = S[x, y]
end

kernel mixfactor(A, B, F, O)
	const x = get_global_id(0)
	const y = get_global_id(1)

	var f = F[x, y]
	var a = A[x, y]
	var b = B[x, y]

	O[x, y] = mix(b, a, clamp(f, 0.0, 1.0))
end
]]

local downsize = require "tools.downsize"
local idx = ffi.new("cl_int[1]", 0)

local function execute()
	local O, P = proc:getAllBuffers(2)

	for i = 0, P.y-1 do

		idx[0] = i
		local s = math.ceil(P:get(0, i, 4))*2 + 64 -- brush size + padding
		local sz = O.z

		local M = data:new(s, s, sz)  -- mask
		local S = data:new(s, s, sz) -- source patch
		local D = data:new(s, s, sz) -- dest patch

		proc:executeKernel("take", {s, s}, {O, S, D, M, P, idx})

		local MG = {} -- mask gaussian levels
		local SL = {} -- source laplacian levels
		local DL = {} -- dest laplacian levels
		local G = {} -- temporary gaussian levels for down-scaling and up-scaling

		MG[1] = data:new(downsize(M))
		SL[1] = data:new(S:shape())
		DL[1] = data:new(D:shape())
		G[1] = data:new(downsize(SL[1]))
		for i = 2, 4 do
			MG[i] = data:new(downsize(MG[i-1]))
			SL[i] = data:new(downsize(SL[i-1]))
			DL[i] = data:new(downsize(DL[i-1]))
			G[i] = data:new(downsize(G[i-1]))
		end
		local SG = data:new(downsize(SL[4]))
		local DG = data:new(downsize(DL[4]))

		-- perform mix6
		proc:executeKernel("pyrDown", proc:size2D(G[1]), {S, G[1]})
		proc:executeKernel("pyrUpL", proc:size2D(G[1]), {S, G[1], SL[1]})
		for i = 2, 3 do
			proc:executeKernel("pyrDown", proc:size2D(G[i]), {G[i-1], G[i]})
			proc:executeKernel("pyrUpL", proc:size2D(G[i]), {G[i-1], G[i], SL[i]})
		end
		proc:executeKernel("pyrDown", proc:size2D(SG), {G[3], SG})
		proc:executeKernel("pyrUpL", proc:size2D(SG), {G[3], SG, SL[4]})

		proc:executeKernel("pyrDown", proc:size2D(G[1]), {D, G[1]})
		proc:executeKernel("pyrUpL", proc:size2D(G[1]), {D, G[1], DL[1]})
		for i = 2, 3 do
			proc:executeKernel("pyrDown", proc:size2D(G[i]), {G[i-1], G[i]})
			proc:executeKernel("pyrUpL", proc:size2D(G[i]), {G[i-1], G[i], DL[i]})
		end
		proc:executeKernel("pyrDown", proc:size2D(DG), {G[3], DG})
		proc:executeKernel("pyrUpL", proc:size2D(DG), {G[3], DG, DL[4]})

		proc:executeKernel("pyrDown", proc:size2D(MG[1]), {M, MG[1]})
		for i = 2, 4 do
			proc:executeKernel("pyrDown", proc:size2D(MG[i]), {MG[i-1], MG[i]})
		end

		proc:executeKernel("mixfactor", proc:size2D(SL[1]), {SL[1], DL[1], M, SL[1]})
		for i = 2, 4 do
			proc:executeKernel("mixfactor", proc:size2D(SL[i]), {SL[i], DL[i], MG[i-1], SL[i]})
		end
		proc:executeKernel("mixfactor", proc:size2D(SG), {SG, DG, MG[4], SG})

		local x, y, z = G[3]:shape()
		x = math.ceil(x/2)
		y = math.ceil(y/2)
		proc:executeKernel("pyrUpG", {x, y}, {SL[4], DG, G[3], data.one})
		for i = 3, 2, -1 do
			local x, y, z = G[i-1]:shape()
			x = math.ceil(x/2)
			y = math.ceil(y/2)
			proc:executeKernel("pyrUpG", {x, y}, {SL[i], G[i], G[i-1], data.one})
		end
		local x, y, z = S:shape()
		x = math.ceil(x/2)
		y = math.ceil(y/2)
		proc:executeKernel("pyrUpG", {x, y}, {SL[1], G[1], S, data.one})

		-- return
		proc:executeKernel("place", {s, s}, {O, S, P, idx})

		-- cleanup
		M:free()
		S:free()
		D:free()
		SG:free()
		DG:free()
		for i = 1, 4 do
			MG[i]:free()
			SL[i]:free()
			DL[i]:free()
			G[i]:free()
		end
	end
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceFile("pyr_c_3d.ivy")
	proc:loadSourceFile("lanczos.ivy")
	proc:loadSourceString(source)
	return execute
end

return init
