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
kernel void levels_RGB(
  global float *i,
  global float *bpi,
  global float *wpi,
  global float *g,
  global float *bpo,
  global float *wpo,
  global float *o)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);

  float3 v = $i[x, y];
  // calculate f(0) and f'(0)
  v = v - $bpi[x, y];
  v = v / ($wpi[x, y]-$bpi[x, y]);

  v = max(v, 0.0f); // gamma function not defined for negative input
  v = pow(v, log($g[x, y])/log(0.5f));

  v = v * ($wpo[x, y]-$bpo[x, y]);
  v = v + $bpo[x, y];

  $o[x, y] = v;
}
]]

local function execute()
	proc:getAllBuffers("i", "bpi", "wpi", "g", "bpo", "wpo", "o")
	proc:executeKernel("levels_RGB", proc:size2D("o"))
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
