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

local widget = require "ui.widget"
local cursor = require "ui.cursor"
local style = require "ui.style"

local function tweak(mode, p1, p2)
	local o = {}

	local node

	local dx, dy =  0,  0
	local ox, oy = -1, -1
	local cx, cy = -1, -1

	local update = false

	local function tweakReleaseCallback()
		dx, dy = 0, 0
		widget.cursor.tweak()
	end

	local function tweakDragCallback(mouse)
		node.dirty = true
		local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
		dx = dx + (shift and mouse.dx/10 or mouse.dx)
		dy = dy + (shift and mouse.dy/10 or mouse.dy)
		update = true
		cx, cy = widget.imageCoord(mouse.lx - mouse.ox + mouse.x, mouse.ly - mouse.oy + mouse.y)
	end

	local function tweakPressCallback(mouse)
		node.dirty = true
		update = true
    dx, dy = 0, 0
    ox, oy = widget.imageCoord(mouse.lx, mouse.ly)
		cx, cy = ox, oy
		if mode=="adjust" then
			cursor.sizeV()
		end
  end
	local function tweakScrollCallback(x, y)
		if p1 then
			local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
			local alt = love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")
			if p2 and alt then
				p2.value = math.clamp(p2.value + (shift and 0.005 or 0.05) * y, 0, 1)
			else
				p1.value = math.max(p1.value + (shift and 1 or 10) * y, 0)
			end
		end
	end

	function o.getOrigin()
		return ox, oy
	end
	function o.getCurrent()
		local u = update
		update = false
		return cx, cy, u
	end
	function o.getUpdate()
		local u = update
		update = false
		return u
	end
	function o.getTweak()
		local x, y = dx, dy
		dx, dy = 0, 0
		return x, y
	end

	local function setToolCallback(elem)
		if elem.value then
			node = elem.parent

			-- dynamically register callback functions
			widget.mode = "tweak"
			widget.press.tweak = tweakPressCallback
			widget.drag.tweak = tweakDragCallback
			widget.release.tweak = tweakReleaseCallback
			widget.scroll.tweak = tweakScrollCallback

			if mode=="paint" then
				widget.cursor.tweak = cursor.none
				widget.draw.tweak.cursor = function(mouse)
					local x, y = love.mouse.getPosition( )

					love.graphics.setLineWidth(4)
					love.graphics.setColor(0, 0, 0, 0.3)
					love.graphics.circle("fill", x, y, 4)

					love.graphics.setLineWidth(2)
					love.graphics.setColor(style.gray9)
					love.graphics.circle("fill", x, y, 3)

					local fx, fy = widget.frame.x, widget.frame.y
					local ix, iy, iw, ih = widget.imagePos() -- take into account frame offsets
					x = math.clamp(x, ix+fx, ix+iw+fx)
					y = math.clamp(y, iy+fy, iy+ih+fy)

					love.graphics.setScissor(ix+fx, iy+fy, iw+1, ih+1)

					local scale = require "tools.pipeline".output.image.scale

					local a, b, c, d, e = 0, math.pi*0.5, math.pi, math.pi*1.5, math.pi*2
					local r1, r2 = p1.value*scale, p1.value*(1-p2.value)*scale
					local w1, w2 = 0.2, 1
					love.graphics.setLineJoin("bevel")

					love.graphics.setLineWidth(2)
					love.graphics.setColor(0, 0, 0, 0.3)

					love.graphics.arc("line", "open", x, y, r2, a+w2, c-w2)
					love.graphics.arc("line", "open", x, y, r2, c+w2, e-w2)

					love.graphics.arc("line", "open", x, y, r1, a+w1, c-w1)
					love.graphics.arc("line", "open", x, y, r1, c+w1, e-w1)

					love.graphics.line(x+10, y, x-10, y)
					love.graphics.line(x, y+10, x, y-10)

					love.graphics.setLineWidth(1)
					love.graphics.setColor(style.gray9)

					love.graphics.arc("line", "open", x, y, r2, a+w2, c-w2)
					love.graphics.arc("line", "open", x, y, r2, c+w2, e-w2)

					love.graphics.arc("line", "open", x, y, r1, a+w1, c-w1)
					love.graphics.arc("line", "open", x, y, r1, c+w1, e-w1)

					love.graphics.line(x+10, y, x-10, y)
					love.graphics.line(x, y+10, x, y-10)

					love.graphics.setScissor()
				end
			else
				widget.cursor.tweak = cursor.cross
				widget.draw.tweak.cursor = nil
			end

			dx, dy = 0, 0
		end
	end
	function o.toolButton(node, idx, name)
		local elem = node:addElem("bool", idx, name, false)
    widget.setExclusive(elem)
    elem.onChange = setToolCallback
	end

	return o
end

return tweak
