--[[
  Copyright (C) 2011-2019 G. Bajlekov

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
kernel void mixrgb(global float *p1, global float *p2, global float *r, global float *g, global float *b)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);

  float3 iv = $p1[x, y];
  float3 rv = $r[x, y];
  float3 gv = $g[x, y];
  float3 bv = $b[x, y];

  $p2[x, y, 0] = iv.x*rv.x + iv.y*rv.y + iv.z*rv.z;
  $p2[x, y, 1] = iv.x*gv.x + iv.y*gv.y + iv.z*gv.z;
  $p2[x, y, 2] = iv.x*bv.x + iv.y*bv.y + iv.z*bv.z;
}
]]

local function execute()
  proc:getAllBuffers("p1", "p2", "r", "g", "b")
  proc:executeKernel("mixrgb", proc:size2D("p2"))
end

local function init(d, c, q)
  proc:init(d, c, q)
  proc:loadSourceString(source)
  return execute
end

return init
