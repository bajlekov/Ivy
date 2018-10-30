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

local font = love.graphics.newFont("res/Carlito-Bold.ttf", 24)

local notice = {}

function notice.blocking(text, clear)
	local w, h = love.window.getMode()
	love.graphics.origin()
	love.graphics.setColor(0.5, 0.5, 0.5, clear and 1.0 or 0.5)
	love.graphics.rectangle( "fill", 0, 0, w, h )

	love.graphics.setFont(font)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(text, 0, 60, w, "center")

	love.graphics.present()
end

function notice.overlay(text, color)
	local w, h = love.window.getMode()
	love.graphics.origin()

	love.graphics.setFont(font)
	love.graphics.setColor(color or {0.9, 0.9, 0.9, 0.6})
	love.graphics.printf(text, 0, 60, w, "center")
end

return notice
