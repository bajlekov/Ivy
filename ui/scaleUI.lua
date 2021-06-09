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

-- adjust text printing and the scissor function for scale

local ___print = love.graphics.print
function love.graphics.print(a, b, c, d, ...)
    if type(b) == "number" then
        b = math.round(b * settings.scaleUI)
    end
    if type(c) == "number" then
        c = math.round(c * settings.scaleUI)
    end
    if type(d) == "number" then
        d = math.round(d * settings.scaleUI)
    end
    love.graphics.push()
    love.graphics.origin()
    ___print(a, b, c, d, ...)
    love.graphics.pop()
end

local ___printf = love.graphics.printf
function love.graphics.printf(a, b, c, d, ...)
    if type(b) == "number" then
        b = math.round(b * settings.scaleUI)
    end
    if type(c) == "number" then
        c = math.round(c * settings.scaleUI)
    end
    if type(d) == "number" then
        d = math.round(d * settings.scaleUI)
    end
    love.graphics.push()
    love.graphics.origin()
    ___printf(a, b, c, d, ...)
    love.graphics.pop()
end

local ___setScissor = love.graphics.setScissor
function love.graphics.setScissor(a, b, c, d, ...)
    if type(a) == "number" then
        a = a * settings.scaleUI
    end
    if type(b) == "number" then
        b = b * settings.scaleUI
    end
    if type(c) == "number" then
        c = c * settings.scaleUI
    end
    if type(d) == "number" then
        d = d * settings.scaleUI
    end
    ___setScissor(a, b, c, d, ...)
end
