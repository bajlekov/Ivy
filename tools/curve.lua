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

	setmetatable(o, self.meta)
	return o
end

local limit = 0.05

local abs = math.abs

function curve:getPt(x, y)
	for k, v in ipairs(self.points) do
		if abs(v.x-x)<limit and abs(v.y-y)<limit then
			return k
		end
	end
	-- TODO: select closest point instead of first
end

function curve:addPt(x, y)
	local i = #self.points + 1
	for k, v in ipairs(self.points) do
		if v.x>x then
			i = k
			break
		end
	end
	table.insert(self.points, i, {x = x, y = y})
	return i
end

function curve:setPt(i, x, y)
	self.points[i].x = x
	self.points[i].y = y
end

function curve:movePt(i, dx, dy)
	local x = self.points[i].x
	local y = self.points[i].y
	x = x + dx
	y = y + dy
	local xmin = i==1 and 0 or self.points[i-1].x
	local xmax = i==#self.points and 1 or self.points[i+1].x
	if x<xmin then x = xmin end
	if x>xmax then x = xmax end
	if y<0 then y = 0 end
	if y>1 then y = 1 end
	self.points[i].x = x
	self.points[i].y = y
end

function curve:removePt(i)
	if #self.points>2 and i>0 and i<=#self.points then
		table.remove(self.points, i)
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

local function t(a, b, c, x) -- compute t at point x
	-- instability when b-a==c-b, introduce small offset
	local v = b - 0.5*(a + c)
	if abs(v)<0.00001 then
		b = b + (v<0 and -0.00001-v or 0.00001-v)
	end

	return (a - b + math.sqrt(b^2 - a * c + a * x - 2 * b * x + c * x)) / (a - 2 * b + c)
end

local function y(a, b, c, t) -- compute y at point t
	local d = a + (b - a) * t
	local e = b + (c - b) * t
	return d + (e - d) * t
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

	if x < self.points[1].x then
		if self.points[2].x - self.points[1].x<1e-5 then
			return self.points[1].y > self.points[2].y and 1 or 0
		end
		local ox = self.points[1].x - x
		local dx = self.points[2].x - self.points[1].x
		local dy = self.points[2].y - self.points[1].y
		return self.points[1].y - ox * dy / dx
	end

	if x > self.points[n].x then
		if self.points[n].x - self.points[n-1].x<1e-5 then
			return self.points[n].y > self.points[n-1].y and 1 or 0
		end
		local ox = x - self.points[n].x
		local dx = self.points[n-1].x - self.points[n].x
		local dy = self.points[n-1].y - self.points[n].y
		return self.points[n].y + ox * dy / dx
	end

	if #self.points==3 then -- bezier interpolation of 3 points
		ax = self.points[1].x
		bx = self.points[2].x
		cx = self.points[3].x
		ay = self.points[1].y
		by = self.points[2].y
		cy = self.points[3].y
		local t = t(ax, bx, cx, x)
		return y(ay, by, cy, t)
	end

	if x < (self.points[2].x + self.points[3].x)/2 then
		ax = self.points[1].x
		bx = self.points[2].x
		cx = (self.points[2].x + self.points[3].x)/2
		ay = self.points[1].y
		by = self.points[2].y
		cy = (self.points[2].y + self.points[3].y)/2
		local t = t(ax, bx, cx, x)
		return y(ay, by, cy, t)
	end

	if x > (self.points[n-2].x + self.points[n-1].x)/2 then
		ax = (self.points[n-2].x + self.points[n-1].x)/2
		bx = self.points[n-1].x
		cx = self.points[n].x
		ay = (self.points[n-2].y + self.points[n-1].y)/2
		by = self.points[n-1].y
		cy = self.points[n].y
		local t = t(ax, bx, cx, x)
		return y(ay, by, cy, t)
	end

	for i = 3, n-2 do
		ax = (self.points[i-1].x + self.points[i].x)/2
		bx = self.points[i].x
		cx = (self.points[i].x + self.points[i+1].x)/2
		if x<=cx and x>=ax then
			ay = (self.points[i-1].y + self.points[i].y)/2
			by = self.points[i].y
			cy = (self.points[i].y + self.points[i+1].y)/2
			local t = t(ax, bx, cx, x)
			return y(ay, by, cy, t)
		end
	end

end

return curve
