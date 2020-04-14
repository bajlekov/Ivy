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
kernel lightnessSelect(I, R, S, O, M)
	const x = get_global_id(0)
  const y = get_global_id(1)

  var i = I[x, y]
	var r = R[x, y]
	var s = S[0, 0]

  var mask = range(r, r, abs(s.x-i.x))

  i.y = i.y*mask
  i.z = i.z*mask
  O[x, y] = i
  M[x, y] = mask
end
]]

local function execute()
  local I, R, S, O, M = proc:getAllBuffers(5)
  proc:executeKernel("lightnessSelect", proc:size2Dmax(O, M), {I, R, S, O, M})
end

local function init(d, c, q)
  proc:init(d, c, q)
  proc:loadSourceString(source)
  return execute
end

return init
