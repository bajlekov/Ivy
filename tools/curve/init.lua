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
local curve = {}
curve.meta = {__index = curve}

function curve:new(a, b, cyclic)
	local o = {}
	o.points = {
		{
			x = 0,
			y = a or 0
		},
		{
			x = 1,
			y = b or 1
		}
	}

	-- curve changed and needs to be recalculated
	o.recalculate = true

	-- cyclic curve
	o.cyclic = cyclic
	o.type = "bezier"

	-- cached cubic spline coefficients
	o.a = {}
	o.b = {}
	o.c = {}

	-- sampled curve cache
	o.cache = {} -- NYI

	setmetatable(o, self.meta)
	return o
end

local abs = math.abs
local limit = 0.05
local eps = 0.0001

function curve:getPt(x, y)
	for k, v in ipairs(self.points) do
		local d2 = (v.x - x)^2 + (v.y - y)^2
		if d2 < limit^2 then
			local v_next = self.points[k + 1]
			if v_next then
				local d2_next = (v_next.x - x)^2 + (v_next.y - y)^2
				if d2_next < d2 then
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
		if abs(x - v.x) <= eps then
			return k
		elseif v.x > x then
			i = k
			break
		end
	end

	table.insert(self.points, i, {x = x, y = y})
	self.recalculate = true
	return i
end

function curve:movePt(i, dx, dy)
	local x = self.points[i].x
	local y = self.points[i].y
	x = x + dx
	y = y + dy
	local xmin = i==1 and 0 or self.points[i-1].x + eps
	local xmax = i==#self.points and 1 or self.points[i+1].x - eps
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

local sampleImpl = {
	linear = require "tools.curve.linear",
	bezier = require "tools.curve.bezier",
	hermite = require "tools.curve.hermite",
	cubic = require "tools.curve.cubic",
}

function curve:sample(x)
	return sampleImpl[self.type](self, x)
end

function curve:drawPts(x, y, w, h, r)
	for k, v in ipairs(self.points) do
		love.graphics.circle("fill", x + v.x*w, y + h - v.y*h, r)
	end
end

local pts = {}
function curve:drawLines(x, y, w, h, n)
	if #pts~=n then pts = {} end

	for px = 0, n or 255 do
		local py = self:sample(px/(n or 255))
		py = math.clamp(py, 0, 1)
		pts[px*2+1] = x + px/(n or 255)*w
		pts[px*2+2] = y + h - py*h
	end

	love.graphics.line(pts)
end

return curve