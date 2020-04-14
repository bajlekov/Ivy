--[[
  Copyright (C) 2011-2018 G. Bajlekov

    ImageFloat is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ImageFloat is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local proc = require "lib.opencl.process.ivy".new()

local source = [[
kernel paste(p1, p2, offset)
  const x = get_global_id(0)
  const y = get_global_id(1)
  const z = get_global_id(2)

  var ox = offset[0]
  var oy = offset[1]
  var s = offset[2]

  p2[int(x*s+ox), int(y*s+oy), z] = p1[x, y, z]
end
]]

local function execute()
  local P1, P2, offset = proc:getAllBuffers(3)
  proc:executeKernel("paste", proc:size3D(P1), {P1, P2, offset})
end

local function init(d, c, q)
  proc:init(d, c, q)
  proc:loadSourceString(source)
  return execute
end

return init
