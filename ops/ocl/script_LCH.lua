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

local function getSource(l, c, h)
  local source = [[
  kernel script(I, O)
    const internal_x = get_global_id(0)
    const internal_y = get_global_id(1)

    var i = I[internal_x, internal_y]
    var l = i.l
    var c = i.c
    var h = i.h

    var x = float(internal_x)/O.x
    var y = float(internal_y)/O.y

    var out_l = ]]..l..[[
    var out_c = ]]..c..[[
    var out_h = ]]..h..[[ 

    O[internal_x, internal_y] = vec(out_l, out_c, out_h)
  end
  ]]

  return source
end

local dataCh = love.thread.getChannel("dataCh_scheduler")
local scriptL = "l"
local scriptC = "c"
local scriptH = "h"

local function execute()
  local I, O = proc:getAllBuffers(2)
  local _l = dataCh:demand()
  local _c = dataCh:demand()
  local _h = dataCh:demand()

  if not(_l==scriptL and _c==scriptC and _h==scriptH) then
    scriptL = _l
    scriptC = _c
    scriptH = _h
		proc:clearSource()
    proc:loadSourceString(getSource(scriptL, scriptC, scriptH))
  end

	proc:executeKernel("script", proc:size2D(O), {I, O})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(getSource(scriptL, scriptC, scriptH))
	return execute
end

return init
