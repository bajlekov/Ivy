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

local draw = {}

local style = require "ui.style"

local drawElem = require "ui.elem.draw"

function draw.empty(frame)
	frame:onDraw()
end

function draw.panel(frame)
	love.graphics.setColor(style.nodeColor)
	love.graphics.rectangle("fill", frame.x + 1, frame.y + 1, frame.w - 2, frame.h - 2, 3, 3)

	if not frame.headless then
		drawElem.title(frame.x + style.nodeBorder + 1, frame.y + style.nodeBorder + 1, frame.w - 2 * style.nodeBorder - 2, style.titleHeight - style.nodeBorder, frame.name)
	end

	-- draw elements
	if frame.elem then
		for i = 1, frame.elem.n do
			if frame.elem[i] then
				if not (frame.elem[i-1] and frame.elem[i-1].type==frame.elem[i].type) then frame.elem[i].first = true end
				if not (frame.elem[i+1] and frame.elem[i+1].type==frame.elem[i].type) then frame.elem[i].last = true end

				local x = frame.x + style.nodeBorder + 1
				local y = frame.y + style.nodeBorder + 1 + (frame.headless and 0 or style.titleHeight) + style.elemHeight * (i - 1)
				local w = frame.w - 2 * style.nodeBorder - 2
				local h = style.elemHeight - style.elemBorder
				frame.elem[i]:draw(x, y, w, h)
			end
		end
	end

	frame:onDraw()
end

function draw.statusbar(frame)
	love.graphics.setColor(style.nodeColor)
	love.graphics.rectangle("fill", frame.x + 1, frame.y + 1, frame.w - 2, frame.h - 2, 3, 3)
	local border = style.nodeBorder + 1
	love.graphics.setColor(style.gray65)
	love.graphics.rectangle("fill", frame.x + border, frame.y + border, frame.w - 2 * border, frame.h - 2 * border, 3, 3)
	love.graphics.setColor(style.elemFontColor)
	love.graphics.setFont(style.elemFont)
	love.graphics.printf(frame.leftText, frame.x + border * 2, frame.y + 4 + 1, frame.w - border * 4, "left")
	love.graphics.printf(frame.centerText, frame.x + border * 2, frame.y + 4 + 1, frame.w - border * 4, "center")
	love.graphics.printf(frame.rightText, frame.x + border * 2, frame.y + 4 + 1, frame.w - border * 4, "right")

	frame:onDraw()
end

function draw.toolbar(frame)
	love.graphics.setColor(style.nodeColor)
	love.graphics.rectangle("fill", frame.x + 1, frame.y + 1, frame.w - 2, frame.h - 2, 3, 3)

	if not frame.headless then
		drawElem.title(frame.x + style.nodeBorder + 1, frame.y + style.nodeBorder + 1, frame.w - 2 * style.nodeBorder - 2, style.titleHeight - style.nodeBorder, frame.name)
	end

	if frame.elem then
		for i = 1, frame.elem.n do
			if frame.elem[i] then
				if not (frame.elem[i-1] and frame.elem[i-1].type==frame.elem[i].type) then frame.elem[i].first = true end
				if not (frame.elem[i+1] and frame.elem[i+1].type==frame.elem[i].type) then frame.elem[i].last = true end

				local x = frame.x + style.nodeBorder + 1 + (style.nodeWidth+1) * (i - 1)
				local y = frame.y + style.nodeBorder + 1 + (frame.headless and 0 or style.titleHeight)
				local w = style.nodeWidth
				local h = style.elemHeight - style.elemBorder
				frame.elem[i]:draw(x, y, w, h)
			end
		end
	end

	frame:onDraw()
end

return draw
