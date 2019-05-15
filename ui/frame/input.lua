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

local input = {}

local frame = require "ui.frame"

function input.press(mouse)
	local fr, lx, ly = frame.baseFrame:getFrame(mouse.x, mouse.y)
	mouse.lx, mouse.ly = lx, ly -- set local x, y within frame

	if mouse.button==1 then
		return true, fr:onAction(mouse)
	elseif mouse.button==2 then
		return true, fr:onContext(mouse)
	end
end

function input.hover(mouse)
	return frame.baseFrame:getFrame(mouse.x, mouse.y)
end

return input
