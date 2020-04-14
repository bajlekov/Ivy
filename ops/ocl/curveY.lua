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
kernel curveY(I, C, L, O)
  const x = get_global_id(0)
  const y = get_global_id(1)

  var i = I[x, y]
  var j = clamp(i.y, 0.0, 1.0)
  if L[0]>0.5 then
    j = YtoL(j)
  end

  var lowIdx = clamp(int(floor(j*255)), 0, 255)
	var highIdx = clamp(int(ceil(j*255)), 0, 255)

	var lowVal = C[lowIdx]
	var highVal = C[highIdx]

  var factor = 0.0
  if lowIdx==highIdx then
    factor = 1.0
  else
    factor = j*255.0-lowIdx
  end

  if L[0]>0.5 then
    i = i * LtoY(mix(lowVal, highVal, factor)) / i.y
  else
    i = i * mix(lowVal, highVal, factor) / i.y
  end

  O[x, y] = i
end
]]

local function execute()
  local I, C, L, O = proc:getAllBuffers(4)
	proc:executeKernel("curveY", proc:size2D(O), {I, C, L, O})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
