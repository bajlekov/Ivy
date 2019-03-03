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
kernel void xy(global float *B, global float *W, global float *X, global float *Y)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
  const int z = get_global_id(2);

  const int xmax = $$ math.max(X.x, Y.x) $$;
  const int ymax = $$ math.max(X.y, Y.y) $$;

	float fx = (float)x/xmax;
	float fy = (float)y/ymax;

	float b = $B[x, y, z];
	float w = $W[x, y, z];

  $X[x, y, z] = w*fx + b*(1-fx);
  $Y[x, y, z] = w*fy + b*(1-fy);
}
]]

local function execute()
	proc:getAllBuffers("B", "W", "X", "Y")
	proc:executeKernel("xy", proc:size3Dmax("X", "Y"))
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
