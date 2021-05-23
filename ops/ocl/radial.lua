--[[
  Copyright (C) 2011-2021 G. Bajlekov

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

---[==[
local source = [[
kernel void radial(global float *X, global float *Y, global float *O)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float f = max($O.x$, $O.y$);

	float2 p = (float2)((float)x/f, (float)y/f);

	float2 a = (float2)($X[x, y, 0], $Y[x, y, 0]/$O.x$*$O.y$);

	float o = distance(a, p);

	$O[x, y, 0] = o;
}
]]
--]==]

--[==[
local source = [[
kernel void radial(global float *X, global float *Y, global float *O)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float f = max($O.x$, $O.y$);

	float2 p = (float2)((float)x/f, (float)y/f);
	float2 n = (float2)(1.0f, 0.0f);
	float2 a = (float2)($X[x, y, 0], $Y[x, y, 0]/$O.x$*$O.y$);

	float2 d = (a-p) - dot((a-p), n)*n;

	float o = length(d);
	o = clamp(o, 0.0f, 1.0f);

	$O[x, y, 0] = o;
}
]]
--]==]

local function execute()
	proc:getAllBuffers("X", "Y", "O")
	proc:executeKernel("radial", proc:size2Dmax("O"))
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
