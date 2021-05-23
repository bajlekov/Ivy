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

local process = require "lib.opencl.process.ivy"

local source = {}
for k, v in ipairs{"negate", "exclude", "screen", "overlay", "hardlight", "softlight", "dodge", "burn", "softdodge", "softburn", "linearlight", "vividlight", "pinlight"} do
  source[v] = [[

	kernel kernel_]]..v..[[(A, B, F, O)
	  const x = get_global_id(0)
	  const y = get_global_id(1)
	  const z = get_global_id(2)

		var a = A[x, y, z]
		var b = B[x, y, z]
		var f = F[x, y, z]

		var o = ]]..v..[[(a, b)

	  O[x, y, z] = a*(1.0 - f) + o*f
	end
	]]
end



local function init(d, c, q, name)
  local proc = process.new()

  proc:init(d, c, q)
  proc:loadSourceFile("blendops_LRGB.ivy")
  proc:loadSourceString(source[name])

  local function execute()
    local A, B, F, O = proc:getAllBuffers(4)
    proc:executeKernel("kernel_"..name, proc:size3D(O), {A, B, F, O})
  end

  return execute
end

return init
