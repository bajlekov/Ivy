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
kernel void curveY__(global float *I, global float *C, global float *O)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
	const int z = get_global_id(2);

  float i = clamp($I[x, y, z], 0.0f, 1.0f);

  int lowIdx = clamp(floor(i*255), 0.0f, 255.0f);
	int highIdx = clamp(ceil(i*255), 0.0f, 255.0f);

	float lowVal = C[lowIdx];
	float highVal = C[highIdx];

	float factor = lowIdx==highIdx ? 1.0f : (i*255.0f-lowIdx)/(highIdx-lowIdx);
	i = lowVal*(1.0f - factor) + highVal*factor;

  $O[x, y, z] = i;
}
]]

local function execute()
	proc:getAllBuffers("I", "C", "O")
	proc:executeKernel("curveY__", proc:size3D("O"))
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
