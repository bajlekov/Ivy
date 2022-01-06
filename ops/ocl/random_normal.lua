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
local ffi = require "ffi"

local source = [[
kernel random(I, W, P, O, seed)
  const x = get_global_id(0)
  const y = get_global_id(1)
  const z = get_global_id(2)

  var i = I[x, y, z]
  var w = W[x, y, z]

  if P[0]>0.5 then
    i = YtoL(i)
  end
  var o = i + rnorm(seed+z, x, y)*w
  if P[0]>0.5 then
    o = LtoY(o)
  end

  O[x, y, z] = o
end
]]

local function execute()
	local I, W, P, O = proc:getAllBuffers(4)
  local seed = ffi.new("int[1]", math.random( -2147483648, 2147483647))
	proc:executeKernel("random", proc:size3D(O), {I, W, P, O, seed})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
