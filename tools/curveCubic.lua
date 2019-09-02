--[[
  Copyright (C) 2011-2019 G. Bajlekov

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

local curve = {}
curve.meta = {__index = curve}

function curve:new(a, b)
	local o = {}
	o.points = {
		{
			x = 0,
			y = a or 0,
		},
		{
			x = 1,
			y = b or 1,
		}
	}

	o.recalculate = true

	setmetatable(o, self.meta)
	return o
end

local limit = 0.05

local abs = math.abs

function curve:getPt(x, y)
	for k, v in ipairs(self.points) do
		local d2 = (v.x-x)^2 + (v.y-y)^2
		if d2<limit^2 then
			local v_next = self.points[k+1]
			if v_next then
				local d2_next = (v_next.x-x)^2 + (v_next.y-y)^2
				if d2_next<d2 then
					return k + 1
				else
					return k
				end
			else
				return k
			end
		end
	end
end

function curve:addPt(x, y)
	local i = #self.points + 1
	for k, v in ipairs(self.points) do
		if v.x>x then
			i = k
			break
		end
	end

	if self.points[i-1] and self.points[i] and self.points[i].x - self.points[i-1].x < 0.002 then
		return i
	end

	if self.points[i-1] and x - self.points[i-1].x < 0.01 then
		x = self.points[i-1].x + 0.001
	elseif self.points[i] and self.points[i].x - x < 0.001 then
		x = self.points[i].x - 0.001
	end

	table.insert(self.points, i, {x = x, y = y})
	self.recalculate = true
	return i
end

function curve:setPt(i, x, y)
	self.points[i].x = x
	self.points[i].y = y
	self.recalculate = true
end

function curve:movePt(i, dx, dy)
	local x = self.points[i].x
	local y = self.points[i].y
	x = x + dx
	y = y + dy
	local xmin = i==1 and 0 or self.points[i-1].x + 0.001
	local xmax = i==#self.points and 1 or self.points[i+1].x - 0.001
	if x<xmin then x = xmin end
	if x>xmax then x = xmax end
	if y<0 then y = 0 end
	if y>1 then y = 1 end
	self.points[i].x = x
	self.points[i].y = y
	self.recalculate = true
end

function curve:removePt(i)
	if #self.points>2 and i>0 and i<=#self.points then
		table.remove(self.points, i)
		self.recalculate = true
	end
end

function curve:drawPts(x, y, w, h, r)
	for k, v in ipairs(self.points) do
		love.graphics.circle("fill", x + v.x*w, y + h - v.y*h, r)
	end
end

local pts = {}
function curve:drawLines(x, y, w, h, n)
	if #pts~=n then pts = {} end

	local py = 0
	for px = 0, n or 255 do
		py = self:sample(px/(n or 255)) or py
		py = math.clamp(py, 0, 1)
		pts[px*2+1] = x + px/(n or 255)*w
		pts[px*2+2] = y + h - py*h
	end

	love.graphics.line(pts)
end


do -- implement cubic spline interpolation
--[[
adapted from:
https://kluge.in-chemnitz.de/opensource/spline/
https://github.com/ttk592/spline/
Copyright (C) 2011, 2014 Tino Kluge (ttk448 at gmail.com)
Licensed under GPL 2+
--]]

	local function lu_decompose(A)
		local n = #A.d
		for i = 1, n do -- pre-condition A
			local norm = 1/A.d[i]
			A.l[i] = A.l[i]*norm
			A.u[i] = A.u[i]*norm
			A.d[i] = 1
			A.n[i] = norm
		end
		for i = 1, n-1 do
			A.l[i+1] = A.l[i+1]/A.d[i]
			A.d[i+1] = A.d[i+1] - A.l[i+1]*A.u[i]
		end
	end

	local x = {}
	local function l_solve(A, b)
		local n = #A.d
		x[1] = 0
		for i = 2, n do
			x[i] = b[i]*A.n[i] - A.l[i]*x[i-1]
		end
		return x
	end

	local x = {}
	local function r_solve(A, b)
		local n = #A.d
		x[n] = 0
		for i = n-1, 1, -1 do
			x[i] = (b[i] - A.u[i]*x[i+1] ) / A.d[i]
		end
		return x
	end

	local function lu_solve(A, b)
	 	lu_decompose(A)
		local y = l_solve(A, b)
		local x = r_solve(A, y)
		return x
	end

	function curve:calc()
		local A = { -- banded matrix
			d = {}, -- diagonal [n, n]
			u = {}, -- upper band [n, n+1]
			l = {}, -- lower band [n, n-1]
			n = {}, -- diagonal normalization factor
		}
		local rhs = {}

		local pts = self.points
		local n = #pts
		for i= 2, n-1 do
			A.l[i] = 1/3*(pts[i].x - pts[i-1].x)
			A.d[i] = 2/3*(pts[i+1].x - pts[i-1].x)
			A.u[i] = 1/3*(pts[i+1].x - pts[i].x)
			rhs[i] = (pts[i+1].y - pts[i].y)/(pts[i+1].x - pts[i].x) - (pts[i].y - pts[i-1].y)/(pts[i].x - pts[i-1].x)
		end

		A.l[1] = 0 -- non-existent
		A.d[1] = 2
		A.u[1] = 0
		rhs[1] = 0 -- 2nd derivative value = 0

		A.u[n] = 0 -- non-existent
		A.d[n] = 2
		A.l[n] = 0
		rhs[n] = 0 -- 2nd derivative value = 0

		local a = {}
		local b = lu_solve(A, rhs)
		local c = {}
		for i = 1, n-1 do
			a[i] = 1/3 * (b[i+1] - b[i]) / (pts[i+1].x - pts[i].x)
			c[i] = (pts[i+1].y - pts[i].y) / (pts[i+1].x - pts[i].x) - 1/3 * (2*b[i] + b[i+1]) * (pts[i+1].x - pts[i].x)
		end

		local h = pts[n].x - pts[n-1].x
		a[n] = 0
		c[n] = 3*a[n-1]*h^2 + 2*b[n-1]*h + c[n-1]
		b[n] = 0

		self.a = a
		self.b = b
		self.c = c
	end

	function curve:get(x)
		local pts = self.points
		local n = #pts
		if x < pts[1].x then -- extrapolate left
			local h = x - pts[1].x
			return self.c[1]*h + pts[1].y
		elseif x > pts[n].x then -- extrapolate right
			local h = x - pts[n].x
			return self.c[n]*h + pts[n].y
		else -- interpolate
			local idx = 1
			for i = 1, n do
				if x > pts[i].x then
					idx = i
				else
					break
				end
			end
			local h = x - pts[idx].x
			return ((self.a[idx]*h + self.b[idx])*h + self.c[idx])*h + pts[idx].y
		end
	end

	function curve:sample(x)
		local ax, bx, cx
		local ay, by, cy
		local n = #self.points

		if #self.points==2 then -- linear interpolation
			ax = self.points[1].x
			cx = self.points[2].x
			local t = (x - ax)/(cx - ax)
			ay = self.points[1].y
			cy = self.points[2].y
			return ay + (cy - ay)*t
		end

		if self.recalculate then self:calc() end
		return self:get(x)
	end

end

return curve
