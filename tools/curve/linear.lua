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
local eps = 0.0001

local function sample(self, x)
	local n = #self.points

	if self.cyclic then
		if x < self.points[1].x then
			local ox = x - self.points[n].x + 1
			local dx = self.points[1].x - self.points[n].x + 1
			local dy = self.points[1].y - self.points[n].y
			return self.points[n].y + ox * dy / math.max(dx, eps)
		end

		if x > self.points[n].x then
			local ox = x - self.points[n].x
			local dx = self.points[1].x - self.points[n].x + 1
			local dy = self.points[1].y - self.points[n].y
			return self.points[n].y + ox * dy / math.max(dx, eps)
		end
	else
		if x < self.points[1].x then
			local ox = self.points[1].x - x
			local dx = self.points[2].x - self.points[1].x
			local dy = self.points[2].y - self.points[1].y
			return self.points[1].y - ox * dy / math.max(dx, eps)
		end

		if x > self.points[n].x then
			local ox = x - self.points[n].x
			local dx = self.points[n - 1].x - self.points[n].x
			local dy = self.points[n - 1].y - self.points[n].y
			return self.points[n].y + ox * dy / math.min(dx, -eps)
		end
	end

	for i = 1, n - 1 do
		if x >= self.points[i].x and x <= self.points[i + 1].x then
			local ox = x - self.points[i].x
			local dx = self.points[i + 1].x - self.points[i].x
			local dy = self.points[i + 1].y - self.points[i].y
			return self.points[i].y + ox * dy / math.max(dx, eps)
		end
	end
	error("For loop should be exhaustive")
end

return sample
