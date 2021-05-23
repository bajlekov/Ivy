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

function math.round(x) return math.floor(x + 0.5) end
function math.clamp(x, min, max) return math.min(math.max(x, min), max) end

function math.erf(x)
	local a1 = 0.254829592
	local a2 = -0.284496736
	local a3 = 1.421413741
	local a4 = -1.453152027
	local a5 = 1.061405429
	local p = 0.3275911

	local sign = 1
	if x < 0 then
		sign = -1
	end
	x = math.abs(x)

	local t = 1.0 / (1.0 + p*x)
	local y = 1.0 - (((((a5*t + a4)*t) + a3)*t + a2)*t + a1) * t * math.exp(-x*x)

	return sign * y
end

function math.norm(m, s)
	s = math.max(s, 0.000001)
	return math.exp(-m^2/(2*s*s))/(math.sqrt(2*math.pi)*s)
end

do
	local i = 1

	function math.halton2()
		local f = 1
		local r = 0
		local j = i
		local n = 0
		while j > 0 do
			f = f/2
			r = r + f * (j%2)
			j = math.floor(j/2)
			n = n + 1
		end

		local h1 = r

		local f = 1
		local r = 0
		local j = i
		while j > 0 do
			f = f/3
			r = r + f * (j%3)
			j = math.floor(j/3)
		end
		local h2 = r

		i = i + 1

		return h1, h2
	end

	function math.haltonSeed(n)
		i = n or math.random(65535)
	end
end

return math
