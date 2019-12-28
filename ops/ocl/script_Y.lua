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

local function getSource(y)
  local source = [[
  kernel script(I, O)
    const internal_x = get_global_id(0)
    const internal_y = get_global_id(1)

    var internal_i = vec(0.0)
    var i = 0.0
    if O.z==3 then
      internal_i = I[internal_x, internal_y].XYZ
      i = internal_i.y
    else
      i = I[internal_x, internal_y].Y
    end

    var x = float(internal_x)/O.x
    var y = float(internal_y)/O.y

    var o = ]]..y..[[

    if O.z==3 then
      O[internal_x, internal_y].XYZ = internal_i*(o/i)
    else
      O[internal_x, internal_y].Y = o
    end

  end
  ]]

  return source
end

local dataCh = love.thread.getChannel("dataCh_scheduler")
local scriptY = "i"

local function execute()
	local I, O = proc:getAllBuffers(2)
  local _y = dataCh:demand()

  if not(_y==scriptY) then
    scriptY = _y
		proc:clearSource()
    proc:loadSourceString(getSource(scriptY))
  end

	proc:executeKernel("script", proc:size2D(O), {I, O})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(getSource(scriptY))
	return execute
end

return init
