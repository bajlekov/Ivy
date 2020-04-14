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

local input = {}

local event = require "ui.elem.event"

local moveElem

local function releaseElemCallback(mouse)
	if event.release[moveElem.type] then
		event.release[moveElem.type](moveElem, mouse)
	end
end

local function moveElemCallback(mouse)
	if event.move[moveElem.type] then
		event.move[moveElem.type](moveElem, mouse)
	end
	return releaseElemCallback
end

function input.press(elem, mouse)
	if event.press[elem.type] then
		event.press[elem.type](elem, mouse)
	end

	moveElem = elem
	return moveElemCallback
end

return input
