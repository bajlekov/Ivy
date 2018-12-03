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

return function(ops)

	local function processHueSelect(self)
		self.procType = "dev"
		local i = t.inputSourceBlack(self, 0)
		local r = t.inputParam(self, 1)
		local o = t.autoOutputSink(self, 0, i:shape())
		local m = t.autoOutputSink(self, 4, i.x, i.y, 1)

		local ox, oy, update = self.data.tweak.getOrigin()
		local p = t.autoTempBuffer(self, - 1, 1, 1, 3) -- [x, y]
		local s = t.autoTempBuffer(self, - 2, 1, 1, 3) -- [r, g, b]
		p:set(0, 0, 0, ox)
		p:set(0, 0, 1, oy)
		p:toDevice()

		if update or self.elem[3].value then
			thread.ops.colorSample5x5({i, p, s}, self)
		end
		thread.ops.hueSelect({i, r, s, o, m}, self)
	end

	function ops.hueSelect(x, y)
		local n = node:new("Hue Select")
		n.data.tweak = require "tools.tweak"(true)
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "LCH")
		n:addPortIn(1, "Y"):addElem("float", 1, "Range", 0, 1, 0.2)
		n.data.tweak.toolButton(n, 2, "Sample hue")
		n:addElem("bool", 3, "Resample pos.", false)
		n:addPortOut(4, "Y"):addElem("text", 4, "", "Mask")
		n.process = processHueSelect
		n:setPos(x, y)
		return n
	end

	local function processChromaSelect(self)
		local i = t.inputSourceBlack(self, 0)
		local r = t.inputParam(self, 1)
		local o = t.autoOutputSink(self, 0, i:shape())
		local m = t.autoOutputSink(self, 4, i.x, i.y, 1)

		local ox, oy, update = self.data.tweak.getOrigin()
		local p = t.autoTempBuffer(self, - 1, 1, 1, 3) -- [x, y]
		local s = t.autoTempBuffer(self, - 2, 1, 1, 3) -- [r, g, b]
		p:set(0, 0, 0, ox)
		p:set(0, 0, 1, oy)
		p:toDevice()

		if update or self.elem[3].value then
			thread.ops.colorSample5x5({i, p, s}, self)
		end
		thread.ops.chromaSelect({i, r, s, o, m}, self)
	end

	function ops.chromaSelect(x, y)
		local n = node:new("Chroma Select")
		n.data.tweak = require "tools.tweak"(true)
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "LCH")
		n:addPortIn(1, "Y"):addElem("float", 1, "Range", 0, 1, 0.2)
		n.data.tweak.toolButton(n, 2, "Sample chroma")
		n:addElem("bool", 3, "Resample pos.", false)
		n:addPortOut(4, "Y"):addElem("text", 4, "", "Mask")
		n.process = processChromaSelect
		n:setPos(x, y)
		return n
	end

	local function processLightnessSelect(self)
		self.procType = "dev"
		local i = t.inputSourceBlack(self, 0)
		local r = t.inputParam(self, 1)
		local o = t.autoOutputSink(self, 0, i:shape())
		local m = t.autoOutputSink(self, 4, i.x, i.y, 1)

		local ox, oy, update = self.data.tweak.getOrigin()
		local p = t.autoTempBuffer(self, - 1, 1, 1, 3) -- [x, y]
		local s = t.autoTempBuffer(self, - 2, 1, 1, 3) -- [r, g, b]
		p:set(0, 0, 0, ox)
		p:set(0, 0, 1, oy)
		p:toDevice()

		if update or self.elem[3].value then
			thread.ops.colorSample5x5({i, p, s}, self)
		end
		thread.ops.lightnessSelect({i, r, s, o, m}, self)
	end

	function ops.lightnessSelect(x, y)
		local n = node:new("Lightness Select")
		n.data.tweak = require "tools.tweak"(true)
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "LCH")
		n:addPortIn(1, "Y"):addElem("float", 1, "Range", 0, 1, 0.2)
		n.data.tweak.toolButton(n, 2, "Sample lightness")
		n:addElem("bool", 3, "Resample pos.", false)
		n:addPortOut(4, "Y"):addElem("text", 4, "", "Mask")
		n.process = processLightnessSelect
		n:setPos(x, y)
		return n
	end

	local function processDistanceSelect(self)
		self.procType = "dev"
		local i = t.inputSourceBlack(self, 0)
		local d = t.inputParam(self, 1)
		local o = t.autoOutputSink(self, 0, i:shape())
		local m = t.autoOutputSink(self, 3, i.x, i.y, 1)

		local ox, oy = self.data.tweak.getOrigin()
		local p = t.autoTempBuffer(self, - 1, 1, 1, 3) -- [x, y, scale]
		local scale = math.min(math.max(o.x, m.x), math.max(o.y, m.y))
		p:set(0, 0, 0, ox)
		p:set(0, 0, 1, oy)
		p:set(0, 0, 2, scale)
		p:toDevice()

		thread.ops.distanceSelect({i, d, p, o, m}, self)
	end

	function ops.distanceSelect(x, y)
		local n = node:new("Distance Select")
		n.data.tweak = require "tools.tweak"(true)
		n:addPortIn(0, "LCH")
		n:addPortOut(0, "LCH")
		n:addPortIn(1, "Y"):addElem("float", 1, "Distance", 0, 1, 0.2)
		n.data.tweak.toolButton(n, 2, "Select position")
		n:addPortOut(3, "Y"):addElem("text", 3, "", "Mask")
		n.process = processDistanceSelect
		n:setPos(x, y)
		return n
	end

	local function processSmartSelect(self)
		self.procType = "dev"
		local i = t.inputSourceBlack(self, 0)
		local r = t.inputParam(self, 1)
		local d = t.inputParam(self, 2)
		local o = t.autoOutputSink(self, 0, i:shape())
		local m = t.autoOutputSink(self, 5, i.x, i.y, 1)

		local ox, oy, update = self.data.tweak.getOrigin()
		local p = t.autoTempBuffer(self, - 1, 1, 1, 3) -- [x, y, scale]
		local s = t.autoTempBuffer(self, - 2, 1, 1, 3) -- [r, g, b]
		local scale = math.min(math.max(o.x, m.x), math.max(o.y, m.y))
		p:set(0, 0, 0, ox)
		p:set(0, 0, 1, oy)
		p:set(0, 0, 2, scale)
		p:toDevice()

		if update or self.elem[4].value then
			thread.ops.colorSample5x5({i, p, s}, self)
		end
		thread.ops.smartSelect({i, r, d, p, s, o, m}, self)
	end

	function ops.smartSelect(x, y)
		local n = node:new("Smart Select")
		n.data.tweak = require "tools.tweak"(true)
		n:addPortIn(0, "LAB")
		n:addPortOut(0, "LAB")
		n:addPortIn(1, "Y"):addElem("float", 1, "Range", 0, 1, 0.2)
		n:addPortIn(2, "Y"):addElem("float", 2, "Distance", 0, 1, 0.2)
		n.data.tweak.toolButton(n, 3, "Select position")
		n:addElem("bool", 4, "Resample pos.", false)
		n:addPortOut(5, "Y"):addElem("text", 5, "", "Mask")
		n.process = processSmartSelect
		n:setPos(x, y)
		return n
	end

	local function processColorSelect(self)
		self.procType = "dev"
		local i = t.inputSourceBlack(self, 0)
		local r = t.inputParam(self, 1)
		local o = t.autoOutputSink(self, 0, i:shape())
		local m = t.autoOutputSink(self, 4, i.x, i.y, 1)

		local ox, oy, update = self.data.tweak.getOrigin()
		local p = t.autoTempBuffer(self, - 1, 1, 1, 3) -- [x, y]
		local s = t.autoTempBuffer(self, - 2, 1, 1, 3) -- [r, g, b]
		p:set(0, 0, 0, ox)
		p:set(0, 0, 1, oy)
		p:toDevice()

		if update or self.elem[3].value then
			thread.ops.colorSample5x5({i, p, s}, self)
		end
		thread.ops.colorSelect({i, r, s, o, m}, self)
		if self.portOut[5].link then
			local o = t.autoOutputSink(self, 5, 1, 1, 3)
			thread.ops._copy({s, o}, self)
		end
	end

	function ops.colorSelect(x, y)
		local n = node:new("Color Select")
		n.data.tweak = require "tools.tweak"(true)
		n:addPortIn(0, "LAB")
		n:addPortOut(0, "LAB")
		n:addPortIn(1, "Y"):addElem("float", 1, "Range", 0, 1, 0.2)
		n.data.tweak.toolButton(n, 2, "Select Color")
		n:addElem("bool", 3, "Resample pos.", false)
		n:addPortOut(4, "Y"):addElem("text", 4, "", "Mask")
		n:addPortOut(5, "LAB"):addElem("text", 5, "", "Color")
		n.process = processColorSelect
		n:setPos(x, y)
		return n
	end

end
