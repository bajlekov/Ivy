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

local proc = require "lib.opencl.process".new()

local function getSource(r, g, b)
  local source = [[
  kernel void script(global float *I, global float *O)
  {
    const int _x = get_global_id(0);
    const int _y = get_global_id(1);

    float r = $I[_x, _y, 0];
    float g = $I[_x, _y, 1];
    float b = $I[_x, _y, 2];

    float x = (float)(_x)/$$O.x$$;
    float y = (float)(_y)/$$O.y$$;

    $O[_x, _y, 0] = ]]..r..[[;
    $O[_x, _y, 1] = ]]..g..[[;
    $O[_x, _y, 2] = ]]..b..[[;
  }
  ]]

  return source
end

local dataCh = love.thread.getChannel("dataCh_scheduler")
local scriptR = "r"
local scriptG = "g"
local scriptB = "b"

local function execute()
	proc:getAllBuffers("I", "O")
	proc.buffers.I.__write = false
	proc.buffers.O.__read = false

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

	proc:executeKernel("script", proc:size2D("O"))
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(getSource(scriptR, scriptG, scriptB))
	return execute
end

return init
