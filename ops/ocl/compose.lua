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
kernel void compose(global float *p1, global float *p2, global float *p3, global float *p4)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);

  $p4[x, y, 0] = $p1[x, y, 0];
  $p4[x, y, 1] = $p2[x, y, 1];
  $p4[x, y, 2] = $p3[x, y, 2];
}
]]

local function execute()
  proc:getAllBuffers("p1", "p2", "p3", "p4")
  proc:executeKernel("compose", proc:size2D("p4"))
end

local function init(d, c, q)
  proc:init(d, c, q)
  proc:loadSourceString(source)
  return execute
end

return init
