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

local source = [[
kernel saturation(I, P, O)
  const x = get_global_id(0)
  const y = get_global_id(1)

  var i = I[x, y]
  var p = P[x, y]

  var iy = YtoXYZ(i.y)

  O[x, y] = iy + (i-iy)*p
end
]]

local target = "OCL"
local proc
local execute

if target=="ISPC" then

  proc = require "lib.opencl.process.ivy_ispc".new()
  function execute()
  	local I, P, O = proc:getAllBuffers(3)
    I:toHost(true)
  	proc:executeKernel("saturation", proc:size2D(O), {I, P, O})
    O:toDevice(true)
  end

else

  proc = require "lib.opencl.process.ivy".new()
  function execute()
  	local I, P, O = proc:getAllBuffers(3)
  	proc:executeKernel("saturation", proc:size2D(O), {I, P, O})
  end

end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
