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

local draw = {}

local style = require("ui.style")

local function tint(c, t)
	if not t then return c end
	local r, g, b, a
	r = c[1] * 0.7 + t[1] * 0.3
	g = c[2] * 0.7 + t[2] * 0.3
	b = c[3] * 0.7 + t[3] * 0.3
	a = 1
	return r, g, b, a
end

local function drawRoundedVertical(x, y, w, h, top, bottom)
	if top then
		love.graphics.rectangle("fill", x, y, w, h - 3, 3, 3)
	else
		love.graphics.rectangle("fill", x, y, w, h - 3)
	end
	if bottom then
		love.graphics.rectangle("fill", x, y + 3, w, h - 3, 3, 3)
	else
		love.graphics.rectangle("fill", x, y + 3, w, h - 3)
	end
end

local function drawRoundedHorizontal(x, y, w, h, top, bottom)
	if top then
		love.graphics.rectangle("fill", x, y, w - 3, h, 3, 3)
	else
		love.graphics.rectangle("fill", x, y, w - 3, h)
	end
	if bottom then
		love.graphics.rectangle("fill", x + 3, y, w - 3, h, 3, 3)
	else
		love.graphics.rectangle("fill", x + 3, y, w - 3, h)
	end
end

local function drawRounded(x, y, w, h, top, bottom, horizontal)
	if horizontal then
		drawRoundedHorizontal(x, y, w, h, top, bottom)
	else
		drawRoundedVertical(x, y, w, h, top, bottom)
	end
end

function draw.label(elem, x, y, w, h)
	love.graphics.setColor(style.labelFontColor)
	love.graphics.setFont(style.labelFont)
	love.graphics.printf(elem.name, x + 2, y + 2, w - 4, "center")
	if elem.line then
		love.graphics.line(x + 0.5, y + h - 0.5, x + w - 0.5, y + h - 0.5)
	end
end

function draw.text(elem, x, y, w, h)
	love.graphics.setColor(style.labelFontColor) -- use label color for better visibility
	love.graphics.setFont(style.elemFont)
	love.graphics.printf(elem.left or "", x + 2, y + 2, w - 4, "left")
	love.graphics.printf(elem.right or "", x + 2, y + 2, w - 4, "right")
end

function draw.textinput(elem, x, y, w, h)
	love.graphics.setColor(tint(style.elemColor, elem.tint))
	drawRounded(x, y, w, h, elem.first, elem.last, elem.parent.style=="toolbar")

	love.graphics.setColor(style.elemFontColor)
	love.graphics.setFont(style.elemFont)

	local text = love.graphics.newText(style.elemFont, elem.value) -- optimize
	local textwidth = text:getWidth()
	love.graphics.setScissor( x+1, y, w-2, h)
	love.graphics.draw(text, x + w-textwidth-4, y+2)
	love.graphics.setScissor()
end

function draw.button(elem, x, y, w, h)
	love.graphics.setColor(style.elemColor)
	drawRounded(x, y, w, h, elem.first, elem.last, elem.parent.style=="toolbar")
	if elem.tint then
		love.graphics.setColor(tint(style.elemColor, elem.tint))
		drawRounded(x, y, w, h, elem.first, elem.last, elem.parent.style=="toolbar")
	end
	love.graphics.setColor(style.elemFontColor)
	love.graphics.setFont(style.elemFont)
	love.graphics.printf(elem.name, x + 2, y + 2, w - 4, "center")
	if elem.menu then
		local x1 = x + w - h + 4
		local y1 = y + 3
		local x2 = x1 + h - 8
		local y2 = y1 + h - 6
		local y3 = y1 + (h - 6) * 0.5
		love.graphics.setLineWidth(0.65)
		love.graphics.setLineJoin("none")
		-- arror
		love.graphics.line(x1 + 0.5, y1 + 0.5, x2 - 0.5, y3, x1 + 0.5, y2 - 0.5)
		love.graphics.setLineWidth(1)
	end
	if elem.dropdown then
		local x1 = x + w - h + 1
		local y1 = y + 4
		local x2 = x1 + h - 5
		local y2 = y1 + h - 8
		local x3 = (x1 + x2) * 0.5
		love.graphics.setLineWidth(0.65)
		love.graphics.setLineJoin("none")
		-- arrow
		love.graphics.line(x1, y1, x3, y2, x2, y1)
		love.graphics.setLineWidth(1)
	end
end

function draw.float(elem, x, y, w, h)
	if elem.disabled then
		love.graphics.setColor(style.elemHighlightColor)
		drawRounded(x, y, w, h, elem.first, elem.last, elem.parent.style=="toolbar")
		love.graphics.setColor(style.elemFontColor)
		love.graphics.setFont(style.elemFont)
		love.graphics.printf(elem.name, x + 2, y + 2, w - 4, "left")
	else
		love.graphics.setColor(style.elemColor)
		drawRounded(x, y, w, h, elem.first, elem.last, elem.parent.style=="toolbar")
		local p = (elem.value - elem.min) / (elem.max - elem.min)
		love.graphics.setColor(tint(style.elemHighlightColor, elem.tint))
		love.graphics.setScissor( x, y, w * p, h)
		drawRounded(x, y, w, h, elem.first, elem.last, elem.parent.style=="toolbar")
		love.graphics.setScissor( )

		love.graphics.setColor(style.elemFontColor)
		love.graphics.setFont(style.elemFont)
		love.graphics.printf(elem.name, x + 2, y + 2, w - 4, "left")
		love.graphics.printf(string.format("%.2f", elem.value), x + 2, y + 2, w - 4, "right")
	end
end

function draw.int(elem, x, y, w, h)
	love.graphics.setColor(style.elemColor)
	drawRounded(x, y, w, h, elem.first, elem.last, elem.parent.style=="toolbar")
	local p = (elem.value - elem.min) / (elem.max - elem.min)
	love.graphics.setColor(tint(style.elemHighlightColor, elem.tint))
	love.graphics.setScissor( x, y, w * p, h)
	drawRounded(x, y, w, h, elem.first, elem.last, elem.parent.style=="toolbar")
	love.graphics.setScissor( )

	love.graphics.setColor(style.elemFontColor)
	love.graphics.setFont(style.elemFont)
	--love.graphics.printf(elem.name..":", x + 2, y + 2, w/3*2 - 2, "right")
	--love.graphics.printf(string.format("%d", elem.value), x + w/3*2 + 2, y + 2, w/3 - 8, "center")
	love.graphics.printf(string.format("%s: %d", elem.name, elem.value), x + 2, y + 2, w - 4, "center")

	love.graphics.setLineWidth(0.65)
	love.graphics.setLineJoin("none")

	local x1 = x + w - h + 4
	local y1 = y + 3
	local x2 = x1 + h - 8
	local y2 = y1 + h - 6
	local y3 = y1 + (h - 6) * 0.5
	if elem.value<elem.max then
		love.graphics.line(x1 + 0.5, y1 + 0.5, x2 - 0.5, y3, x1 + 0.5, y2 - 0.5)
	end

	local x1 = x + h - 4
	local x2 = x1 - h + 8
	if elem.value>elem.min then
		love.graphics.line(x1 - 0.5, y1 + 0.5, x2 + 0.5, y3, x1 - 0.5, y2 - 0.5)
	end

	love.graphics.setLineWidth(1)
end

function draw.bool(elem, x, y, w, h)
	love.graphics.setColor(style.elemColor)
	drawRounded(x, y, w, h, elem.first, elem.last, elem.parent.style=="toolbar")
	if elem.value then
		love.graphics.setColor(tint(style.elemHighlightColor, elem.tint))
		drawRounded(x, y, w, h, elem.first, elem.last, elem.parent.style=="toolbar")

		love.graphics.setColor(style.elemFontColor)
		love.graphics.rectangle("fill", x + w - h + 2, y + 2, h - 4, h - 4, 2, 2)
	else
		if elem.tint then
			love.graphics.setColor(tint(style.elemHighlightColor, elem.tint))
			drawRounded(x, y, w, h, elem.first, elem.last, elem.parent.style=="toolbar")
		end

		love.graphics.setColor(style.elemColor)
		love.graphics.rectangle("fill", x + w - h + 2, y + 2, h - 4, h - 4, 3, 3)
		love.graphics.setColor(style.elemFontColor)
		love.graphics.setLineWidth(0.7)
		love.graphics.rectangle("line", x + w - h + 2.5, y + 2.5, h - 5, h - 5, 2, 2)
		love.graphics.setLineWidth(1)
	end

	love.graphics.setColor(style.elemFontColor)
	love.graphics.setFont(style.elemFont)
	love.graphics.printf(elem.name, x + 2, y + 2, w - 4, "left")
end

function draw.color(elem, x, y, w, h)
	love.graphics.setColor(style.elemColor)
	love.graphics.rectangle("fill", x + w - h * 3, y, h * 3, h, 3, 3)
	love.graphics.setColor(elem.value)
	love.graphics.rectangle("fill", x + w - h * 3 + 1, y + 1, h * 3 - 2, h - 2, 3, 3)

	love.graphics.setColor(style.labelFontColor)
	love.graphics.setFont(style.elemFont)
	love.graphics.printf(elem.name, x + 2, y + 2, w - 4, "left")
end

function draw.title(x, y, w, h, title)
	love.graphics.setColor(style.titleColor)
	love.graphics.rectangle("fill", x, y, w, h, 3, 3)
	love.graphics.setColor(style.titleFontColor)
	love.graphics.setFont(style.titleFont)
	love.graphics.printf(title, x + style.nodeBorder, y + 3, w - style.nodeBorder * 2, "center")
end

return draw
