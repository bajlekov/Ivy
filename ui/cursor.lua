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

local cursor = {x = 0, y = 0}

love.mouse.setVisible(false)

function cursor:draw()
  ---[[
  love.graphics.setLineWidth(0.5)
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.line(self.x-5, self.y+0.5, self.x-2, self.y+0.5)
  love.graphics.line(self.x+6, self.y+0.5, self.x+3, self.y+0.5)
  love.graphics.line(self.x+0.5, self.y-5, self.x+0.5, self.y-2)
  love.graphics.line(self.x+0.5, self.y+6, self.x+0.5, self.y+3)
  --]]
end

function cursor:update(x, y)
  self.x = x
  self.y = y
end

return cursor
