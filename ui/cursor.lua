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

local cursor = {}

local arrow = love.mouse.getSystemCursor("arrow")
local sizeH = love.mouse.getSystemCursor("sizewe")
local sizeV = love.mouse.getSystemCursor("sizens")
local sizeA = love.mouse.getSystemCursor("sizeall")
local cross = love.mouse.getSystemCursor("crosshair")

function cursor.arrow()
  love.mouse.setVisible(true)
  love.mouse.setCursor(arrow)
end

function cursor.sizeH()
  love.mouse.setVisible(true)
  love.mouse.setCursor(sizeH)
end

function cursor.sizeV()
  love.mouse.setVisible(true)
  love.mouse.setCursor(sizeV)
end

function cursor.sizeA()
  love.mouse.setVisible(true)
  love.mouse.setCursor(sizeA)
end

function cursor.cross()
  love.mouse.setVisible(true)
  love.mouse.setCursor(cross)
end

function cursor.none()
  love.mouse.setVisible(false)
end

return cursor
