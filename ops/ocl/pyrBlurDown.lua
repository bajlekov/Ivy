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
constant float k[5] = {0.0625, 0.25, 0.375, 0.25, 0.0625};

constant float kk[5][5] = {
  {0.00390625, 0.015625, 0.0234375, 0.015625, 0.00390625},
  {0.015625  , 0.0625  , 0.09375  , 0.0625  , 0.015625  },
  {0.0234375 , 0.09375 , 0.140625 , 0.09375 , 0.0234375 },
  {0.015625  , 0.0625  , 0.09375  , 0.0625  , 0.015625  },
  {0.00390625, 0.015625, 0.0234375, 0.015625, 0.00390625}
};

kernel void pyrDown(global float *I, global float *G)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
  const int z = get_global_id(2);

	float h[5][5];
	for (int i = 0; i<5; i++)
		for (int j = 0; j<5; j++)
			h[i][j] = $I[x*2+i-2, y*2+j-2, z];

	float v[5];
	for (int i = 0; i<5; i++)
		v[i] = 0;
	for (int i = 0; i<5; i++)
		#pragma unroll 5
		for (int j = 0; j<5; j++) {
			v[i] += h[i][j]*k[j];
		}

	float g = 0;
	for (int i = 0; i<5; i++) {
		g += v[i]*k[i];
	}

	$G[x, y, z] = g;
}
]]

local function execute()
	proc:getAllBuffers("I", "G")
	proc:executeKernel("pyrDown", proc:size3D("G"))
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
