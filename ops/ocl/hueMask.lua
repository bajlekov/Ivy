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
kernel hueMask(I, C, P, O)
  const x = get_global_id(0)
  const y = get_global_id(1)

  var i = I[x, y, 2]
	i = i - floor(i)

  var lowIdx = clamp(int(floor(i*255.0)), 0, 255)
	var highIdx = clamp(int(ceil(i*255.0)), 0, 255)

	var lowVal = C[lowIdx]
	var highVal = C[highIdx]

	var factor = 0.0
  if lowIdx==highIdx then
    factor = 1.0
  else
    factor = i*255.0-lowIdx
  end

  var o = mix(lowVal, highVal, factor)
  if P[0]>0.5 then
    o = o * I[x, y, 1]
  end
  O[x, y, 0] = o
end
]]

local function execute()
  local I, C, P, O = proc:getAllBuffers(4)
	proc:executeKernel("hueMask", proc:size2D(O), {I, C, P, O})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
