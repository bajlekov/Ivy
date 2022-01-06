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

local proc = require "lib.opencl.process.ivy".new()

local source = [[
const Q = 144
const F = 12

function getColor(LUT, r, g, b)
	r = clamp(r, 0, Q-1)
	g = clamp(g, 0, Q-1)
  b = clamp(b, 0, Q-1)

	var gf = g\F
	var x = r + (g - gf*F)*Q
	var y = b*F + gf

	y = Q*F - y - 1 
	return LUT[x, y]
end

kernel lut(I, LUT, O, MIX)
  const x = get_global_id(0)
  const y = get_global_id(1)

	var i = max(I[x, y], vec(0))
  var v = LRGBtoSRGB(i)*(Q-1) -- sample LUT based on sRGB coordinates
 	var s = clamp(v, vec(0), vec(Q-1))
  var fs = floor(s)
  var d = s - fs

	var r = int(fs.x)
	var g = int(fs.y)
	var b = int(fs.z)

  var s1 = getColor(LUT, r  , g  , b  )
	var s2 = getColor(LUT, r+1, g  , b  )
	var s3 = getColor(LUT, r+1, g+1, b  )
	var s4 = getColor(LUT, r  , g+1, b  )
	var s5 = getColor(LUT, r  , g  , b+1)
	var s6 = getColor(LUT, r+1, g  , b+1)
	var s7 = getColor(LUT, r+1, g+1, b+1)
	var s8 = getColor(LUT, r  , g+1, b+1)

  var s15 = s1 + d.z*(s5-s1)
  var s26 = s2 + d.z*(s6-s2)
  var s37 = s3 + d.z*(s7-s3)
  var s48 = s4 + d.z*(s8-s4)

  var s1526 = s15 + d.x*(s26-s15)
  var s4837 = s48 + d.x*(s37-s48)

  var o = clamp(s1526 + d.y*(s4837-s1526), 0.0, 1.0)

	o = i + (o-i) * MIX[x, y]

  O[x, y] = o
end
]]

local function execute()
  local I, LUT, O, MIX = proc:getAllBuffers(4)
  proc:executeKernel("lut", proc:size2D(O), {I, LUT, O, MIX})
end

local function init(d, c, q)
  proc:init(d, c, q)
  proc:loadSourceString(source)
  return execute
end

return init
