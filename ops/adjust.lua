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

local node = require "ui.node"
local data = require "data"
local thread = require "thread"

local t = require "ops.tools"


local function curve_slope(c)
	for i = 0, 255 do c:set(0, 0, i, i/255) end
end

local function curve_flat(c)
	for i = 0, 255 do c:set(0, 0, i, 0.5) end
end

local f = {
	LL = {"lightnessAdjust", "L", "L", "Lightness", "lightness", curve_slope},
	LC = {"lightnessAdjust", "L", "C", "Lightness", "chroma", curve_flat},
	LH = {"lightnessAdjust", "L", "H", "Lightness", "hue", curve_flat},
	CL = {"chromaAdjust", "C", "L", "Chroma", "lightness", curve_flat},
	CC = {"chromaAdjust", "C", "C", "Chroma", "chroma", curve_slope},
	CH = {"chromaAdjust", "C", "H", "Chroma", "hue", curve_flat},
	HL = {"hueAdjust", "H", "L", "Hue", "lightness", curve_flat},
	HC = {"hueAdjust", "H", "C", "Hue", "chroma", curve_flat},
	HH = {"hueAdjust", "H", "H", "Hue", "hue", curve_flat},
}

return function(ops)

	for k, v in pairs(f) do

		local function process(self)
			self.procType = "dev"
			local i = t.inputSourceBlack(self, 0)
			local c = self.data.curve
			local r = t.inputParam(self, 1)
			local o = t.autoOutputSink(self, 0, i:shape())

			local ox, oy, update = self.data.tweak.getOrigin()
			local dx, dy = self.data.tweak.getTweak()
			local p = t.autoTempBuffer(self, -1, 1, 1, 4) -- [x, y, dx, dy]
			local s = t.autoTempBuffer(self, -2, 1, 1, 3) -- [r, g, b]
			p:set(0, 0, 2, dx)
			p:set(0, 0, 3, dy)

			if update then
				p:set(0, 0, 0, ox)
				p:set(0, 0, 1, oy)
				p:toDevice()
				thread.ops.colorSample({i, p, s}, self)
			end

			if dy ~= 0 then
				p:set(0, 0, 2, dx)
				p:set(0, 0, 3, dy)
				p:toDevice()
				thread.ops[v[1]]({p, s, r, c}, self)
			end

			thread.ops["curve"..k]({i, c, o}, self)
		end

		ops["adjust"..k] = function(x, y)
			local n = node:new("Adjust "..v[3].."("..v[2]..")")
			n:addPortIn(0, "LCH")
			n:addPortOut(0, "LCH")
			n:addPortIn(1, "Y"):addElem("float", 1, v[4].." range", 0, 1, 0.2)

			n.data.tweak = require "tools.tweak"(false)
			n.data.tweak.toolButton(n, 2, "Adjust "..v[5])

			n.data.curve = data:new(1, 1, 256)
			v[6](n.data.curve)
			n.data.curve:toDevice()

			n.process = process
			n:setPos(x, y)
			return n
		end

	end

end
