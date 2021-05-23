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

local function t(a, b, c, x) -- compute t at point x
	-- instability when b-a==c-b, use linear interpolation of x
	local v = a - 2 * b + c
	if math.abs(v) < eps then
		return (x - a) / (c - a)
	end

	return (a - b + math.sqrt(b ^ 2 - a * c + a * x - 2 * b * x + c * x)) / (a - 2 * b + c)
end

local function y(a, b, c, t) -- compute y at point t
	local d = a + (b - a) * t
	local e = b + (c - b) * t
	return d + (e - d) * t
end

local function sample(self, x)
	local ax, bx, cx
	local ay, by, cy
	local n = #self.points

	if #self.points == 1 then -- constant value
		return self.points[1].y
	end

	if self.cyclic then
		local function copy(pts, offset)
			return {
				x = pts.x + offset,
				y = pts.y
			}
		end

		-- create temporary padded points array
		local points = {}
		points[1] = copy(self.points[n - 1], -1)
		points[2] = copy(self.points[n - 0], -1)
		for i = 1, n do
			points[i + 2] = copy(self.points[i], 0)
		end
		points[n + 3] = copy(self.points[1], 1)
		points[n + 4] = copy(self.points[2], 1)
		local n = n + 4

		for i = 2, n - 1 do
			ax = (points[i - 1].x + points[i].x) / 2
			bx = points[i].x
			cx = (points[i].x + points[i + 1].x) / 2
			if x <= cx and x >= ax then
				ay = (points[i - 1].y + points[i].y) / 2
				by = points[i].y
				cy = (points[i].y + points[i + 1].y) / 2

				-- remove added points
				self.points[-1] = nil
				self.points[0] = nil
				self.points[n - 1] = nil
				self.points[n] = nil

				local t = t(ax, bx, cx, x)
				return y(ay, by, cy, t)
			end
		end
		error("For loop should be exhaustive")
	end

	if #self.points == 2 then -- linear interpolation
		ax = self.points[1].x
		cx = self.points[2].x
		local t = (x - ax) / math.max(cx - ax, eps)
		ay = self.points[1].y
		cy = self.points[2].y
		return ay + (cy - ay) * t
	end

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

	if #self.points == 3 then -- bezier interpolation of 3 points
		ax = self.points[1].x
		bx = self.points[2].x
		cx = self.points[3].x
		ay = self.points[1].y
		by = self.points[2].y
		cy = self.points[3].y
		local t = t(ax, bx, cx, x)
		return y(ay, by, cy, t)
	end

	if x < (self.points[2].x + self.points[3].x) / 2 then
		ax = self.points[1].x
		bx = self.points[2].x
		cx = (self.points[2].x + self.points[3].x) / 2
		ay = self.points[1].y
		by = self.points[2].y
		cy = (self.points[2].y + self.points[3].y) / 2
		local t = t(ax, bx, cx, x)
		return y(ay, by, cy, t)
	end

	if x > (self.points[n - 2].x + self.points[n - 1].x) / 2 then
		ax = (self.points[n - 2].x + self.points[n - 1].x) / 2
		bx = self.points[n - 1].x
		cx = self.points[n].x
		ay = (self.points[n - 2].y + self.points[n - 1].y) / 2
		by = self.points[n - 1].y
		cy = self.points[n].y
		local t = t(ax, bx, cx, x)
		return y(ay, by, cy, t)
	end

	for i = 2, n - 2 do
		ax = (self.points[i-1].x + self.points[i].x) / 2
		bx = self.points[i].x
		cx = (self.points[i].x + self.points[i+1].x) / 2
		if x <= cx and x >= ax then
			ay = (self.points[i - 1].y + self.points[i].y) / 2
			by = self.points[i].y
			cy = (self.points[i].y + self.points[i + 1].y) / 2
			local t = t(ax, bx, cx, x)
			return y(ay, by, cy, t)
		end
	end
	error("For loop should be exhaustive")
end

return sample
