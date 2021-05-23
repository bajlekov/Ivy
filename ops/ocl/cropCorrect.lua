--[[
  Copyright (C) 2011-2020 G. Bajlekov

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
function rd_calc(ru, A, B, C, BR, CR, VR)
  ru = ru*(A*ru*ru*ru + B*ru*ru + C*ru + (1.0-A-B-C))
	return ru*(BR*ru*ru + CR*ru + VR)
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
		gs = offset[15]
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

  var rd = rd_calc(r, A, B, C, BR, CR, VR)*gs
  var sd = rd / max(r, 0.000001)
  cx = sd*cxn*fn_1 + x_2
  cy = sd*cyn*fn_1 + y_2

  if flags[2]>0.5 then
    var o = lanczos_z(I, cx, cy, z)
    var K1 = offset[12]
    var K2 = offset[13]
    var K3 = offset[14]
    rd = rd/2
    o = o / (1 + K1*rd^2 + K2*rd^4 + K3*rd^6)
    O[x, y, z] = o
  else
    O[x, y, z] = lanczos_z(I, cx, cy, z)
  end

	if cx<0 or cy<0 or cx>I.x-1 or cy>I.y-1 then
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
  proc:loadSourceFile("lanczos.ivy")
	proc:loadSourceString(source)
	return execute
end

return init
