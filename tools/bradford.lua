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

local function fwd(X, Y, Z)
  -- Bradford matrix:
	-- http://www.brucelindbloom.com/index.html?Eqn_ChromAdapt.html
	local L =  0.8951000*X + 0.2664000*Y - 0.1614000*Z
	local M = -0.7502000*X + 1.7135000*Y + 0.0367000*Z
	local S =  0.0389000*X - 0.0685000*Y + 1.0296000*Z

  return L, M, S
end

local function inv(L, M, S)
  -- Bradford matrix:
	-- http://www.brucelindbloom.com/index.html?Eqn_ChromAdapt.html
	local X =  0.9869929*L + 0.1470543*M + 0.1599627*S
	local Y =  0.4323053*L + 0.5183603*M + 0.0492912*S
	local Z = -0.0085287*L + 0.0400428*M + 0.9684867*S

  return X, Y, Z
end

return {fwd = fwd, inv = inv}
