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
kernel smartSelect(I, R, D,  P, S, O, M)
  const x = get_global_id(0)
  const y = get_global_id(1)

  var i = I[x, y]
	var r = R[x, y]
	var d = D[x, y]
  var s = S[0, 0]

  var d1 = sqrt((x-P[0])^2 + (y-P[1])^2) / min(I.x, I.y)*2
  var d2 = sqrt((i.x-s.x)^2 + (i.y-s.y)^2 + (i.z-s.z)^2)
  var mask = range(d, d, d1)*range(r, r, d2)

  i.y = i.y*mask
  i.z = i.z*mask
  O[x, y] = i
  M[x, y] = mask
end
]]

local function execute()
  local I, R, D, P, S, O, M = proc:getAllBuffers(7)
  proc:executeKernel("smartSelect", proc:size2Dmax(O, M), {I, R, D, P, S, O, M})
end

local function init(d, c, q)
  proc:init(d, c, q)
  proc:loadSourceString(source)
  return execute
end

return init
