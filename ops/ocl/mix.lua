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
kernel mixfactor(p1, p2, p3, p4)
  const x = get_global_id(0)
  const y = get_global_id(1)
  const z = get_global_id(2)

  var f = p3[x, y, z]
  f = clamp(f, 0.0, 1.0)

  p4[x, y, z] = p1[x, y, z]*f + p2[x, y, z]*(1 - f)
end
]]

local function execute()
  local p1, p2, p3, p4 = proc:getAllBuffers(4)
  proc:executeKernel("mixfactor", proc:size3D(p4), {p1, p2, p3, p4})
end

local function init(d, c, q)
  proc:init(d, c, q)
  proc:loadSourceString(source)
  return execute
end

return init
