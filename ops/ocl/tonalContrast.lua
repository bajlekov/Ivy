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
kernel void tonalContrast(global float * I, global float * P1, global float * P2, global float * P3, global float * P4, global float * O)
{
	const int x = get_global_id(0);
	const int y = get_global_id(1);

	float i = $I[x, y, 0];
	float d = $I[x, y, 0] - $O[x, y, 0];

	float p1 = $P1[x, y, 0];
	float p2 = $P2[x, y, 0];
	float p3 = $P3[x, y, 0];
	float p4 = $P4[x, y, 0];

	float g;
	float t = 1.0f / 3.0f;
	if (i < t) {
		float f = cos(i * 3.0f * M_PI) * 0.5f + 0.5f;
		g = p2 * d * (1.0f - f) + p1 * d * f;
	} else if (i < 2 * t) {
		float f = cos((i - t) * 3.0f * M_PI) * 0.5f + 0.5f;
		g = p3 * d * (1.0f - f) + p2 * d * f;
	} else {
		float f = cos((i - 2.0f * t) * 3.0f * M_PI) * 0.5f + 0.5f;
		g = p4 * d * (1.0f - f) + p3 * d * f;
	}

	g = isnan(g) ? 0.0f : g;

	$O[x, y, 0] = i + fmin(g, 0.0f)*i + fmax(g, 0.0f)*(1-i);
	$O[x, y, 1] = $I[x, y, 1]; // * (1.0f + (g - i));
	$O[x, y, 2] = $I[x, y, 2]; // * (1.0f + (g - i));
}
]]

local function execute()
	proc:getAllBuffers("I", "P1", "P2", "P3", "P4", "O")
	proc:executeKernel("tonalContrast", proc:size2D("O"))
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
