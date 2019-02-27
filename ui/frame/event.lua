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

local event = {}

local style = require "ui.style"

event.onAction = {}

local function mouseOverElem(frame, mouse) -- vertical elems
	local y = frame.y + style.nodeBorder + 1 + (frame.headless and 0 or style.titleHeight)
	local h = style.elemHeight
	local i = math.floor((mouse.y - y) / h) + 1
	if frame.elem[i] then
		local x = frame.x + style.nodeBorder + 1
		local y = y + h *(i-1)
		local w = frame.w - 2*style.nodeBorder - 2
		local h = style.elemHeight - style.elemBorder
		if mouse.x>=x and mouse.x<x+w and mouse.y>=y and mouse.y<y+h then
			return frame.elem[i]
		end
	end
	return false
end

local elemInput = require "ui.elem.input"

function event.onAction.panel(frame, mouse)
	local elem = mouseOverElem(frame, mouse)
	if elem then
		return elemInput.press(elem, mouse)
	end
end


local function mouseOverElem(frame, mouse) -- horizontal elems
	local x = frame.x + style.nodeBorder + 1
	local w = style.nodeWidth + 1
	local i = math.floor((mouse.x - x) / w) + 1
	if frame.elem[i] then
		local x = x + w*(i - 1)
		local y = frame.y + style.nodeBorder + 1 + (frame.headless and 0 or style.titleHeight)
		local w = style.nodeWidth
		local h = style.elemHeight - style.elemBorder
		if mouse.x>=x and mouse.x<x+w and mouse.y>=y and mouse.y<y+h then
			return frame.elem[i]
		end
	end
  return false
end

function event.onAction.toolbar(frame, mouse)
	local elem = mouseOverElem(frame, mouse)
	if elem then
		return elemInput.press(elem, mouse)
	end
end

return event
