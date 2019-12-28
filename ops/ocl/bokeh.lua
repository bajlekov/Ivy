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

local proc = require "lib.opencl.process.ivy".new()

local source = [[
kernel sat(I, T) -- summed area table
  -- const x = get_global_id(0)
	const y = get_global_id(1)
	const z = get_global_id(2)

	var acc = 0.0

	for x = 0, I.x do
		acc = acc + I[x, y, z]
		T[x, y, z] = acc
	end
end

kernel bokeh(I, T, R, O, H)
	const x = get_global_id(0)
	const y = get_global_id(1)
	const z = get_global_id(2)

	var r = clamp(int(round(R[x, y, 0]*min(O.x, O.y)/32.0)), 0, 256)

	if r==0 then
		O[x, y, z] = I[x, y, z]
	else
		var acc = 0.0
		var n = 0.0

		for j = -r, r do
			if (y+j)>=0 and (y+j)<O.y then

				var rr = 0 -- blur width

        if H[0]>0.5 then
					-- hexagonal bokeh (height = sqrt(3)/2)
					var h = sqrt(3.0)/2.0
          if float(abs(j))/r > h then
					  rr = 0
					else
					  rr = ceil( r*(1.0 - abs(j)/(h*r*2.0)) )
					end
				else
					-- circular bokeh
					rr = ceil( r*sqrt(1.0 - ((abs(j)+0.5)/r)^2) )
				end

				if rr>0 then
					var xmin = max(x-rr, 0)-1
					var xmax = min(x+rr, O.x-1)
					if xmin==-1 then
						acc = acc + T[xmax, y+j, z]
						n = n + xmax + 1
					else
						acc = acc + T[xmax, y+j, z] - T[xmin, y+j, z]
						n = n + xmax - xmin
					end
				end
			end
		end

		O[x, y, z] = acc/n
	end
end
]]

local function execute()
	local I, R, O, H = proc:getAllBuffers(4)

	local T = I:new()
	local x, y, z = I:shape()

	proc:setWorkgroupSize({1, 256, 1})
	proc:executeKernel("sat", {1, y, z}, {I, T})
	proc:setWorkgroupSize()
	proc:executeKernel("bokeh", proc:size3D(O), {I, T, R, O, H})

	T:free()
	T = nil
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
