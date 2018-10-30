--[[
  Copyright (C) 2011-2018 G. Bajlekov

    ImageFloat is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ImageFloat is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local input = {}

local overlay = require "ui.overlay"
local style = require "ui.style"

local function mouseOverFrame(frame, x, y)
	if not frame.h then
		frame.h = style.elemHeight * frame.elem.n - (frame.elem.n == 0 and style.nodeBorder or style.elemBorder)
	end

	local xmin = frame.x - style.nodeBorder
	local ymin = frame.y - (frame.name and style.titleHeight or 0) - style.nodeBorder
	local xmax = xmin + frame.w + style.nodeBorder * 2
	local ymax = ymin + frame.h + (frame.name and style.titleHeight or 0) + style.nodeBorder * 2

	return x >= xmin and x < xmax and y >= ymin and y < ymax
end

local function mouseOverElem(frame, x, y)
	local xmin = frame.x
	local xmax = frame.x + frame.w

	if x >= xmin and x < xmax then
		local i = math.floor((y - frame.y) / style.elemHeight) + 1
		if frame.elem[i] then

			local ymin = frame.y + style.elemHeight * (i - 1)
			local ymax = ymin + style.elemHeight - style.elemBorder

			if y >= ymin and y < ymax then
				return frame.elem[i]
			end

		end
	end
	return false
end

local elemInput = require "ui.elem.input"

function input.press(mouse) --FIXME: use event system!!!
	if mouse.button == 1 and overlay.frame and overlay.frame.visible and mouseOverFrame(overlay.frame, mouse.x, mouse.y) then
		local elem = mouseOverElem(overlay.frame, mouse.x, mouse.y)
		if elem then
			return true, elemInput.press(elem, mouse)
		end
		return true
	else -- button press outside of frame -> exit menu
		if overlay.frame then overlay.frame.visible = false end
		return false
	end
	return false
end

return input
