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
kernel void convert(global float *I, global float *M, global float *W)
{
	const int x = get_global_id(0);
	const int y = get_global_id(1);

	float ri = $I[x, y, 0] * $W[0, 0, 0];
	float gi = $I[x, y, 1] * $W[0, 0, 1];
	float bi = $I[x, y, 2] * $W[0, 0, 2];

	float ro = ri*$M[0, 0, 0] + gi*$M[0, 1, 0] + bi*$M[0, 2, 0];
	float go = ri*$M[1, 0, 0] + gi*$M[1, 1, 0] + bi*$M[1, 2, 0];
	float bo = ri*$M[2, 0, 0] + gi*$M[2, 1, 0] + bi*$M[2, 2, 0];

  $I[x, y, 0] = ro;
	$I[x, y, 1] = go;
	$I[x, y, 2] = bo;
}
]]

local function execute()
	proc:getAllBuffers("I", "M", "W")
	proc.buffers.M.__write = false
	proc.buffers.W.__write = false
	proc:executeKernel("convert", proc:size2D("I"))
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
