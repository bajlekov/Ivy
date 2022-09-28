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
kernel adjust(I, E, B, C, V, O)
  const x = get_global_id(0)
  const y = get_global_id(1)

  -- adjust exposure (LRGB)

  var e = 2^E[x, y]
  var i = I[x, y]
  var o = i*e

  -- adjust brightness (XYZ)

  i = LRGBtoXYZ(o)
  var b = B[x, y]
  var l = YtoL(i.y)

  if l<0.0 then
    l = b*l
  else
    if l>1.0 then
      l = 1.0 + (2.0-b)*(l-1.0)
    else
      l = (1.0-b)*l^2 + b*l
    end
  end

  -- adjust contrast (XYZ)

  var c = C[x, y]
  var p = 0.5 -- fixed pivot

  if l<=0 then
    l = (2-c)*l
  else
    if l>=1 then
      l = 1 + (2-c)*(l-1)
    else

      if l>p then
        l = 1-l
        p = 1-p
        l = (c-1)/p*(l^2) + (2-c)*l
        l = 1-l
      else
        l = (c-1)/p*(l^2) + (2-c)*l
      end

    end
  end

  o = i/i.y * LtoY(l)

  -- adjust vibrance (LRGB)

  var v = V[x, y]

  var Y = o.y
	i = XYZtoLRGB(o)

  var d = i-Y
  var m3 = vec(0.0)
  if d.x<0.0 then m3.x = -d.x/Y else m3.x = d.x/(1.0-Y) end
  if d.y<0.0 then m3.y = -d.y/Y else m3.y = d.y/(1.0-Y) end
  if d.z<0.0 then m3.z = -d.z/Y else m3.z = d.z/(1.0-Y) end
  
  var m = clamp(max(m3.x, max(m3.y, m3.z)), 0.0001, 1.0) -- greatest multiplier without clipping
  var mv = (1.0 - v)*m^2 + v*m

  O[x, y] = Y + mv/m*d
end
]]

local function execute()
	local I, E, B, C, V, O = proc:getAllBuffers(6)
	proc:executeKernel("adjust", proc:size2D(O), {I, E, B, C, V, O})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
