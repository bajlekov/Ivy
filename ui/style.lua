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

local style = {}

style.nodeBorder = 2
style.nodeWidth = 100
style.titleHeight = 20
style.elemBorder = 1
style.elemHeight = 14

style.shadow = true

-- fonts
style.titleFontPath = "res/Carlito-Bold.ttf"
style.elemFontPath = "res/Carlito-Regular.ttf"
style.labelFontPath = "res/Carlito-Bold.ttf"
style.messageFontPath = "res/Cousine-Regular.ttf"
style.noticeFontPath = "res/Carlito-Bold.ttf"

local colors = {
	red = 0xf44336,
	pink = 0xe91e63,
	purple = 0x9c27b0,
	deepPurple = 0x673ab7,
	indigo = 0x3f51b5,
	blue = 0x2196f3,
	lightBlue = 0x03a9f4,
	cyan = 0x00bcd4,
	teal = 0x009688,
	green = 0x4caf50,
	lightGreen = 0x8bc34a,
	lime = 0xcddc39,
	yellow = 0xffeb3b,
	amber = 0xffc107,
	orange = 0xff9800,
	deepOrange = 0xff5722,
	grey = 0x9e9e9e,
}

local bit = require "bit"

local alpha = 1.0

for k, v in pairs(colors) do
	local r, g, b
	r = bit.band(bit.rshift(v, 16), 0xff)/255
	g = bit.band(bit.rshift(v, 8), 0xff)/255
	b = bit.band(bit.rshift(v, 0), 0xff)/255
	style[k] = {r, g, b, alpha}
end


style.gray2 = {0.2, 0.2, 0.2, alpha}
style.gray3 = {0.3, 0.3, 0.3, alpha}
style.gray4 = {0.4, 0.4, 0.4, alpha}
style.gray5 = {0.5, 0.5, 0.5, alpha}
style.gray6 = {0.6, 0.6, 0.6, alpha}
style.gray65 = {0.65, 0.65, 0.65, alpha}
style.gray7 = {0.7, 0.7, 0.7, alpha}
style.gray75 = {0.75, 0.75, 0.75, alpha}
style.gray8 = {0.8, 0.8, 0.8, alpha}
style.gray9 = {0.9, 0.9, 0.9, alpha}

style.backgroundColor = style.gray2

style.shadowColor = {0, 0, 0, 0.1}
style.nodeColor = style.gray5

style.titleColor = style.gray9
style.titleFontColor = style.gray3

--style.portColor = style.gray7
style.portOnColor = style.gray9
style.portOffColor = style.gray75

style.labelColor = style.nodeColor
style.labelFontColor = style.gray9

style.elemColor = style.gray9
style.elemFontColor = style.gray3
style.elemHighlightColor = style.gray75

style.linkColor = style.portOnColor
style.linkDragColor = style.orange


-- dynamic resizing based on UI scale
function style.resize()
	style.smallFont = love.graphics.newFont(style.elemFontPath, 10*settings.scaleUI)
	style.titleFont = love.graphics.newFont(style.titleFontPath, (style.titleHeight - style.nodeBorder*3)*settings.scaleUI)
	style.elemFont = love.graphics.newFont(style.elemFontPath, (style.elemHeight - style.elemBorder*2)*settings.scaleUI)
	style.labelFont = love.graphics.newFont(style.labelFontPath, (style.elemHeight - style.elemBorder*2)*settings.scaleUI)
	style.messageFont = love.graphics.newFont(style.messageFontPath, (style.elemHeight - style.elemBorder*2)*settings.scaleUI)
	style.noticeFont = love.graphics.newFont(style.noticeFontPath, 32*settings.scaleUI)
end
style.resize()

function style.tint(c, t)
	if not t then return c end
	local r, g, b, a
	r = c[1] * 0.7 + t[1] * 0.3
	g = c[2] * 0.7 + t[2] * 0.3
	b = c[3] * 0.7 + t[3] * 0.3
	a = 1
	return r, g, b, a
end

return style
