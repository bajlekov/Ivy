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

local node = require "ui.node"
--local data = require "data"
local thread = require "thread"

local t = require "ops.tools"

local dataCh = love.thread.getChannel("dataCh_scheduler")

return function(ops)
  local function scriptProcess(self)
  	self.procType = "dev"
  	local i = t.inputSourceBlack(self, 0)
    local x, y, z = i:shape()
  	local o = t.autoOutput(self, 0, x, y, z)

    if z==1 then
      o.cs = "Y"
    elseif z==3 then
      o.cs = "XYZ"
    end

  	thread.ops.script_Y({i, o}, self)
  	dataCh:push(self.elem[1].value)
  end

  function ops.scriptY(x, y)
  	local n = node:new("Script Y")
  	n:addPortIn(0, "ANY")
  	n:addPortOut(0, "ANY")
  	n:addElem("textinput", 1, "i")
  	n.process = scriptProcess
  	n:setPos(x, y)
  	return n
  end

  local function scriptProcess(self)
  	self.procType = "dev"
  	local i = t.inputSourceBlack(self, 0)
  	local o = t.autoOutput(self, 0, i:shape())
  	thread.ops.script_LRGB({i, o}, self)
  	dataCh:push(self.elem[1].value)
  	dataCh:push(self.elem[2].value)
  	dataCh:push(self.elem[3].value)
  end

  function ops.scriptRGB(x, y)
  	local n = node:new("Script RGB")
  	n:addPortIn(0, "LRGB")
  	n:addPortOut(0, "LRGB")
  	n:addElem("textinput", 1, "r")
  	n:addElem("textinput", 2, "g")
  	n:addElem("textinput", 3, "b")
  	n.process = scriptProcess
  	n:setPos(x, y)
  	return n
  end

  local function scriptProcess(self)
  	self.procType = "dev"
  	local i = t.inputSourceBlack(self, 0)
  	local o = t.autoOutput(self, 0, i:shape())
  	thread.ops.script_LAB({i, o}, self)
  	dataCh:push(self.elem[1].value)
  	dataCh:push(self.elem[2].value)
  	dataCh:push(self.elem[3].value)
  end

  function ops.scriptLAB(x, y)
  	local n = node:new("Script LAB")
  	n:addPortIn(0, "LAB")
  	n:addPortOut(0, "LAB")
  	n:addElem("textinput", 1, "l")
  	n:addElem("textinput", 2, "a")
  	n:addElem("textinput", 3, "b")
  	n.process = scriptProcess
  	n:setPos(x, y)
  	return n
  end

  local function scriptProcess(self)
  	self.procType = "dev"
  	local i = t.inputSourceBlack(self, 0)
  	local o = t.autoOutput(self, 0, i:shape())
  	thread.ops.script_LCH({i, o}, self)
  	dataCh:push(self.elem[1].value)
  	dataCh:push(self.elem[2].value)
  	dataCh:push(self.elem[3].value)
  end

  function ops.scriptLCH(x, y)
  	local n = node:new("Script LCH")
  	n:addPortIn(0, "LCH")
  	n:addPortOut(0, "LCH")
  	n:addElem("textinput", 1, "l")
  	n:addElem("textinput", 2, "c")
  	n:addElem("textinput", 3, "h")
  	n.process = scriptProcess
  	n:setPos(x, y)
  	return n
  end

end
