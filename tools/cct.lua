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

return function(T, tint)
	local x, y

	-- Source: ufraw https://github.com/sergiomb2/ufraw/blob/1aec313/ufraw_routines.c#L246-L294

	-- daylight illuminant
	if T<=4000 then
		x = 0.27475E9 / (T^3) - 0.98598E6 / (T^2) + 1.17444E3 / T + 0.145986
	elseif T <= 7000 then
		x = -4.6070E9 / (T^3) + 2.9678E6 / (T^2) + 0.09911E3 / T + 0.244063
	else
		x = -2.0064E9 / (T^3) + 1.9018E6 / (T^2) + 0.24748E3 / T + 0.237040
	end

	y = -3 * x^2 + 2.87 * x - 0.275

	local Y = 1
	local X = (x * Y) / y
	local Z = ((1 - x - y) * Y) / y

	Y = Y * (tint or 1)

	-- Bradford matrix:
	local L =  0.8951000*X + 0.2664000*Y - 0.1614000*Z
	local M = -0.7502000*X + 1.7135000*Y + 0.0367000*Z
	local S =  0.0389000*X - 0.0685000*Y + 1.0296000*Z

	return L, M, S
end


--[[
	// Fit for Blackbody using CIE standard observer function at 2 degrees
	xD = -1.8596e9/(T*T*T) + 1.37686e6/(T*T) + 0.360496e3/T + 0.232632;
	yD = -2.6046*xD*xD + 2.6106*xD - 0.239156;

	// Fit for Blackbody using CIE standard observer function at 10 degrees
	xD = -1.98883e9/(T*T*T) + 1.45155e6/(T*T) + 0.364774e3/T + 0.231136;
	yD = -2.35563*xD*xD + 2.39688*xD - 0.196035;
--]]

--[[
-- planckian locus:

local a, b, c, d, e, f, g, h
a = {-0.2661239e9,-3.0258469e9}
b = {-0.2343580e6, 2.1070379e6}
c = { 0.8776956e3, 0.2226347e3}
d = { 0.179910, 0.240390}
e = {-1.1063814 ,-0.9549476 , 3.0817580 }
f = {-1.34811020,-1.37418593,-5.87338670}
g = { 2.18555832, 2.09137015, 3.75112997}
h = {-0.20219683,-0.16748867,-0.37001483}
function TtoXY(T) --Planck locus
	local xt, yt, i
	i = T<=4000 and 1 or 2
	xt = a[i]/T^3 + b[i]/T^2 + c[i]/T + d[i]
	i = T<=2222 and 1 or T<=4000 and 2 or 3
	yt = e[i]*xt^3 + f[i]*xt^2 + g[i]*xt + h[i]
	return xt,yt
end

--]]
