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
local localLaplacianMacro = require "ops.ocl.macro.localLaplacian"

local function execute()
	local I, D, R, O, hq = proc:getAllBuffers(5) -- input, detail, range, output

	local hq = hq:get(0, 0, 0)>0.5 and 127 or 15

	localLaplacianMacro.execute(proc, I, D, R, O, hq)
end

local function init(d, c, q)
	proc:init(d, c, q)
	localLaplacianMacro.init(proc)
	return execute
end

return init
