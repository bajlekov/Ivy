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
kernel split(i1, i2, p1, p2, o)
  const x = get_global_id(0)
  const y = get_global_id(1)
  const z = get_global_id(2)

  var A = x < o.x*p1[0]

  if p2[0]<0.5 then
    A = not A
  end

  if A then
    o[x, y, z] = i1[x, y, z]
  else
    o[x, y, z] = i2[x, y, z]
  end
end
]]

local function execute()
  local i1, i2, p1, p2, o = proc:getAllBuffers(5)
  proc:executeKernel("split", proc:size3D(o), {i1, i2, p1, p2, o})
end

local function init(d, c, q)
  proc:init(d, c, q)
  proc:loadSourceString(source)
  return execute
end

return init
