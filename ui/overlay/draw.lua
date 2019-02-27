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

local style = require "ui.style"
local drawElem = require "ui.elem.draw"

return function(overlay)
	if not (overlay.frame and overlay.frame.visible) then
		return
	end

	if not overlay.frame.h then
		overlay.frame.h = style.elemHeight * overlay.frame.elem.n - (overlay.frame.elem.n == 0 and style.nodeBorder or style.elemBorder)
	end

	-- move if extending past edge
	-- FIXME: returne
	if overlay.frame.y + overlay.frame.h > love.graphics.getHeight() - style.nodeBorder - 1 then
		overlay.frame.y = love.graphics.getHeight() - overlay.frame.h - style.nodeBorder - 1
	end
	if overlay.frame.x + overlay.frame.w > love.graphics.getWidth() - style.nodeBorder - 1 then
		overlay.frame.x = love.graphics.getWidth() - overlay.frame.w - style.nodeBorder - 1
	end

	if overlay.frame.x < style.nodeBorder + 1 then
		overlay.frame.x = style.nodeBorder + 1
	end
	if overlay.frame.y < style.nodeBorder + 1 then
		overlay.frame.y = style.nodeBorder + 1
	end

	local x = overlay.frame.x - style.nodeBorder
	local y = overlay.frame.y - (overlay.frame.name and style.titleHeight or 0) - style.nodeBorder
	local w = overlay.frame.w + style.nodeBorder * 2
	local h = overlay.frame.h + (overlay.frame.name and style.titleHeight or 0) + style.nodeBorder * 2

	if style.shadow then
		love.graphics.setColor(style.shadowColor)
		love.graphics.rectangle("fill", x - 1, y - 1, w + 4, h + 4, 5, 5)
		love.graphics.rectangle("fill", x - 1, y - 1, w + 3, h + 3, 4, 4)
		love.graphics.rectangle("fill", x - 1, y - 1, w + 2, h + 2, 3, 3)
	end

	love.graphics.setColor(style.gray6)
	love.graphics.rectangle("fill", x, y, w, h, 3, 3)

	if overlay.frame.name then
		drawElem.title(x + style.nodeBorder, y + style.nodeBorder, overlay.frame.w, style.titleHeight - style.nodeBorder, overlay.frame.name)
	end

	if overlay.frame.elem then
		for i = 1, overlay.frame.elem.n do
			if overlay.frame.elem[i] then
				overlay.frame.elem[i].first = not (overlay.frame.elem[i - 1] and overlay.frame.elem[i - 1].type == overlay.frame.elem[i].type)
				overlay.frame.elem[i].last = not (overlay.frame.elem[i + 1] and overlay.frame.elem[i + 1].type == overlay.frame.elem[i].type)

				local x = x + style.nodeBorder
				local y = y + style.nodeBorder + (overlay.frame.name and style.titleHeight or 0) + style.elemHeight * (i - 1)
				local w = overlay.frame.w
				local h = style.elemHeight - style.elemBorder

				overlay.frame.elem[i]:draw(x, y, w, h)
			end
		end
	end
end
