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
kernel levels_RGB(I, Ibp, Iwp, G, Obp, Owp, O)
  const x = get_global_id(0)
  const y = get_global_id(1)

  var ibp = LtoY(Ibp[x, y])
  var iwp = LtoY(Iwp[x, y])

  var obp = LtoY(Obp[x, y])
  var owp = LtoY(Owp[x, y])

	var v = I[x, y]
  v = v - ibp
  v = v / (iwp - ibp)

  v = max(v, 0.0) -- gamma function not defined for negative input
  v = v^(log(G[x, y])/log(0.5))

  v = v * (owp - obp)
  v = v + obp

  O[x, y] = v
end
]]

local function execute()
	local I, Ibp, Iwp, G, Obp, Owp, O = proc:getAllBuffers(7)
	proc:executeKernel("levels_RGB", proc:size2D(O), {I, Ibp, Iwp, G, Obp, Owp, O})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
