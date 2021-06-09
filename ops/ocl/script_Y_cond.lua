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

local function getSource(y_cond, y_true, y_false)
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

    var o = 0.0
    if float(]]..y_cond..[[)>0.5 then
      o = ]]..y_true..[[
    else
      o = ]]..y_false..[[
    end

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
local y_cond = "true"
local y_true = "i"
local y_false = "0"

local function execute()
	local I, O = proc:getAllBuffers(2)
  local _y_cond = dataCh:demand()
  local _y_true = dataCh:demand()
  local _y_false = dataCh:demand()

  if not(_y_cond==y_cond and _y_true==y_true and _y_false==y_false) then
    y_cond = _y_cond
    y_true = _y_true
    y_false = _y_false
		proc:clearSource()
    proc:loadSourceString(getSource(y_cond, y_true, y_false))
  end

	proc:executeKernel("script", proc:size2D(O), {I, O})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(getSource(y_cond, y_true, y_false))
	return execute
end

return init
