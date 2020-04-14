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
kernel contrast(I, P, O)
  const x = get_global_id(0)
  const y = get_global_id(1)

  var i = I[x, y]
  var p = P[x, y]

  var l = YtoL(i.y)

  if l<0.0 then
    l = (1.0-p)*l
  else
    if l>1.0 then
      l = 1.0 + (2.0-p)*(l-1.0)
    else
      l = l*2.0-1.0
  		var s = sign(l)
  		l = (1.0 - p)*l^2 + abs(l)*p
  		l = (s*l + 1.0)*0.5
    end
  end

  O[x, y] = i/i.y * LtoY(l)
end
]]

local function execute()
	local I, P, O = proc:getAllBuffers(3)
	proc:executeKernel("contrast", proc:size3D(O), {I, P, O})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
