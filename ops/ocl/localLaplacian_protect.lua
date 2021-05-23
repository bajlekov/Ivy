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

local source = [[
-- I (XYZ) -> O (XYZ)
kernel post_LL_protect(I, O, S, H)
  const x = get_global_id(0)
  const y = get_global_id(1)

  var i = I[x, y]
  var o = O[x, y]

	var fs = 0.0
	var fh = 0.0

	var s = S[x, y]
	var h = H[x, y]
	var ls = 1.0 - clamp(YtoL(o.y), 0.0, 1.0)
	var lh = clamp(YtoL(o.y), 0.0, 1.0)
	fs = ls*s
	fh = lh*h

	o.y = fs*max(i.y, o.y) + fh*min(i.y, o.y) + (1-fs-fh)*o.y

  O[x, y] = max(i*o.y/i.y, 0.0)
end
]]

local function execute()
	local I, D, R, O, hq, S, H = proc:getAllBuffers(7) -- input, detail, range, output

	local hq = hq:get(0, 0, 0)>0.5 and 127 or 15

	localLaplacianMacro.execute(proc, I, D, R, O, hq, false)

	proc:executeKernel("post_LL_protect", proc:size2Dmax(I), {I, O, S, H})
end

local function init(d, c, q)
	proc:init(d, c, q)
	localLaplacianMacro.init(proc)
	proc:loadSourceString(source)
	return execute
end

return init
