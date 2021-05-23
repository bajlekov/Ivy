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

--[[
adapted from:
https://kluge.in-chemnitz.de/opensource/spline/
https://github.com/ttk592/spline/
Copyright (C) 2011, 2014, 2016, 2021 Tino Kluge (ttk448 at gmail.com)
Licensed under GPL 2+
--]]
local function calc(self)
	self.recalculate = false

	local pts = self.points
	local n = #pts

	local a = {}
	local b = {}
	local c = {}

	-- calculate slopes
	for i = 2, n - 1 do
		local h = math.max(pts[i + 1].x - pts[i].x, eps)
		local hl = math.max(pts[i].x - pts[i - 1].x, eps)
		c[i] = -h / (hl * (hl + h)) * pts[i - 1].y + (h - hl) / (hl * h) * pts[i].y + hl / (h * (hl + h)) * pts[i + 1].y
	end

	if self.cyclic then
		local h = math.max(pts[2].x - pts[1].x, eps)
		local hl = math.max(pts[1].x - pts[n].x + 1, eps)
		c[1] = -h / (hl * (hl + h)) * pts[n].y + (h - hl) / (hl * h) * pts[1].y + hl / (h * (hl + h)) * pts[2].y

		local h = math.max(pts[1].x - pts[n].x + 1, eps)
		local hl = math.max(pts[n].x - pts[n - 1].x, eps)
		c[n] = -h / (hl * (hl + h)) * pts[n - 1].y + (h - hl) / (hl * h) * pts[n].y + hl / (h * (hl + h)) * pts[1].y
	else
		if n==2 then
			c[1] = (pts[2].y - pts[1].y) / math.max(pts[2].x - pts[1].x, eps)
			c[2] = c[1]
		else
			-- boundary condition: 2nd derivative = 0
			c[1] = (-c[2] + 3 * (pts[2].y - pts[1].y) / math.max(pts[2].x - pts[1].x, eps)) / 2
			c[n] = (-c[n - 1] + 3 * (pts[n].y - pts[n - 1].y) / math.max(pts[n].x - pts[n - 1].x, eps)) / 2
		end
	end

	-- calculate a and b coefficients
	for i = 1, n - 1 do
		local h = math.max(pts[i + 1].x - pts[i].x, eps)
		b[i] = (3 * (pts[i + 1].y - pts[i].y) / h - (2 * c[i] + c[i + 1])) / h
		a[i] = ((c[i + 1] - c[i]) / (3 * h) - 2 / 3 * b[i]) / h
	end

	if self.cyclic then
		local h = math.max(pts[1].x - pts[n].x + 1, eps)
		b[n] = (3 * (pts[1].y - pts[n].y) / h - (2 * c[n] + c[1])) / h
		a[n] = ((c[1] - c[n]) / (3 * h) - 2 / 3 * b[n]) / h
	end

	self.a = a
	self.b = b
	self.c = c
end

local function get(self, x)
	local pts = self.points
	local n = #pts

	if self.cyclic then
		if x < pts[1].x then -- extrapolate left
			local h = x - pts[n].x + 1
			return ((self.a[n] * h + self.b[n]) * h + self.c[n]) * h + pts[n].y
		elseif x > pts[n].x then -- extrapolate right
			local h = x - pts[n].x
			return ((self.a[n] * h + self.b[n]) * h + self.c[n]) * h + pts[n].y
		end
	else
		if x < pts[1].x then -- extrapolate left
			local h = x - pts[1].x
			return self.c[1] * h + pts[1].y
		elseif x > pts[n].x then -- extrapolate right
			local h = x - pts[n].x
			return self.c[n] * h + pts[n].y
		end
	end

	-- interpolate
	local idx = 1
	for i = 1, n do
		if x > pts[i].x then
			idx = i
		else
			break
		end
	end
	local h = x - pts[idx].x
	return ((self.a[idx] * h + self.b[idx]) * h + self.c[idx]) * h + pts[idx].y
end

local function sample(self, x)
	if self.recalculate then
		calc(self)
	end
	return get(self, x)
end

return sample
