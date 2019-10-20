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

local unroll = require "tools.unroll"
local filter = require "tools.filter"

-- data operators
return function (data)
	function data.operator(fun)
		return function(a, b)
			local c = a:new()

			local innerFunction
			if type(a) == "table" and type(b) == "table" then
				function innerFunction(z, x, y)
					c:set(x, y, z, fun(a:get(x, y, z), b:get(x, y, z)))
				end
			elseif type(a) == "table" and type(b) == "number" then
				function innerFunction(z, x, y)
					c:set(x, y, z, fun(a:get(x, y, z), b))
				end
			elseif type(a) == "number" and type(b) == "table" then
				function innerFunction(z, x, y)
					c:set(x, y, z, fun(a, b:get(x, y, z)))
				end
			elseif type(a) == "table" and b == nil then
				function innerFunction(z, x, y)
					c:set(x, y, z, fun(a:get(x, y, z)))
				end
			else
				error("wrong argument type to operator: "..type(a)..", "..type(b))
			end

			--jit.flush(1)
			local unrolled = unroll.fixed(c.z, 2)
			for x = 0, c.x - 1 do
				for y = 0, c.y - 1 do
					unrolled(innerFunction, x, y)
				end
			end

			return c
		end
	end

	data.meta.__add = data.operator(function(a, b) return a + b end)
	data.meta.__sub = data.operator(function(a, b) return a - b end)
	data.meta.__mul = data.operator(function(a, b) return a * b end)
	data.meta.__div = data.operator(function(a, b) return a / b end)
	data.meta.__pow = data.operator(function(a, b) return a^b end)
	data.meta.__unm = data.operator(function(a) return - a end)
	data.meta.__mod = data.operator(function(a, b) return a%b end)
	-- "..", "#" "()" definition?
	-- comparisons do not work properly due to requirement to return single boolean value

	local math = math
	data.abs = data.operator(function(a) return math.abs(a) end)
	data.mod = data.operator(function(a, b) return a%b end)
	data.floor = data.operator(function(a) return math.floor(a) end)
	data.ceil = data.operator(function(a) return math.ceil(a) end)
	data.sqrt = data.operator(function(a) return math.sqrt(a) end)
	data.pow = data.operator(function(a, b) return a^b end)
	data.exp = data.operator(function(a) return math.exp(a) end)
	data.log = data.operator(function(a) return math.log(a) end)
	data.log10 = data.operator(function(a) return math.log10(a) end)
	data.deg = data.operator(function(a) return math.deg(a) end)
	data.rad = data.operator(function(a) return math.rad(a) end)
	data.sin = data.operator(function(a) return math.sin(a) end)
	data.cos = data.operator(function(a) return math.cos(a) end)
	data.tan = data.operator(function(a) return math.tan(a) end)
	data.asin = data.operator(function(a) return math.asin(a) end)
	data.acos = data.operator(function(a) return math.acos(a) end)
	data.atan = data.operator(function(a) return math.atan(a) end)
	data.atan2 = data.operator(function(a, b) return math.atan2(a, b) end)
	data.random = data.operator(function() return math.random() end)

	function data:map(fun, ...) -- z, x, y, params...
		local out = self:new()

		local unrolled = unroll.fixed(self.z, 2)
		for x = 0, self.x - 1 do
			for y = 0, self.y - 1 do
				unrolled(fun, x, y, ...)
			end
		end
	end

	function data.superSize(...) -- returns size of buffer needed to accomodate all argument buffers by broadcasting
		local buffers = {...}
		local x, y, z = 1, 1, 1
		for _, t in ipairs(buffers) do
			--assert(t.x == x or t.x == 1 or x == 1, "Incompatible x dimension")
			--assert(t.y == y or t.y == 1 or y == 1, "Incompatible y dimension")
			--assert(t.z == z or t.z == 1 or z == 1, "Incompatible z dimension")
			if t.x > x then x = t.x end
			if t.y > y then y = t.y end
			if t.z > z then z = t.z end
		end
		return x, y, z
	end

	local function separable4(self, x, y, z, f)
		local xm = math.floor(x)
		local xf = x - xm
		local ym = math.floor(y)
		local yf = y - ym

		local v00, v01, v02, v03
		local v10, v11, v12, v13
		local v20, v21, v22, v23
		local v30, v31, v32, v33
		local v

		v00 = self:get(xm - 1, ym - 1, z)
		v01 = self:get(xm - 1, ym, z)
		v02 = self:get(xm - 1, ym + 1, z)
		v03 = self:get(xm - 1, ym + 2, z)
		v10 = self:get(xm, ym - 1, z)
		v11 = self:get(xm, ym, z)
		v12 = self:get(xm, ym + 1, z)
		v13 = self:get(xm, ym + 2, z)
		v20 = self:get(xm + 1, ym - 1, z)
		v21 = self:get(xm + 1, ym, z)
		v22 = self:get(xm + 1, ym + 1, z)
		v23 = self:get(xm + 1, ym + 2, z)
		v30 = self:get(xm + 2, ym - 1, z)
		v31 = self:get(xm + 2, ym, z)
		v32 = self:get(xm + 2, ym + 1, z)
		v33 = self:get(xm + 2, ym + 2, z)

		return f(
			f(v00, v01, v02, v03, yf),
			f(v10, v11, v12, v13, yf),
			f(v20, v21, v22, v23, yf),
			f(v30, v31, v32, v33, yf),
		xf)
	end

	function data:bicubic(x, y, z)
		return separable4(self, x, y, z, filter.cubic)
	end

	function data:lanczos(x, y, z)
		return separable4(self, x, y, z, filter.lanczos)
	end

	function data:bilinear(x, y, z)
		local xm = math.floor(x)
		local xf = x - xm
		local ym = math.floor(y)
		local yf = y - ym
		local v00, v01, v10, v11, v

		v00 = self:get(xm, ym, z)
		v01 = self:get(xm, ym + 1, z)
		v10 = self:get(xm + 1, ym, z)
		v11 = self:get(xm + 1, ym + 1, z)

		return filter.linear(filter.linear(v00, v01, yf), filter.linear(v10, v11, yf), xf)
	end

	function data:nearest(x, y, z)
		x = math.floor(x + 0.5)
		y = math.floor(y + 0.5)
		return self:get(x, y, z)
	end
end
