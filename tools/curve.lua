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

local limit = 8/146

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


function curve:drawPts(x, y, w, h)
	for k, v in ipairs(self.points) do
		love.graphics.circle("line", x + v.x*w, y + h - v.y*h, 5)
	end

	local pts = {}

	local py = 0
	for px = 0, 256 do
		py = self:sample(px/256) or py
		py = math.clamp(py, 0, 1)
		pts[px*2+1] = x + px/256*w
		pts[px*2+2] = y + h - py*h
	end

	love.graphics.setLineJoin("bevel")
	love.graphics.line(pts)
end

local function t(a, b, c, x) -- compute t at point x
	return (a - b + math.sqrt(b^2 - a * c + a * x - 2 * b * x + c * x)) / (a - 2 * b + c)
	-- FIXME: instability when b-a == c-b (a+c==2b => a-2*b+c==0)
end

local function y(a, b, c, t) -- compute y at point t
	local d = a + (b - a) * t
	local e = b + (c - b) * t
	return d + (e - d) * t
end

function curve:sample(x)
	local ax, bx, cx
	local ay, by, cy

	if #self.points==2 then -- linear interpolation
		ax = self.points[1].x
		cx = self.points[2].x
		local t = (x - ax)/(cx - ax)
		ay = self.points[1].y
		cy = self.points[2].y
		return ay + (cy - ay)*t
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

	local n = #self.points
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
