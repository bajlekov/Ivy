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
local proc = require "lib.opencl.process".new()
local data = require "data"

local source = [[
kernel void derivative(global float *J, global float *dHdx, global float *dVdy, global float *S, global float *R)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float3 jo = $J[x, y];
	float3 jx = $J[x+1, y];
	float3 jy = $J[x, y+1];

	float s = $S[x, y];
	float r = $R[x, y];
	float sr = s/fmax(r, 0.0001f);

	float3 h3 = fabs(jx-jo);
	float h = 1.0f + sr*(h3.x + h3.y + h3.z);

	float3 v3 = fabs(jy-jo);
	float v = 1.0f + sr*(v3.x + v3.y + v3.z);

	if (x+1<$dHdx.x$) $dHdx[x+1, y] = h;
	if (y+1<$dVdy.y$) $dVdy[x, y+1] = v;
}

kernel void horizontal(global float *I, global float *dHdx, global float *O, global float *S, float h) {
	//const int x = get_global_id(0);
	const int y = get_global_id(1);

	$O[0, y] = $I[0, y];
	for (int x = 1; x<$O.x$; x++) {
		float3 io = $I[x, y];
		float3 ix = $O[x-1, y];
		float a = exp( -sqrt(2.0f) / ($S[x, y]*h));
		float v = pow(a, $dHdx[x, y]);
		$O[x, y] = io + v * (ix - io);
	}

	for (int x = $O.x$-2; x>=0; x--) {
		float3 io = $O[x, y];
		float3 ix = $O[x+1, y];
		float a = exp( -sqrt(2.0f) / ($S[x+1, y]*h));
		float v = pow(a, $dHdx[x+1, y]);
		$O[x, y] = io + v * (ix - io);
	}
}

kernel void vertical(global float *I, global float *dVdy, global float *O, global float *S, float h) {
	const int x = get_global_id(0);
	//const int y = get_global_id(1);

	$O[x, 0] = $I[x, 0];
	for (int y = 1; y<$O.y$; y++) {
		float3 io = $I[x, y];
		float3 iy = $O[x, y-1];
		float a = exp( -sqrt(2.0f) / ($S[x, y]*h));
		float v = pow(a, $dVdy[x, y]);
		$O[x, y] = io + v * (iy - io);
	}

	for (int y = $O.y$-2; y>=0; y--) {
		float3 io = $O[x, y];
		float3 iy = $O[x, y+1];
		float a = exp( -sqrt(2.0f) / ($S[x, y+1]*h));
		float v = pow(a, $dVdy[x, y+1]);
		$O[x, y] = io + v * (iy - io);
	}
}

]]

local function execute()
	proc:getAllBuffers("I", "J", "S", "R", "O")

	local x, y, z = proc.buffers.O:shape()

	-- allocate and calculate dHdx, dVdy
	proc.buffers.dHdx = data:new(x, y, 1)
	proc.buffers.dVdy = data:new(x, y, 1)
	proc:executeKernel("derivative", proc:size2D("O"), {"J", "dHdx", "dVdy", "S", "R"})

	local N = 5 -- number of iterations
	local h = ffi.new("float[1]")
	local I = proc.buffers.I
	local O = proc.buffers.O
	for i = 0, N-1 do
		h[0] = math.sqrt(3) * 2^(N - (i+1)) / math.sqrt(4^N - 1)
		-- vertical pass optimizes the slower initial copy from I to O better (memory locality?)
		-- read from input buffer in first pass of first iteration
		-- in-place transform for all subsequent passes
		proc.buffers.I = i==0 and I or O
		proc:executeKernel("vertical", {x, 1}, {"I", "dVdy", "O", "S", h})
    proc.buffers.I = O
		proc:executeKernel("horizontal", {1, y}, {"I", "dHdx", "O", "S", h})
	end
	proc.buffers.I = I
	proc.buffers.dHdx:free()
	proc.buffers.dVdy:free()
	proc.buffers.dHdx = nil
	proc.buffers.dVdy = nil
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
