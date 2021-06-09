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

local style = require "ui.style"

local notice = {}

function notice.blocking(text, clear)
	local scale = settings.scaleUI
	local w, h = love.window.getMode()
	w = w/scale
	h = h/scale
	love.graphics.origin()
	love.graphics.setColor(0.5, 0.5, 0.5, clear and 1.0 or 0.5)
	love.graphics.rectangle( "fill", 0, 0, w, h )
	love.graphics.scale(scale)
	love.graphics.setFont(style.noticeFont)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(text, 0, 60, w, "center")

	love.graphics.present()
end

function notice.overlay(text, color)
	local scale = settings.scaleUI
	local w, h = love.window.getMode()
	w = w/scale
	h = h/scale
	love.graphics.origin()
	love.graphics.scale(scale)
	love.graphics.setFont(style.noticeFont)

	love.graphics.setColor(color or {0.9, 0.9, 0.9, 0.6})
	love.graphics.printf(text, 0, 60, w, "center")
end

return notice
