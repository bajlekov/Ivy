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

local proc = require "lib.opencl.process.ivy".new()

local source = [[
function rd(ru, A, B, C, BR, CR, VR)
  ru = ru*(A*ru*ru*ru + B*ru*ru + C*ru + (1.0-A-B-C))
	return ru*(BR*ru*ru + CR*ru + VR)
end

function filterLinear(y0, y1, x)
  return y1*x + y0*(1.0-x)
end

function filterCubic(y0, y1, y2, y3, x)
  var a = 0.5*(-y0 + 3.0*y1 -3.0*y2 +y3)
  var b = y0 -2.5*y1 + 2.0*y2 - 0.5*y3
  var c = 0.5*(-y0 + y2)
  var d = y1

  return a*x^3 + b*x^2 + c*x + d
end

kernel cropCorrect(I, O, offset, flags)
  const x = get_global_id(0)
  const y = get_global_id(1)
  const z = get_global_id(2)

  var ox = round(offset[0])
  var oy = round(offset[1])
  var s = offset[2]

	var A = 0.0
	var B = 0.0
	var C = 0.0
	var gs = 1.0

	if flags[0]>0.5 then
  	A = offset[3]
  	B = offset[4]
  	C = offset[5]
		gs = offset[12]
	end

	var BR = 0.0
	var CR = 0.0
	var VR = 1.0
	if flags[1]>0.5 then
		if z==0 then
			BR = offset[6]
			CR = offset[7]
			VR = offset[8]
		end
		if z==2 then
			BR = offset[9]
			CR = offset[10]
			VR = offset[11]
		end
	end

  var x_2 = I.x*0.5
  var y_2 = I.y*0.5
  var fn_1 = min(x_2, y_2)
  var fn = 1.0/fn_1

  var cy = y*s+oy
  var cx = x*s+ox

  var cxn = (cx - x_2)*fn
  var cyn = (cy - y_2)*fn

  var r = sqrt(cxn^2 + cyn^2)

  var sd = rd(r, A, B, C, BR, CR, VR) / max(r, 0.000001)*gs
  cx = sd*cxn*fn_1 + x_2
  cy = sd*cyn*fn_1 + y_2

  -- bicubic filtering
  var xm = int(floor(cx))
  var xf = cx - xm
  var ym = int(floor(cy))
  var yf = cy - ym

	var v = array(4, 4)

  v[0, 0] = I[xm-1, ym-1, z]
  v[0, 1] = I[xm-1, ym  , z]
  v[0, 2] = I[xm-1, ym+1, z]
  v[0, 3] = I[xm-1, ym+2, z]
  v[1, 0] = I[xm  , ym-1, z]
  v[1, 1] = I[xm  , ym  , z]
  v[1, 2] = I[xm  , ym+1, z]
  v[1, 3] = I[xm  , ym+2, z]
  v[2, 0] = I[xm+1, ym-1, z]
  v[2, 1] = I[xm+1, ym  , z]
  v[2, 2] = I[xm+1, ym+1, z]
  v[2, 3] = I[xm+1, ym+2, z]
  v[3, 0] = I[xm+2, ym-1, z]
  v[3, 1] = I[xm+2, ym  , z]
  v[3, 2] = I[xm+2, ym+1, z]
  v[3, 3] = I[xm+2, ym+2, z]

  O[x, y, z] = filterCubic(
    filterCubic(v[0, 0], v[0, 1], v[0, 2], v[0, 3], yf),
    filterCubic(v[1, 0], v[1, 1], v[1, 2], v[1, 3], yf),
    filterCubic(v[2, 0], v[2, 1], v[2, 2], v[2, 3], yf),
    filterCubic(v[3, 0], v[3, 1], v[3, 2], v[3, 3], yf),
    xf)

	if xm<0 or ym<0 or xm>I.x-1 or ym>I.y-1 then
		O[x, y, z] = 0.0
	end
end
]]

local function execute()
	local I, O, offset, flags = proc:getAllBuffers(4)
	proc:executeKernel("cropCorrect", proc:size3D(O), {I, O, offset, flags})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
