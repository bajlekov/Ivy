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

kernel horizontal(dHdx, O, S, h)
	const y = get_global_id(1)

	for x = 1, O.x-1 do
		var io = O[x, y]
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

kernel vertical(dVdy, O, S, h)
	const x = get_global_id(0)

	for y = 1, O.y-1 do
		var io = O[x, y]
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

const SQRT3 = 1.73205081
const SQRT12 = 3.46410162

kernel convert(I, M, W, P, flags, C)
	const x = get_global_id(0)
	const y = get_global_id(1)

	var i = I[x, y]

	var clip = i.x>0.98 or i.y>0.98 or i.z>0.98

	if flags[3]>0.5 then
		i = i * P[0, 0]
  end

  if flags[4]>0.5 then
		i = i * W[0, 0]
  end

  var i_r = vec(0.0)
  if flags[5]>0.5 then
  -- adapted from DarkTable's process_lch_bayer (GNU General Public License v3.0)

    var r = i.x
    var g = i.y
    var b = i.z

    var ro = min(r, 1.0)
    var go = min(g, 1.0)
    var bo = min(b, 1.0)

    var l = (r + g + b) / 3.0
    var c = SQRT3 * (r-g)
    var h = 2*b - g - r

    var co = SQRT3 * (ro - go)
    var ho = 2*bo - go - ro

    if r~=g and g~=b then
      var r = sqrt((co^2 + ho^2) / (c^2 + h^2))
      c = c * r
      h = h * r
    end

    i_r.x = l - h / 6.0 + c / SQRT12
    i_r.y = l - h / 6.0 - c / SQRT12
    i_r.z = l + h / 3.0
  end

	if flags[3]>0.5 then
		var o = vec(0.0)
		o.x = i.x*M[0, 0, 0] + i.y*M[0, 1, 0] + i.z*M[0, 2, 0]
		o.y = i.x*M[1, 0, 0] + i.y*M[1, 1, 0] + i.z*M[1, 2, 0]
		o.z = i.x*M[2, 0, 0] + i.y*M[2, 1, 0] + i.z*M[2, 2, 0]

    if clip then
      -- desaturate clipped values
			o = YtoLRGB(LRGBtoY(o))
    end

    if flags[5]>0.5 then
      -- replace luminance with reconstructed value
      var o_r = vec(0.0)
      o_r.x = i_r.x*M[0, 0, 0] + i_r.y*M[0, 1, 0] + i_r.z*M[0, 2, 0]
      o_r.y = i_r.x*M[1, 0, 0] + i_r.y*M[1, 1, 0] + i_r.z*M[1, 2, 0]
      o_r.z = i_r.x*M[2, 0, 0] + i_r.y*M[2, 1, 0] + i_r.z*M[2, 2, 0]

      var y = LRGBtoXYZ(o)
      var yr = LRGBtoY(o_r)

      o = XYZtoLRGB(y * yr/y.y)
    end

		I[x, y] = o
	else
		I[x, y] = i
	end

  if clip then
    C[x, y] = 1.0
  else
    C[x, y] = 0.0
  end
end

kernel expand(I, C, J, O)
	const x = get_global_id(0)
	const y = get_global_id(1)

	var e = false
	var f = false
	var c = C[x, y] > 0.5

	for i = -2, 2 do
		for j = -2, 2 do
			if C[x+i, y+j]>0.5 then
        f = true
      end
    end
  end

	for i = -4, 4 do
		for j = -4, 4 do
			if C[x+i, y+j]>0.5 then
        e = true
      end
    end
  end

	var i = I[x, y]
	var l = max(max(i.x, i.y), i.z) > 0.75

  if e then
    --J[x, y] = i -- detailed guide
    J[x, y] = 1.0 -- smooth guide
  else
    J[x, y] = 0.0
  end

  if e and not f and l then
    O[x, y] = i
  else
    O[x, y] = vec(0.0)
  end
end

kernel merge(I, C, O)
	const x = get_global_id(0)
	const y = get_global_id(1)

	var c = C[x, y]>0.5

	if c then
		var i = I[x, y]
		var o = O[x, y]

		i = LRGBtoXYZ(i)
		o = LRGBtoXYZ(o)
		o = o * i.y/o.y

		I[x, y] = XYZtoLRGB(o)
	end
end

]]


local function execute()
	local I, M, W, P, flags = proc:getAllBuffers(5)

	local x, y, z = I:shape()
	local C = data:new(x, y, 1) -- clipping mask
	local J = data:new(x, y, z) -- guide

	local S = data:new(1, 1, 1) -- DT filter param
	local R = data:new(1, 1, 1) -- DT filter param
	S:set(0, 0, 0, 50):hostWritten():syncDev()
	R:set(0, 0, 0, 0.5):hostWritten():syncDev()

	local dHdx = data:new(x, y, 1)
	local dVdy = data:new(x, y, 1)
	local O = data:new(x, y, z) -- reference in, reconstructed colors out

	proc:executeKernel("convert", proc:size2D(I), {I, M, W, P, flags, C})

	if flags:get(0, 0, 6) > 0.5 then -- reconstruct color
		proc:executeKernel("expand", proc:size2D(I), {I, C, J, O})

		-- DT dx, dy generate dHdx, dVdy from G
		proc:executeKernel("derivative", proc:size2D(I), {J, dHdx, dVdy, S, R})

		-- DT iterate V, H over R with G as guide
		local N = 5 -- number of iterations
		local h = ffi.new("float[1]")
		for i = 0, N-1 do
			h[0] = math.sqrt(3) * 2^(N - (i+1)) / math.sqrt(4^N - 1)
			proc:executeKernel("vertical", {x, 1}, {dVdy, O, S, h})
			proc:executeKernel("horizontal", {1, y}, {dHdx, O, S, h})
		end

		-- merge colors from R in I according to C
		proc:executeKernel("merge", proc:size2D(I), {I, C, O})
	end

  C:free()
  J:free()
  S:free()
  R:free()
  dHdx:free()
  dVdy:free()
  O:free()
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
