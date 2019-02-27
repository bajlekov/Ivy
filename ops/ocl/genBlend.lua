--[[
  Copyright (C) 2011-2018 G. Bajlekov

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

local process = require "lib.opencl.process"

local source = {}
for k, v in ipairs{"negate", "exclude", "screen", "overlay", "hardlight", "softlight", "dodge", "burn", "softdodge", "softburn", "linearlight", "vividlight", "pinlight"} do
  source[v] = [[
	#include "blendops_LRGB.cl"

	kernel void __]]..v..[[(
	  global float *A,
	  global float *B,
		global float *F,
	  global float *O)
	{
	  const int x = get_global_id(0);
	  const int y = get_global_id(1);
	  const int z = get_global_id(2);

		float a = $A[x, y, z];
		float b = $B[x, y, z];
		float f = $F[x, y, 0];

		float o = ]]..v..[[(a, b);

	  $O[x, y, z] = a*(1.0f - f) + o*f;
	}

	]]
end



local function init(d, c, q, name)
  local proc = process.new()

  proc:init(d, c, q)
  proc:loadSourceString(source[name])

  local function execute()
    proc:getAllBuffers("A", "B", "F", "O")
		proc.buffers.A.__write = false
		proc.buffers.B.__write = false
		proc.buffers.F.__write = false
		proc.buffers.O.__read = false
    proc:executeKernel("__"..name, proc:size3D("O"))
  end

  return execute
end

return init
