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
local blur = require "ops.ocl.macro.blur"

local source = [[
kernel high_pass(I, L, O)
	const x = get_global_id(0)
	const y = get_global_id(1)

	var i = I[x, y]
	var l = L[x, y]

	O[x, y] = i-l
end
]]

local function execute()
	local I, O, n = proc:getAllBuffers(3)

	local n = n:get(0, 0, 0)
	blur.execute(proc, I, O, n)
	proc:executeKernel("high_pass", proc:size2D(O), {I, O, O})
end

local function init(d, c, q)
	proc:init(d, c, q)
	blur.init(proc)
  proc:loadSourceString(source)
	return execute
end

return init
