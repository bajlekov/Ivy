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

local proc = require "lib.opencl.process.ivy".new()

local source = [[
	function gaussian(x, s)
		return exp(-0.5*(x/s)^2)
	end
	
	kernel unsharp_mask(I, R, S, O)
		const x = get_global_id(0)
		const y = get_global_id(1)
	
		var w = R[0]
		var i = I[x, y, 0]
		var v = i
	
		if w==0 then
			v = i
		else
			var g = {gaussian(0, w), gaussian(1, w), gaussian(2, w), gaussian(3, w)}
			var n = g[0] + 2*g[1] + 2*g[2] + 2*g[3]
			g[0] = g[0]/n
			g[1] = g[1]/n
			g[2] = g[2]/n
			g[3] = g[3]/n
	
			v = 0
			for i = -3, 3 do
				for j = -3, 3 do
					v = v + I[x+i, y+j, 0] * g[abs(i)]*g[abs(j)]
				end
			end
		end
	
		var o = i + (i-v)*S[0]
	
		O[x, y, 0] = o
		O[x, y, 1] = I[x, y, 1]
		O[x, y, 2] = I[x, y, 2]
	end
]]

local function execute()
	local I, R, S, O = proc:getAllBuffers(4)
	proc:executeKernel("unsharp_mask", proc:size2D(O), {I, R, S, O})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
