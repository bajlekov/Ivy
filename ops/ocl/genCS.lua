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
kernel SRGB(I, O)
	const x = get_global_id(0)
	const y = get_global_id(1)
	O[x, y] = I[x, y].SRGB
end

kernel LRGB(I, O)
	const x = get_global_id(0)
	const y = get_global_id(1)
	O[x, y] = I[x, y].LRGB
end

kernel XYZ(I, O)
	const x = get_global_id(0)
	const y = get_global_id(1)
	O[x, y] = I[x, y].XYZ
end

kernel LAB(I, O)
	const x = get_global_id(0)
	const y = get_global_id(1)
	O[x, y] = I[x, y].LAB
end

kernel LCH(I, O)
	const x = get_global_id(0)
	const y = get_global_id(1)
	O[x, y] = I[x, y].LCH
end

kernel Y(I, O)
	const x = get_global_id(0)
	const y = get_global_id(1)
	O[x, y] = I[x, y].Y
end

kernel L(I, O)
	const x = get_global_id(0)
	const y = get_global_id(1)
	O[x, y] = I[x, y].L
end
]]

local function init(d, c, q, name)
  proc:init(d, c, q)
	proc:loadSourceString(source)

  return function()
  	local I, O = proc:getAllBuffers(2)
  	proc:executeKernel(name, proc:size2D(O), {I, O})
  end
end

return init
