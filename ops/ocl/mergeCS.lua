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
kernel merge(I1, I2, I3, O)
  const x = get_global_id(0)
  const y = get_global_id(1)

  O[x, y] = vec(I1[x, y], I2[x, y], I3[x, y])
end
]]

local function execute()
  local I1, I2, I3, O = proc:getAllBuffers(4)
  proc:executeKernel("merge", proc:size2D(O), {I1, I2, I3, O})
end

local function init(d, c, q)
  proc:init(d, c, q)
  proc:loadSourceString(source)
  return execute
end

return init
