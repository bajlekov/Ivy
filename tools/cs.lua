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

local lut = require "tools.lut"

local cs = {}

cs.SRGB = {}
cs.LRGB = {}
cs.XYZ = {}
cs.LAB = {}
cs.LCH = {}

do
	-- FIXME: re-evaluate these values, they didn't match the sRGB specs
	local a = 0.055
	local G = 2.4

	local a_1 = 1/(1+a)
	local G_1 = 1/G

	local f = ((1+a)^G*(G-1)^(G-1))/(a^(G-1)*G^G)
	local k = a/(G-1)
	local k_f = k/f
	local f_1 = 1/f

	local function LRGBtoSRGB(i)
		return i<=k_f and i*f or (a+1)*i^G_1-a
	end
	local function SRGBtoLRGB(i)
		return i<=k and i*f_1 or ((i+a)*a_1)^G
	end

	-- include out of range behavior in the look-up table to prevent branchy out of range handling
	local LRGBtoSRGB_LUT = lut.create(function(x) if x<0 then return 0 elseif x>1 then return 1 else return LRGBtoSRGB(x) end end, -1, 3, 1024*6) -- average error smaller than float machine precision
	local SRGBtoLRGB_LUT = lut.create(function(x) if x<0 then return 0 elseif x>1 then return 1 else return SRGBtoLRGB(x) end end, -1, 3, 1024*6)

	function cs.LRGB.SRGB_exact(i1, i2, i3)
		return LRGBtoSRGB(i1), i2 and LRGBtoSRGB(i2) or nil, i3 and LRGBtoSRGB(i3) or nil
	end
	function cs.SRGB.LRGB_exact(i1, i2, i3)
		return SRGBtoLRGB(i1), i2 and SRGBtoLRGB(i2) or nil, i3 and SRGBtoLRGB(i3) or nil
	end

	-- use LUT lookup version by default for speed
	function cs.LRGB.SRGB(i1, i2, i3)
		return LRGBtoSRGB_LUT(i1), i2 and LRGBtoSRGB_LUT(i2) or nil, i3 and LRGBtoSRGB_LUT(i3) or nil
	end
	function cs.SRGB.LRGB(i1, i2, i3)
		return SRGBtoLRGB_LUT(i1), i2 and SRGBtoLRGB_LUT(i2) or nil, i3 and SRGBtoLRGB_LUT(i3) or nil
	end
end

do
	-- matrix for linear sRGB with D65 whitepoint reference
	-- http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
	local M = {
		 0.4124564,  0.3575761,  0.1804375,
 	 	 0.2126729,  0.7151522,  0.0721750,
 		 0.0193339,  0.1191920,  0.9503041,
	}
	local M_1 = {
		 3.2404542, -1.5371385, -0.4985314,
		-0.9692660,  1.8760108,  0.0415560,
		 0.0556434, -0.2040259,  1.0572252,
	}
	function cs.LRGB.XYZ(r, g, b)
		local x = M[1]*r + M[2]*g + M[3]*b
		local y = M[4]*r + M[5]*g + M[6]*b
		local z = M[7]*r + M[8]*g + M[9]*b
		return x, y, z
	end
	function cs.XYZ.LRGB(x, y, z)
		local M = M_1
		local r = M[1]*x + M[2]*y + M[3]*z
		local g = M[4]*x + M[5]*y + M[6]*z
		local b = M[7]*x + M[8]*y + M[9]*z
		return r, g, b
	end
end

do
	local wp = {x = 0.31271, y = 0.32902} -- D65 2 degree observer (matching XYZ)
	wp.z = 1 - wp.x - wp.y
	wp.x = wp.x/wp.y
	wp.z = wp.z/wp.y
	wp.y = 1

	-- http://www.brucelindbloom.com/index.html?Eqn_XYZ_to_Lab.html
	-- http://www.brucelindbloom.com/index.html?Eqn_Lab_to_XYZ.html
	local e = 216/24389
	local k = 24389/27
	local function f(x) return (x>e) and (x^(1/3)) or ((k*x+16)/116) end
	local function f_1(x) return (x^3>e) and (x^3) or ((116*x-16)/k) end

	local f = lut.create(f, 0, 4, 1024*6)
	local f_1 = lut.create(f_1, 0, 4, 1024*6)

	-- functions from brucelindbloom.com
	function cs.XYZ.LAB(x, y, z)
		local fx = f(x/wp.x)
		local fy = f(y/wp.y)
		local fz = f(z/wp.z)
		local l = 1.16*fy - 0.16
		local a = 5*(fx - fy)
		local b = 2*(fy - fz)

		return l, a, b
	end
	function cs.LAB.XYZ(l, a, b)
		local fy = (l + 0.16)/1.16
		local fx = a*0.2 + fy
		local fz = fy - b*0.5

		local x = wp.x*f_1(fx)
		local y = wp.y*f_1(fy)
		local z = wp.z*f_1(fz)

		return x, y, z
	end
end

do
	local pi2 = 2*math.pi
	local pi2_1 = 1/pi2

	function cs.LAB.LCH(l, a, b)
		local c = math.sqrt(a^2+b^2)
		local h = math.atan2(b, a)
		h = h*pi2_1
		return l, c, h
	end
	function cs.LCH.LAB(l, c, h)
		h = h*pi2
		local a = c*math.cos(h)
		local b = c*math.sin(h)
		return l, a, b
	end
end

function cs.LRGB.LCH(r, g, b) return cs.LAB.LCH(cs.XYZ.LAB(cs.LRGB.XYZ(r, g, b))) end
function cs.LCH.LRGB(l, c, h) return cs.XYZ.LRGB(cs.LAB.XYZ(cs.LCH.LAB(l, c, h))) end
function cs.XYZ.LCH(x, y, z) return cs.LAB.LCH(cs.XYZ.LAB(x, y, z)) end
function cs.LCH.XYZ(l, c, h) return cs.LAB.XYZ(cs.LCH.LAB(l, c, h)) end

return cs
