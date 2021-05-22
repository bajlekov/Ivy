--[[
  Copyright (C) 2011-2020 G. Bajlekov

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
Copyright (C) 2011, 2014 Tino Kluge (ttk448 at gmail.com)
Licensed under GPL 2+
--]]
local function calc(self)
	self.recalculate = false

	local A = {
		-- banded matrix
		d = {}, -- diagonal [n, n]
		u = {}, -- upper band [n, n+1]
		l = {}, -- lower band [n, n-1]
		n = {} -- diagonal normalization factor
	}
	local b = {}

	local pts = self.points
	local n = #pts
	for i = 2, n - 1 do
		A.l[i] = 1 / 3 * (pts[i].x - pts[i - 1].x)
		A.d[i] = 2 / 3 * (pts[i + 1].x - pts[i - 1].x)
		A.u[i] = 1 / 3 * (pts[i + 1].x - pts[i].x)
		b[i] =
			(pts[i + 1].y - pts[i].y) / math.max(pts[i + 1].x - pts[i].x, eps) -
			(pts[i].y - pts[i - 1].y) / math.max(pts[i].x - pts[i - 1].x, eps)
	end

	if self.cyclic then
		local AF = {} -- dense matrix A
		for i = 1, n do
			AF[i] = {}
			for j = 1, n do
				AF[i][j] = 0
			end
		end
		for i = 2, n - 1 do
			AF[i][i - 1] = A.l[i]
			AF[i][i] = A.d[i]
			AF[i][i + 1] = A.u[i]
		end

		AF[1][n] = 1 / 3 * (pts[1].x - pts[n].x + 1)
		AF[1][1] = 2 / 3 * (pts[2].x - pts[n].x + 1)
		AF[1][2] = 1 / 3 * (pts[2].x - pts[1].x) + AF[1][2] -- handles 2-point cyclic spline

		AF[n][n - 1] = 1 / 3 * (pts[n].x - pts[n - 1].x)
		AF[n][n] = 2 / 3 * (pts[1].x - pts[n - 1].x + 1)
		AF[n][1] = 1 / 3 * (pts[1].x - pts[n].x + 1) + AF[n][1] -- handles 2-point cyclic spline

		b[1] =
			(pts[2].y - pts[1].y) / math.max(pts[2].x - pts[1].x, eps) -
			(pts[1].y - pts[n].y) / math.max(pts[1].x - pts[n].x + 1, eps)
		b[n] =
			(pts[1].y - pts[n].y) / math.max(pts[1].x - pts[n].x + 1, eps) -
			(pts[n].y - pts[n - 1].y) / math.max(pts[n].x - pts[n - 1].x, eps)

		local b = require "tools.curve.solve".gauss(AF, b)
	else
		A.l[1] = 0 -- non-existent
		A.d[1] = 2
		A.u[1] = 0
		b[1] = 0 -- 2nd derivative value = 0

		A.u[n] = 0 -- non-existent
		A.d[n] = 2
		A.l[n] = 0
		b[n] = 0 -- 2nd derivative value = 0

		b = require "tools.curve.solve".lu(A, b)
	end

	local a = {}
	local c = {}
	for i = 1, n - 1 do
		a[i] = 1 / 3 * (b[i + 1] - b[i]) / math.max(pts[i + 1].x - pts[i].x, eps)
		c[i] =
			(pts[i + 1].y - pts[i].y) / math.max(pts[i + 1].x - pts[i].x, eps) -
			1 / 3 * (2 * b[i] + b[i + 1]) * math.max(pts[i + 1].x - pts[i].x, eps)
	end

	if self.cyclic then
		a[n] = 1 / 3 * (b[1] - b[n]) / math.max(pts[1].x - pts[n].x + 1, eps)
		c[n] =
			(pts[1].y - pts[n].y) / math.max(pts[1].x - pts[n].x + 1, eps) -
			1 / 3 * (2 * b[n] + b[1]) * math.max(pts[1].x - pts[n].x + 1, eps)
	else
		local h = pts[n].x - pts[n - 1].x
		a[n] = 0
		c[n] = 3 * a[n - 1] * h ^ 2 + 2 * b[n - 1] * h + c[n - 1]
		b[n] = 0
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
