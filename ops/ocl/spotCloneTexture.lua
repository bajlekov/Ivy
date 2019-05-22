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

local source = [[
#include "range.cl"

kernel void take(global float *O, global float *S, global float *D, global float *M, global float *P, int idx, int ox, int oy) {
	const int x = get_global_id(0);
	const int y = get_global_id(1);
	const int z = get_global_id(2);

	int s = $P[0, idx, 4];		// spot size
	float f = $P[0, idx, 5];		// spot falloff

	int sx = floor($P[0, idx, 0]*$O.x$) - ox + x;	// source x
	int sy = floor($P[0, idx, 1]*$O.y$) - oy + y;	// source y
	int dx = floor($P[0, idx, 2]*$O.x$) - ox + x;	// destination x
	int dy = floor($P[0, idx, 3]*$O.y$) - oy + y;	// destination y

	$S[x, y, z] = $O[sx, sy, z];
	$D[x, y, z] = $O[dx, dy, z];

	float d = sqrt( (float)((x - ox)*(x - ox) + (y - oy)*(y - oy)) ); // distance from center
	float mask = range(d, s/(1 + f), f);

	$M[x, y, 0] = mask; // todo: separate 1ch process with reduced calculation outside of bounding box
}

kernel void place(global float *O, global float *S, global float *P, int idx, int ox, int oy) {
	const int x = get_global_id(0);
	const int y = get_global_id(1);
	const int z = get_global_id(2);

	int s = $P[0, idx, 4];		// spot size

	int dx = floor($P[0, idx, 2]*$O.x$) - ox + x;	// destination x
	int dy = floor($P[0, idx, 3]*$O.y$) - oy + y;	// destination y
	if (dx<0 || dx>=$O.x$ || dy<0 || dy>=$O.y$) return; // clamp to image

	$O[dx, dy, z] = $S[x, y, z];
}

#if $$ A and B and F and O and 1 or 0 $$
kernel void mixfactor(global float *A, global float *B, global float *F, global float *O) {
	const int x = get_global_id(0);
	const int y = get_global_id(1);
	const int z = get_global_id(2);

	float f = $F[x, y, z];
	f = clamp(f, 0.0f, 1.0f);

	$O[x, y, z] = $A[x, y, z]*f + $B[x, y, z]*(1.0f - f);
}
#endif
]]

local downsize = require "tools.downsize"
local idx = ffi.new("cl_int[1]", 0)
local ox = ffi.new("cl_int[1]", 0)
local oy = ffi.new("cl_int[1]", 0)

local function execute()
	proc:getAllBuffers("O", "P")
	proc.buffers.P.__write = false
	for i = 0, proc.buffers.P.y-1 do

		idx[0] = i
		local s = math.ceil(proc.buffers.P:get(0, i, 4)) -- brush size

		if s<=128 then
			ox[0] = 256
			oy[0] = 256
		elseif s<=384 then
			ox[0] = 512
			oy[0] = 512
		elseif s<=640 then
			ox[0] = 768
			oy[0] = 768
		elseif s<=896 then
			ox[0] = 1024
			oy[0] = 1024
		elseif s<=1152 then
			ox[0] = 1280
			oy[0] = 1280
		elseif s<=1408 then
			ox[0] = 1536
			oy[0] = 1536
		elseif s<=1664 then
			ox[0] = 1792
			oy[0] = 1792
		elseif s<=1920 then
			ox[0] = 2048
			oy[0] = 2048
		else
			error("Brush size not supported!")
		end
		local sz = proc.buffers.O.z

		local M = data:new(ox[0]*2, oy[0]*2, 1)	-- mask
		local S = data:new(ox[0]*2, oy[0]*2, sz)	-- source patch
		local D = data:new(ox[0]*2, oy[0]*2, sz) -- dest patch

		local O = proc.buffers.O
		proc.buffers.S = S
		proc.buffers.D = D
		proc.buffers.M = M
		proc:executeKernel("take", {ox[0]*2, oy[0]*2, sz}, {"O", "S", "D", "M", "P", idx, ox, oy})

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
		proc.buffers.I = S
		proc.buffers.L = SL[1]
		proc.buffers.G = G[1]
		proc:executeKernel("pyrDown", proc:size3D("G"), {"I", "G"})
		proc:executeKernel("pyrUpL", proc:size3D("G"), {"I", "L", "G"})
		for i = 2, 3 do
			proc.buffers.I = G[i-1]
			proc.buffers.L = SL[i]
			proc.buffers.G = G[i]
			proc:executeKernel("pyrDown", proc:size3D("G"), {"I", "G"})
			proc:executeKernel("pyrUpL", proc:size3D("G"), {"I", "L", "G"})
		end
		proc.buffers.I = G[3]
		proc.buffers.L = SL[4]
		proc.buffers.G = SG
		proc:executeKernel("pyrDown", proc:size3D("G"), {"I", "G"})
		proc:executeKernel("pyrUpL", proc:size3D("G"), {"I", "L", "G"})

		proc.buffers.I = D
		proc.buffers.L = DL[1]
		proc.buffers.G = G[1]
		proc:executeKernel("pyrDown", proc:size3D("G"), {"I", "G"})
		proc:executeKernel("pyrUpL", proc:size3D("G"), {"I", "L", "G"})
		for i = 2, 3 do
			proc.buffers.I = G[i-1]
			proc.buffers.L = DL[i]
			proc.buffers.G = G[i]
			proc:executeKernel("pyrDown", proc:size3D("G"), {"I", "G"})
			proc:executeKernel("pyrUpL", proc:size3D("G"), {"I", "L", "G"})
		end
		proc.buffers.I = G[3]
		proc.buffers.L = DL[4]
		proc.buffers.G = DG
		proc:executeKernel("pyrDown", proc:size3D("G"), {"I", "G"})
		proc:executeKernel("pyrUpL", proc:size3D("G"), {"I", "L", "G"})

		proc.buffers.I = M
		proc.buffers.G = MG[1]
		proc:executeKernel("pyrDown", proc:size3D("G"), {"I", "G"})
		for i = 2, 4 do
			proc.buffers.I = MG[i-1]
			proc.buffers.G = MG[i]
			proc:executeKernel("pyrDown", proc:size3D("G"), {"I", "G"})
		end

		proc.buffers.A = SL[1]
		proc.buffers.B = DL[1]
		proc.buffers.F = M
		proc.buffers.O = SL[1]
		proc:executeKernel("mixfactor", proc:size3D("O"), {"A", "B", "F", "O"})
		for i = 2, 4 do
			proc.buffers.A = SL[i]
			proc.buffers.B = DL[i]
			proc.buffers.F = MG[i-1]
			proc.buffers.O = SL[i]
			proc:executeKernel("mixfactor", proc:size3D("O"), {"A", "B", "F", "O"})
		end
		proc.buffers.A = SG
		proc.buffers.B = DG
		proc.buffers.F = MG[4]
		proc.buffers.O = SG
		proc:executeKernel("mixfactor", proc:size3D("O"), {"A", "B", "F", "O"})

		proc.buffers.L = SL[4]
		proc.buffers.G = DG
		proc.buffers.O = G[3]
		proc.buffers.f = data.one
		local x, y, z = proc.buffers.O:shape()
		x = math.ceil(x/2)
		y = math.ceil(y/2)
		proc:executeKernel("pyrUpG", {x, y, z}, {"L", "G", "O", "f"})
		for i = 3, 2, -1 do
			proc.buffers.L = SL[i]
			proc.buffers.G = G[i]
			proc.buffers.O = G[i - 1]
			proc.buffers.f = data.one
			local x, y, z = proc.buffers.O:shape()
			x = math.ceil(x/2)
			y = math.ceil(y/2)
			proc:executeKernel("pyrUpG", {x, y, z}, {"L", "G", "O", "f"})
		end
		proc.buffers.L = SL[1]
		proc.buffers.G = G[1]
		proc.buffers.O = S
		proc.buffers.f = data.one
		local x, y, z = proc.buffers.O:shape()
		x = math.ceil(x/2)
		y = math.ceil(y/2)
		proc:executeKernel("pyrUpG", {x, y, z}, {"L", "G", "O", "f"})

		-- return
		proc.buffers.O = O
		proc.buffers.S = S
		proc:executeKernel("place", {ox[0]*2, oy[0]*2, sz}, {"O", "S", "P", idx, ox, oy})
		proc.queue:finish()

		-- cleanup
		M:free()
		M = nil
		S:free()
		S = nil
		D:free()
		D = nil
		SG:free()
		SG = nil
		DG:free()
		DG = nil
		for i = 1, 4 do
			MG[i]:free()
			MG[i] = nil
			SL[i]:free()
			SL[i] = nil
			DL[i]:free()
			DL[i] = nil
			G[i]:free()
			G[i] = nil
		end
	end
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceFile("pyr.cl")
	proc:loadSourceString(source)
	return execute
end

return init
