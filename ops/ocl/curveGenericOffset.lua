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
kernel void curveGenericOffset(global float *I, global float *D, global float *C, global float *R, global float *O)
{
	const int x = get_global_id(0);
  const int y = get_global_id(1);

	bool r = R[0];

	float d = $D[x, y, 0];
	d = r ? d*0.5f + 0.5f : d; // [-1, 1] range

  float f = clamp(d, 0.0f, 1.0f);

  int lowIdx = clamp(floor(f*255), 0.0f, 255.0f);
	int highIdx = clamp(ceil(f*255), 0.0f, 255.0f);

	float lowVal = C[lowIdx];
	float highVal = C[highIdx];

	float factor = lowIdx==highIdx ? 1.0f : (f*255.0f-lowIdx)/(highIdx-lowIdx);
	f = lowVal*(1.0f - factor) + highVal*factor;

  $O[x, y, 0] = $I[x, y, 0] + (f-0.5f)*2.0f;
}
]]

local function execute()
	proc:getAllBuffers("I", "D", "C", "R", "O")
	proc:executeKernel("curveGenericOffset", proc:size2D("O"))
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
