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

local ffi = require "ffi"

local proc = require "lib.opencl.process.ivy".new()

local source = [[
const hi = 1.0001
const lo = -0.0001

kernel display(I, O, P)
  const x = get_global_id(0)
  const y = get_global_id(1)

  var i = I[x, y].LRGB
	if P[0]>0.5 and (i.x>hi or i.y>hi or i.z>hi) then
		i = 0.0
	end

	if P[0]>0.5 and (i.x<lo or i.y<lo or i.z<lo) then
		i = 1.0
	end

  var m = max(max(i.x, i.y), i.z)
  if P[0]<0.5 and m>1.0 then
    var Y = LRGBtoY(i)
    if Y<1.0 then
      var d = i-Y
      var f = (1.0-Y)/(m-Y)
      i = Y + d*f
    else
      i = 1.0
    end
  end

  i = LRGBtoSRGB(i)

  O[x, O.y-y-1] = RGBA(i, 1.0)
end
]]

local function execute()
  local I, O, P = proc:getAllBuffers(3)

  proc:executeKernel("display", proc:size2D(O), {I, O, P})

  O:devWritten()
  O:syncHost(true)
  O:freeDev()
end

local function init(d, c, q)
  proc:init(d, c, q)
  proc:loadSourceString(source)
  return execute
end

return init
