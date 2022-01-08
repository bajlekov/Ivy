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

local source = [[
const hi = 1.0001
const lo = -0.0001

kernel clearHist(H)
  const x = get_global_id(0)
  const z = get_global_id(2)

  H[x, 0, z].int = 0
end

function clamp_chroma(i)
  var m = max(max(i.x, i.y), i.z)
  var Y = LRGBtoY(i)
  if Y<1.0 then
    var d = i-Y
    var f = (1.0-Y)/(m-Y)
    return Y + d*f
  else
    return 1.0
  end
end

function clamp_lightness(i)
  var m = max(max(i.x, i.y), i.z)
  return i/m
end

function clamp_color(i)
  var m = max(max(i.x, i.y), i.z)
  var Y = LRGBtoY(i)
  if Y<1.0 then
    for n = 1, 15 do
      i = min(i, 1.0)
      var Y_new = LRGBtoY(i)
      i = i * Y/Y_new
    end
  else
    i = 1.0
  end
  return i
end

function clamp_channels(i)
  return min(i, 1.0)
end

kernel display(I, O, G, C, D, H, seed)
  const x = get_global_id(0)
  const y = get_global_id(1)

  var i = I[x, y].LRGB

  -- clipping indicator
  var t1 = (x + y)*0.125
  t1 = t1 - floor(t1)
  var t2 = (x + O.y - y - 1)*0.125
  t2 = t2 - floor(t2)

	if G[0]>0.5 and (i.x>hi or i.y>hi or i.z>hi) then
    if t1 >= 0.25 then
      i = 0.0
    else
      i = 1.0
    end
	end

	if G[0]>0.5 and (i.x<lo or i.y<lo or i.z<lo) then
    if t2 >= 0.25 then
      i = 1.0
    else
      i = 0.0
    end
	end

  -- gamut projection
  var m = max(max(i.x, i.y), i.z)
  if G[0]<0.5 and m>1.0 then
    if C[0]==1.0 then
      i = clamp_chroma(i)
    elseif C[0]==2.0 then
      i = clamp_color(i)
    elseif C[0]==3.0 then
      i = clamp_channels(i)
    elseif C[0]==4.0 then
      i = clamp_lightness(i)
    else
      i = 1.0
    end
  end

  var a = clamp(int(LRGBtoL(i)*255), 0, 255)

  i = LRGBtoSRGB(i)

  -- dither
  if D[0]>0.5 then
    var rf = clamp(i.r*255.0, 0.0, 255.0)
    var gf = clamp(i.g*255.0, 0.0, 255.0)
    var bf = clamp(i.b*255.0, 0.0, 255.0)
    var ri = int(rf)
    var gi = int(gf)
    var bi = int(bf)
    if rf-ri>runif(seed, x, y) then
      ri = ri + 1
    end
    if gf-gi>runif(seed, x, y) then
      gi = gi + 1
    end
    if bf-bi>runif(seed, x, y) then
      bi = bi + 1
    end
    i = vec(ri, gi, bi)/255.0
  end

  O[x, O.y-y-1] = RGBA(i, 1.0)

  var r = clamp(int(i.r*255), 0, 255)
  var g = clamp(int(i.g*255), 0, 255)
  var b = clamp(int(i.b*255), 0, 255)

  var lh = local_int_array(256, 4)
  if int(get_local_size(0))==256 then
    const lx = int(get_local_id(0))

    lh[lx, 0] = 0
    lh[lx, 1] = 0
    lh[lx, 2] = 0
    lh[lx, 3] = 0
    barrier(CLK_LOCAL_MEM_FENCE)

    atomic_inc(lh[r, 0].ptr)
    atomic_inc(lh[g, 1].ptr)
    atomic_inc(lh[b, 2].ptr)
    atomic_inc(lh[a, 3].ptr)
    barrier(CLK_LOCAL_MEM_FENCE)

    atomic_add(H[lx, 0, 0].intptr, lh[lx, 0])
    atomic_add(H[lx, 0, 1].intptr, lh[lx, 1])
    atomic_add(H[lx, 0, 2].intptr, lh[lx, 2])
    atomic_add(H[lx, 0, 3].intptr, lh[lx, 3])

  else

    atomic_inc(H[r, 0, 0].intptr)
    atomic_inc(H[g, 0, 1].intptr)
    atomic_inc(H[b, 0, 2].intptr)
    atomic_inc(H[a, 0, 3].intptr)

  end
end
]]

local function execute()
	local I, O, G, C, D, H = proc:getAllBuffers(6)

  local seed = ffi.new("int[1]", math.random( -2147483648, 2147483647))
  proc:setWorkgroupSize({256, 1, 1})
  proc:executeKernel("clearHist", {256, 1, 4}, {H})
  proc:executeKernel("display", proc:size2D(O), {I, O, G, C, D, H, seed})

  O:lock()
  O:devWritten()
  O:syncHost(true)
  O:unlock()
  O:freeDev()

  H:lock()
  H:devWritten()
  H:syncHost(true)
  H:unlock()
  H:freeDev()
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
