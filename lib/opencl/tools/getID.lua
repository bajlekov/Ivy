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

local function signature(data, chain)
	chain = chain or ""
	return string.format("%s{%d_%d_%d/%d_%d_%d/%s}", chain, data.x, data.y, data.z, data.sx, data.sy, data.sz, data.cs)
end

-- TODO: get length from variable length array? or auto-generate variable length ID functions on demand
-- somewhat slower than fixed count funtions, below 0.002ms (roughly 0.0007ms vs 0.0003ms)
local function getID(...)
	local s = ""
	for k, v in ipairs({...}) do
		s = signature(v, s)
	end
	return s
end

return getID, getID2
