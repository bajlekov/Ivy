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

local tools = {}

tools.parseIndex = require "lib.opencl.tools.parseIndex"
tools.getID = require "lib.opencl.tools.getID"

function tools.profile(name, event, queue, suppress)
	queue:finish() -- ensure that queued operation is finished
	local t1 = event:get_profiling_info("start")
	local t2 = event:get_profiling_info("end")
	local time = tonumber(t2 - t1) / 1000000
	if not suppress then
		print("[OCL]"..name..": "..string.format("%.3fms", (time)))
	end
	return time
end

--tools.buildParams = "-cl-fast-relaxed-math -cl-single-precision-constant -cl-mad-enable -cl-std=CL2.0"
--tools.buildParams = "-cl-fast-relaxed-math -cl-single-precision-constant -cl-mad-enable -cl-std=CL1.2"
tools.buildParams = settings.openclBuildParams

return tools
