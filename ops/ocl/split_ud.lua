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

local proc = require "lib.opencl.process".new()

local source = [[
kernel void split(global float *i1, global float *i2, global float *p1, global float *p2, global float *o)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
  const int z = get_global_id(2);

  bool A = (y > $o.y$*p1[0]);

  A = (p2[0]<0.5) ? A : !A;

  $o[x, y, z] = A ? $i1[x, y, z] : $i2[x, y, z];
}
]]

local function execute()
  proc:getAllBuffers("i1", "i2", "p1", "p2", "o")
  proc:executeKernel("split", proc:size3D("o"))
end

local function init(d, c, q)
  proc:init(d, c, q)
  proc:loadSourceString(source)
  return execute
end

return init
