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
kernel void sat(global float *I, global float *T) { // summed area table
  //const int x = get_global_id(0);
	const int y = get_global_id(1);
	const int z = get_global_id(2);

	float acc = 0.0f;

	for (int x = 0; x<$I.x$; x++) {
		acc += $I[x, y, z];
		$T[x, y, z] = acc;
	}
}

kernel void bokeh(global float *I, global float *T, global float *R, global float *O, global float *H) {
	const int x = get_global_id(0);
	const int y = get_global_id(1);
	const int z = get_global_id(2);

	int r = clamp((int)round($R[x, y, 0]*$$math.min(O.x, O.y)/32$$), 0, 256);

	if (r==0) {
		$O[x, y, z] = $I[x, y, z];
	} else {
		float acc = 0.0f;
		float n = 0.0f;
		for (int j = -r; j<=r; j++) {
			if ((y+j)>=0 && (y+j)<$O.y$) {

				int rr; // blur width
				if (H[0]>0.5f) {
					// hexagonal bokeh (height = sqrt(3)/2)
					float h = $$math.sqrt(3)/2$$;
					rr = (float)abs(j)/r > h ? 0 : ceil( r*(1.0f - abs(j)/(h*r*2.0f)) );
				} else {
					// circular bokeh
					rr = ceil(r*sqrt(1.0f-(pown((abs(j)+0.5f)/r, 2))));
				}

				if (rr>0) {
					int xmin = max(x-rr, 0)-1;
					int xmax = min(x+rr, $$O.x-1$$);
					if (xmin==-1) {
						acc += $T[xmax, y+j, z];
						n += xmax + 1;
					} else {
						acc += $T[xmax, y+j, z] - $T[xmin, y+j, z];
						n += xmax-xmin;
					}
				}
			}
		}
		$O[x, y, z] = acc/n;
	}
}
]]

local function execute()
	proc:getAllBuffers("I", "R", "O", "H")

	proc.buffers.T = proc.buffers.I:new()
	local x, y, z = proc.buffers.I:shape()

	proc:setWorkgroupSize({1, 256, 1})
	proc:executeKernel("sat", {1, y, z}, {"I", "T"})
	proc:setWorkgroupSize()
	proc:executeKernel("bokeh", proc:size3D("O"), {"I", "T", "R", "O", "H"})

	proc.buffers.T:free()
	proc.buffers.T = nil
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
