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
kernel mixrgb(I, O, R, G, B)
  const x = get_global_id(0)
  const y = get_global_id(1)

  var i = I[x, y]
  var r = R[x, y]
  var g = G[x, y]
  var b = B[x, y]

  O[x, y, 0] = i.x*r.x + i.y*r.y + i.z*r.z
  O[x, y, 1] = i.x*g.x + i.y*g.y + i.z*g.z
  O[x, y, 2] = i.x*b.x + i.y*b.y + i.z*b.z
end
]]

local function execute()
  local I, O, R, G, B =proc:getAllBuffers(5)
  proc:executeKernel("mixrgb", proc:size2D(O), {I, O, R, G, B})
end

local function init(d, c, q)
  proc:init(d, c, q)
  proc:loadSourceString(source)
  return execute
end

return init
