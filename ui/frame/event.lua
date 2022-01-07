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

local event = {}

local style = require "ui.style"

event.onAction = {}

local function mouseOverElem(frame, x, y) -- vertical elems
	local xmin = frame.x + style.nodeBorder + 1
	local xmax = frame.x + frame.w - style.nodeBorder - 1

	if x >= xmin and x < xmax then
		local fy = frame.y + style.nodeBorder + 1 + (frame.headless and 0 or style.titleHeight)
		local i = math.floor((y - fy) / style.elemHeight) + 1
		if frame.elem[i] then
			local ymin = fy + style.elemHeight * (i - 1)
			local ymax = ymin + style.elemHeight - style.elemBorder
			if y >= ymin and y < ymax then
				return frame.elem[i], xmin, ymin, xmax-xmin-1, ymax-ymin-1
			end
		end
	end

	return false , nil, nil
end

local elemInput = require "ui.elem.input"

function event.onAction.panel(frame, mouse)
	local elem, ex, ey, ew, eh = mouseOverElem(frame, mouse.x, mouse.y)
	if elem then
		mouse.ex = ex
		mouse.ey = ey
		mouse.ew = ew
		mouse.eh = eh
		return elemInput.press(elem, mouse)
	end
end


local function mouseOverElem(frame, x, y) -- horizontal elems
	local ymin = frame.y + style.nodeBorder + 1 + (frame.headless and 0 or style.titleHeight)
	local ymax = ymin + style.elemHeight - style.elemBorder

	if y >= ymin and y < ymax then
		local fx = frame.x + style.nodeBorder + 1
		local i = math.floor((x - fx) / (style.nodeWidth + style.elemBorder)) + 1
		if frame.elem[i] then
			local xmin = fx + (style.nodeWidth + style.elemBorder) * (i - 1)
			local xmax = xmin + style.nodeWidth
			if x >= xmin and x < xmax then
				return frame.elem[i], xmin, ymin, xmax-xmin-1, ymax-ymin-1
			end
		end
	end

	return false, nil, nil
end

function event.onAction.toolbar(frame, mouse)
	local elem, ex, ey, ew, eh = mouseOverElem(frame, mouse.x, mouse.y)
	if elem then
		mouse.ex = ex
		mouse.ey = ey
		mouse.ew = ew
		mouse.eh = eh
		return elemInput.press(elem, mouse)
	end
end

return event
