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

local function getSource(r, g, b)
  local source = [[
  kernel script(I, O)
    const internal_x = get_global_id(0)
    const internal_y = get_global_id(1)

    var i = I[internal_x, internal_y]
    var r = i.r
    var g = i.g
    var b = i.b

    var x = float(internal_x)/O.x
    var y = float(internal_y)/O.y

    var out_r = ]]..r..[[
    var out_g = ]]..g..[[
    var out_b = ]]..b..[[ 

    O[internal_x, internal_y] = vec(out_r, out_g, out_b)
  end
  ]]

  return source
end

local dataCh = love.thread.getChannel("dataCh_scheduler")
local scriptR = "r"
local scriptG = "g"
local scriptB = "b"

local function execute()
  local I, O = proc:getAllBuffers(2)
  local _r = dataCh:demand()
  local _g = dataCh:demand()
  local _b = dataCh:demand()

  if not(_r==scriptR and _g==scriptG and _b==scriptB) then
    scriptR = _r
    scriptG = _g
    scriptB = _b
		proc:clearSource()
    proc:loadSourceString(getSource(scriptR, scriptG, scriptB))
  end

	proc:executeKernel("script", proc:size2D(O), {I, O})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(getSource(scriptR, scriptG, scriptB))
	return execute
end

return init
