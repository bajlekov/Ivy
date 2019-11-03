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
#include "cs.cl"

// domain transform copy
kernel void derivative(global float *J, global float *dHdx, global float *dVdy, global float *S, global float *R)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float3 jo = $J[x, y];
	float3 jx = $J[x+1, y];
	float3 jy = $J[x, y+1];

	float s = S[0];
	float r = R[0];
	float sr = s/fmax(r, 0.0001f);

	float3 h3 = fabs(jx-jo);
	float h = 1.0f + sr*(h3.x + h3.y + h3.z);

	float3 v3 = fabs(jy-jo);
	float v = 1.0f + sr*(v3.x + v3.y + v3.z);

	if (x+1<$dHdx.x$) $dHdx[x+1, y] = h;
	if (y+1<$dVdy.y$) $dVdy[x, y+1] = v;
}

kernel void horizontal(global float *dHdx, global float *O, global float *S, float h) {
	//const int x = get_global_id(0);
	const int y = get_global_id(1);

	for (int x = 1; x<$O.x$; x++) {
		float3 io = $O[x, y];
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

kernel void vertical(global float *dVdy, global float *O, global float *S, float h) {
	const int x = get_global_id(0);
	//const int y = get_global_id(1);

	for (int y = 1; y<$O.y$; y++) {
		float3 io = $O[x, y];
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


#define SQRT3 1.73205081
#define SQRT12 3.46410162

kernel void convert(
	global float *I,
	global float *M,
	global float *W,
	global float *P,
	global float *flags,
	global float *C
) {
	const int x = get_global_id(0);
	const int y = get_global_id(1);

	float3 i = $I[x, y];

	bool clip = i.x>0.95f || i.y>0.95f || i.z>0.95f;

	if (flags[3]>0.5f)
		i = i * $P[0, 0];

  if (flags[4]>0.5f)
		i = i * $W[0, 0];

  float3 ir;
  if (flags[5]>0.5f) {
    // adapted from DarkTable's process_lch_bayer (GNU General Public License v3.0)

    float r = i.x;
    float g = i.y;
    float b = i.z;

    float ro = min(r, 1.0f);
    float go = min(g, 1.0f);
    float bo = min(b, 1.0f);

    float l = (r + g + b) / 3.0f;
    float c = SQRT3 * (r-g);
    float h = 2.0f * b - g - r;

    float co = SQRT3 * (ro - go);
    float ho = 2.0f * bo - go - ro;

    if (r != g && g != b) {
      float r = sqrt((co*co + ho*ho) / (c*c + h*h));
      c = c * r;
      h = h * r;
    }

    ir.x = l - h / 6.0f + c / SQRT12;
    ir.y = l - h / 6.0f - c / SQRT12;
    ir.z = l + h / 3.0f;
  }

	if (flags[3]>0.5f) {
		float3 o;
		o.x = i.x*$M[0, 0, 0] + i.y*$M[0, 1, 0] + i.z*$M[0, 2, 0];
		o.y = i.x*$M[1, 0, 0] + i.y*$M[1, 1, 0] + i.z*$M[1, 2, 0];
		o.z = i.x*$M[2, 0, 0] + i.y*$M[2, 1, 0] + i.z*$M[2, 2, 0];

    if (clip) {
      // desaturate clipped values
			o = YtoLRGB(LRGBtoY(o));
    }

    if (flags[5]>0.5f) {
      // replace luminance with reconstructed value
      float3 or;
      or.x = ir.x*$M[0, 0, 0] + ir.y*$M[0, 1, 0] + ir.z*$M[0, 2, 0];
      or.y = ir.x*$M[1, 0, 0] + ir.y*$M[1, 1, 0] + ir.z*$M[1, 2, 0];
      or.z = ir.x*$M[2, 0, 0] + ir.y*$M[2, 1, 0] + ir.z*$M[2, 2, 0];

      float3 y = LRGBtoXYZ(o);
      float yr = LRGBtoY(or);

      o = XYZtoLRGB(y * yr/y.y);
    }

		$I[x, y] = o;
	} else {
		$I[x, y] = i;
	}

  $C[x, y] = clip ? 1.0f : 0.0f;
}

kernel void expand(global float *I, global float *C, global float *J, global float *O) {
	const int x = get_global_id(0);
	const int y = get_global_id(1);

	bool e = false;
	bool f = false;
	bool c = $C[x, y] > 0.5f;

	for (int i = -2; i<=2; i++)
		for (int j = -2; j<=2; j++)
			if ($C[x+i, y+j]>0.5f) f = true;

	for (int i = -4; i<=4; i++)
		for (int j = -4; j<=4; j++)
			if ($C[x+i, y+j]>0.5f) e = true;

	float3 i = $I[x, y];
	bool l = max(max(i.x, i.y), i.z) > 0.75f;

	$J[x, y] = e ? i : (float3)(0.0f);
	$O[x, y] = (e && !f && l) ? i : (float3)(0.0f);
}

kernel void merge(global float *I, global float *C, global float *O) {
	const int x = get_global_id(0);
	const int y = get_global_id(1);

	bool c = $C[x, y]>0.5f;

	if (c) {
		float3 i = $I[x, y];
		float3 o = $O[x, y];

		i = LRGBtoXYZ(i);
		o = LRGBtoXYZ(o);
		o = o * i.y/o.y;

		$I[x, y] = XYZtoLRGB(o);
	}
}

]]

local function execute()
	proc:getAllBuffers("I", "M", "W", "P", "flags")

	local x, y, z = proc.buffers.I:shape()
	proc.buffers.C = data:new(x, y, 1) -- clipping mask
	proc.buffers.J = data:new(x, y, z) -- guide

	proc.buffers.S = data:new(1, 1, 1) -- DT filter param
	proc.buffers.R = data:new(1, 1, 1) -- DT filter param
	proc.buffers.S:set(0, 0, 0, 50)
	proc.buffers.R:set(0, 0, 0, 0.5)
	proc.buffers.S:toDevice()
	proc.buffers.R:toDevice()

	proc.buffers.dHdx = data:new(x, y, 1)
	proc.buffers.dVdy = data:new(x, y, 1)
	proc.buffers.O = data:new(x, y, z) -- reference in, reconstructed colors out

	proc:executeKernel("convert", proc:size2D("I"), {"I", "M", "W", "P", "flags", "C"})

	if proc.buffers.flags:get(0, 0, 6) > 0.5 then -- reconstruct color
		proc:executeKernel("expand", proc:size2D("I"), {"I", "C", "J", "O"})

		-- DT dx, dy generate dHdx, dVdy from G
		proc:executeKernel("derivative", proc:size2D("I"), {"J", "dHdx", "dVdy", "S", "R"})

		-- DT iterate V, H over R with G as guide
		local N = 5 -- number of iterations
		local h = ffi.new("float[1]")
		for i = 0, N-1 do
			h[0] = math.sqrt(3) * 2^(N - (i+1)) / math.sqrt(4^N - 1)
			proc:executeKernel("vertical", {x, 1}, {"dVdy", "O", "S", h})
			proc:executeKernel("horizontal", {1, y}, {"dHdx", "O", "S", h})
		end

		-- merge colors from R in I according to C
		proc:executeKernel("merge", proc:size2D("I"), {"I", "C", "O"})
	end

  proc.buffers.C:free()
  proc.buffers.J:free()
  proc.buffers.S:free()
  proc.buffers.R:free()
  proc.buffers.dHdx:free()
  proc.buffers.dVdy:free()
  proc.buffers.O:free()
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
