--[[
  Copyright (C) 2011-2018 G. Bajlekov

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

local function getSource(l, c, h)
  local source = [[
  kernel void script(global float *I, global float *O)
  {
    const int _x = get_global_id(0);
    const int _y = get_global_id(1);

    float l = $I[_x, _y, 0];
    float c = $I[_x, _y, 1];
    float h = $I[_x, _y, 2];

    float x = (float)(_x)/$$O.x$$;
    float y = (float)(_y)/$$O.y$$;

    $O[_x, _y, 0] = ]]..l..[[;
    $O[_x, _y, 1] = ]]..c..[[;
    $O[_x, _y, 2] = ]]..h..[[;
  }
  ]]

  return source
end

local dataCh = love.thread.getChannel("dataCh_scheduler")
local scriptL = "l"
local scriptC = "c"
local scriptH = "h"

local function execute()
	proc:getAllBuffers("I", "O")
	proc.buffers.I.__write = false
	proc.buffers.O.__read = false

  local _l = dataCh:demand()
  local _c = dataCh:demand()
  local _h = dataCh:demand()

  if not(_l==scriptL and _c==scriptC and _h==scriptH) then
    scriptL = _l
    scriptC = _c
    scriptH = _h

    proc:loadSourceString(getSource(scriptL, scriptC, scriptH))
  end

	proc:executeKernel("script", proc:size2D("O"))
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(getSource(scriptL, scriptC, scriptH))
	return execute
end

return init
