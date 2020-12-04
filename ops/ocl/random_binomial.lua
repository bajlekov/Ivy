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
kernel random(I, W, P, O, seed)
  const x = get_global_id(0)
  const y = get_global_id(1)
  const z = get_global_id(2)

  --var n = max(W[x, y, z], 1.0)
  --var n2 = int(n*n)

  var n2 = int(clamp(1.0/(4*W[x, y, z]^2), 1.0, 1000000.0))

  var i = I[x, y, z]
  if P[0]>0.5 then
    i = YtoL(i)
  end

  var o = 0.0
  if i<=0.0 then
    o = 0.0
  elseif i>=1.0 then
    o = 1.0
  else
    if n2*i>100.0 or n2*(1.0-i)>100.0 then
      -- normal approximation
      var r = rnorm(seed+z, x, y)
      var s = round(n2*i + r*sqrt(n2*i*(1-i)))
      o = s/n2
    else
      -- uniform sampling
      var s = 0

      for k = 1, n2 do
        var r = runif(seed+z, x + O.x*y, k)

        if r<i then
          s = s + 1
        end
      end

      o = float(s)/n2
    end

    if P[0]>0.5 then
      o = LtoY(o)

      -- correction for average luminance
      var f = (i/LtoY(i) - 1)/n2 + 1
      o = o/f
    end
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
