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
kernel vibrance(I, V, O)
  const x = get_global_id(0)
  const y = get_global_id(1)

	var i = I[x, y]
	var v = V[x, y]

  var Y = LRGBtoY(i)

  var d = i-Y
  var m3 = vec(0.0)
  if d.x<0.0 then m3.x = -Y/d.x else m3.x = (1.0-Y)/d.x end
  if d.y<0.0 then m3.y = -Y/d.y else m3.y = (1.0-Y)/d.y end
  if d.z<0.0 then m3.z = -Y/d.z else m3.z = (1.0-Y)/d.z end

  var m = 1.0/max(min(m3.x, min(m3.y, m3.z)), 0.0001)
  m = clamp(m, 0.0001, 1.0)

  var mv = (1.0 - v)*m^2 + v*m

  O[x, y] = Y + mv/m*d
end
]]

local function execute()
	local I, V, O = proc:getAllBuffers(3)
	proc:executeKernel("vibrance", proc:size2D(O), {I, V, O})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
