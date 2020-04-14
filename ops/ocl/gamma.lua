--[[
  Copyright (C) 2011-2020 G. Bajlekov

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
kernel gamma(I, G, O)
  const x = get_global_id(0)
  const y = get_global_id(1)

  var i = max(I[x, y], 0.0)
  var j = i.y ^ (log(G[x, y])/log(0.5))
  i = i * j / i.y

  O[x, y] = i
end
]]

local function execute()
	local I, G, O = proc:getAllBuffers(3)
	proc:executeKernel("gamma", proc:size2D(O), {I, G, O})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
