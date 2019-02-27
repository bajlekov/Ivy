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
kernel void structure(global float *I, global float *S, global float *O)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float i = $I[x, y, 0];
	float s = $S[x, y, 0]*2;
	float o = $O[x, y, 0];

	float v = (i-o)*s;
	v = i + fmin(v, 0.0f)*i + fmax(v, 0.0f)*(1-i);

	$O[x, y, 0] = v;
	$O[x, y, 1] = $I[x, y, 1]*v/i;
	$O[x, y, 2] = $I[x, y, 2]*v/i;
}
]]

local function execute()
	proc:getAllBuffers("I", "S", "O")
	proc:executeKernel("structure", proc:size2D("O"))
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
