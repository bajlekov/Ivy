--[[
  Copyright (C) 2011-2020 G. Bajlekov

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
kernel void paint(global float *O, global float *P) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float px = P[0];
	float py = P[1];
	float pv = P[2];

	if (px - 32 + x<0 || px - 32 + x>=$O.x$ || py - 32 + y<0 || py - 32 + y>=$O.y$) return;

	float d = sqrt((float)((x-32)*(x-32) + (y-32)*(y-32)));
	float f = d<32.0f ? (cos(d * $$ 1/32*math.pi $$) + 1.0f) * 0.5f : 0.0f;

	float o = $O[px - 32 + x, py - 32 + y];
	$O[px - 32 + x, py - 32 + y] = f*pv + (1.0f - f)*o;
}
]]

local function execute()
	proc:getAllBuffers("O", "P")
	proc.buffers.P.__write = false
	proc:executeKernel("paint", {65, 65})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
