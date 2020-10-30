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
kernel contrast(I, S, P, O)
  const x = get_global_id(0)
  const y = get_global_id(1)

  var i = I[x, y]
  var s = S[x, y]
  var p = P[x, y]

  var l = YtoL(i.y)

  if l<=0 then
    l = (2-s)*l
  else
    if l>=1 then
      l = 1 + (2-s)*(l-1)
    else

      if l>p then
        l = 1-l
        p = 1-p
        l = (s-1)/p*(l^2) + (2-s)*l
        l = 1-l
      else
        l = (s-1)/p*(l^2) + (2-s)*l
      end

    end
  end

  O[x, y] = i/i.y * LtoY(l)
end
]]

local function execute()
	local I, S, P, O = proc:getAllBuffers(4)
	proc:executeKernel("contrast", proc:size3D(O), {I, S, P, O})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
