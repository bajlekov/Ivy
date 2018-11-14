--[[
  Copyright (C) 2011-2018 G. Bajlekov

    ImageFloat is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ImageFloat is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local proc = require "lib.opencl.process".new()

local source = [[
kernel void mixfactor(global float *p1, global float *p2, global float *p3, global float *p4)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
  const int z = get_global_id(2);

  float f = $p3[x, y, z];
  f = clamp(f, 0.0f, 1.0f);

  $p4[x, y, z] = $p1[x, y, z]*f + $p2[x, y, z]*(1.0f - f);
}
]]

local function execute()
  proc:getAllBuffers("p1", "p2", "p3", "p4")
  proc:executeKernel("mixfactor", proc:size3D("p4"))
end

local function init(d, c, q)
  proc:init(d, c, q)
  proc:loadSourceString(source)
  return execute
end

return init
