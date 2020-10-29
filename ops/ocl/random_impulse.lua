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
local ffi = require "ffi"

local source = [[
kernel random(I, P, O, W, B, seed)
  const x = get_global_id(0)
  const y = get_global_id(1)
  const z = get_global_id(2)

  var p = (1 - P[x, y, z])*0.5
  var w = W[x, y, z] > 0.5
  var b = B[x, y, z] > 0.5

  var r = runif(seed+z, x, y)
  if r > (0.5 + p) and w then
    O[x, y, z] = 1.0
  else
    if r < (0.5 - p) and b then
      O[x, y, z] = 0.0
    else
      O[x, y, z] = I[x, y, z]
    end
  end
end
]]

local function execute()
	local I, P, W, B, O = proc:getAllBuffers(5)
  local seed = ffi.new("int[1]", math.random( -2147483648, 2147483647))
	proc:executeKernel("random", proc:size3D(O), {I, P, O, W, B, seed})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
