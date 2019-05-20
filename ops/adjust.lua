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
	LL = {"lightnessAdjust", "L", "L", "Lightness", "lightness"},
	LC = {"lightnessAdjust", "L", "C", "Lightness", "chroma"},
	LH = {"lightnessAdjust", "L", "H", "Lightness", "hue"},
	CL = {"chromaAdjust", "C", "L", "Chroma", "lightness"},
	CC = {"chromaAdjust", "C", "C", "Chroma", "chroma"},
	CH = {"chromaAdjust", "C", "H", "Chroma", "hue"},
	HL = {"hueAdjust", "H", "L", "Hue", "lightness"},
	HC = {"hueAdjust", "H", "C", "Hue", "chroma"},
	HH = {"hueAdjust", "H", "H", "Hue", "hue"},
}

return function(ops)

	for k, v in pairs(f) do

		local function process(self)
			self.procType = "dev"
			local i = t.inputSourceBlack(self, 0)
			local c = self.data.curve
			local r = t.inputParam(self, 1)
			local o = t.autoOutputSink(self, 0, i:shape())

			local ox, oy = self.data.tweak.getOrigin()
			local update = self.data.tweak.getUpdate()
			local dx, dy = self.data.tweak.getTweak()
			local p = t.autoTempBuffer(self, -1, 1, 1, 5) -- [x, y, dx, dy, mod]
			local s = t.autoTempBuffer(self, -2, 1, 1, 3) -- [r, g, b]
			p:set(0, 0, 2, dx)
			p:set(0, 0, 3, dy)

			if update then
				p:set(0, 0, 0, ox)
				p:set(0, 0, 1, oy)
				p:toDevice()
				thread.ops.colorSample5x5({i, p, s}, self)
			end

			if dy ~= 0 then
				local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
				local alt = love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")

				p:set(0, 0, 2, dx)
				p:set(0, 0, 3, dy)
				p:set(0, 0, 4, (ctrl and 1) or (alt and 2) or 0)
				p:toDevice()
				thread.ops[v[1]]({p, s, r, c}, self) -- allow for tweak (+), smooth (alt) and reset (ctrl)
			end

			thread.ops["curve"..k]({i, c, o}, self)
		end

		ops["adjust"..k] = function(x, y)
			local n = node:new("Adjust "..v[3].."("..v[2]..")")
			n:addPortIn(0, "LCH")
			n:addPortOut(0, "LCH")
			n:addPortIn(1, "Y"):addElem("float", 1, v[4].." range", 0, 1, 0.2)

			n.data.tweak = require "ui.widget.tweak"("adjust")
			n.data.tweak.toolButton(n, 2, "Adjust "..v[5])

			n.data.curve = data:new(1, 1, 256)
			for i = 0, 255 do n.data.curve:set(0, 0, i, 0.5) end
			n.data.curve:toDevice()

			require "ui.graph".curveView(n)

			n.process = process
			n:setPos(x, y)
			return n
		end

	end

end
