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
kernel void colorSample(global float *I, global float *P, global float *S) {
  const int x = P[0];
  const int y = P[1];

  float3 s = (float3)0.0f;
	for (int i = -2; i<=2; i++)
		for (int j = -2; j<=2; j++)
			s += $I[x+i, y+j]XYZ;

	s = XYZto$$I.cs$$(s/25.0f);

  $S[0, 0] = s;
}
]]

local function execute()
	proc:getAllBuffers("I", "P", "S")
	proc:executeKernel("colorSample", {1, 1})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
