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
kernel chromaSelect(I, R, S, O, M)
  const x = get_global_id(0)
  const y = get_global_id(1)

	var r = R[x, y, 0]
	var s = S[0, 0]
  var i = I[x, y]

  var mask = range(r, r, abs(s.y-i.y))
  if O.z==3 then
    O[x, y, 0] = i.x
    O[x, y, 1] = i.y*mask
    O[x, y, 2] = i.z
  end
  M[x, y] = mask
end
]]

local function execute()
  local I, R, S, O, M = proc:getAllBuffers(5)
  proc:executeKernel("chromaSelect", proc:size2Dmax(O, M), {I, R, S, O, M})
end

local function init(d, c, q)
  proc:init(d, c, q)
  proc:loadSourceString(source)
  return execute
end

return init
