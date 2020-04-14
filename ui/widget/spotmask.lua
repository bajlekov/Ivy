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


local function spotmask(p1, p2) -- size, fall-off
	local o = {}

	local node

	local spots = {}
	-- sx, sy, dx, dy, size, falloff, intensity???

	local dragN = false
	local dragT = false

	local function findSpot(x, y)
		local w, h, s = widget.imageSize()
		for k, v in ipairs(spots) do
			-- check both source and destination
			local s2 = math.max(v.size^2, 10)
			local d2 = (v.sx*w-x*w)^2 + (v.sy*h-y*h)^2
			if d2<s2 then
				return k, "src"
			end
			local d2 = (v.dx*w-x*w)^2 + (v.dy*h-y*h)^2
			if d2<s2 then
				return k, "dst"
			end
		end
	end
	local function addSpot(sx, sy, dx, dy, size, falloff)
		size = math.clamp(size, 0, 1920)
		table.insert(spots, {
			sx = sx, sy = sy,
			dx = dx, dy = dy,
			size = size,
			falloff = falloff,
		})
		return #spots
	end
	local function removeSpot(n)
		table.remove(spots, n)
	end

	function o.getSpots()
		return spots
	end

	local function spotReleaseCallback(mouse)
		dragN = false
		dragT = false
	end
	local function spotDragCallback(mouse)
		local fx, fy = widget.frame.x, widget.frame.y
		local ix, iy = widget.imageCoord(mouse.x - fx, mouse.y - fy)
		local w, h, s = widget.imageSize()
		local x, y = ix/w, 1-iy/h

		local spot = spots[dragN]
		if dragT=="src" then
			spot.sx = x
			spot.sy = y
		elseif dragT=="dst" then
			spot.dx = x
			spot.dy = y
		end
		node.dirty = true
	end
	local function spotPressCallback(mouse)
		-- check if spot found
		local fx, fy = widget.frame.x, widget.frame.y
		local ix, iy = widget.imageCoord(mouse.x - fx, mouse.y - fy)
		local w, h, s = widget.imageSize()
		local x, y = ix/w, 1-iy/h

		local n, t = findSpot(x, y)
		if n then
			local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
			if ctrl then
				removeSpot(n)
			else
				dragN = n
				dragT = t
			end
		else
			dragN = addSpot(x, y, x, y, p1.value, p2.value)
			dragT = "src"
		end
		node.dirty = true
	end

	local function spotScrollCallback(scrollX, scrollY)
		local mx, my = love.mouse.getPosition()
		local fx, fy = widget.frame.x, widget.frame.y
		local ix, iy = widget.imageCoord(mx - fx, my - fy)
		local w, h, s = widget.imageSize()
		local x, y = ix/w, 1-iy/h

		local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
		local alt = love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")
		local n, t = findSpot(x, y)

		if n then
			if alt then
				spots[n].falloff = math.clamp(spots[n].falloff - (shift and 0.005 or 0.05) * scrollY, 0, 1)
			else
				spots[n].size = math.clamp(spots[n].size + (shift and 1 or 10) * scrollY, 0, 1920)
			end
			node.dirty = true
			return true
		else
			if p1 then
				if p2 and alt then
					p2.value = math.clamp(p2.value - (shift and 0.005 or 0.05) * scrollY, 0, 1)
				else
					p1.value = math.clamp(p1.value + (shift and 1 or 10) * scrollY, 0, 1920)
				end
			end
		end
	end

	local function setToolCallback(elem)
		if elem.value then
			node = elem.parent

			widget.mode = "spotmask"
			widget.press.spotmask = spotPressCallback
			widget.drag.spotmask = spotDragCallback
			widget.release.spotmask = spotReleaseCallback
			widget.scroll.spotmask = spotScrollCallback

			widget.cursor.spotmask = cursor.none
			widget.draw.spotmask.cursor = function(mouse)
				local x, y = love.mouse.getPosition( )

				love.graphics.setLineWidth(4)
				love.graphics.setColor(0, 0, 0, 0.3)
				love.graphics.circle("fill", x, y, 4)

				love.graphics.setLineWidth(2)
				love.graphics.setColor(style.gray9)
				love.graphics.circle("fill", x, y, 3)

				local fx, fy = widget.frame.x, widget.frame.y

				local overSpot
				do
					local ix, iy = widget.imageCoord(x - fx, y - fy)
					local w, h, s = widget.imageSize()
					overSpot = findSpot(ix/w, 1-iy/h)
				end

				local ix, iy, iw, ih = widget.imagePos() -- take into account frame offsets
				x = math.clamp(x, ix+fx, ix+iw+fx)
				y = math.clamp(y, iy+fy, iy+ih+fy)
				local _, _, scale = widget.imageSize()

				love.graphics.setScissor(ix+fx, iy+fy, iw+1, ih+1)

				local a, b, c, d, e = 0, math.pi*0.5, math.pi, math.pi*1.5, math.pi*2
				local r1, r2 = p1.value*scale, p1.value*(1-p2.value)*scale
				local w1, w2 = 0.2, 1
				love.graphics.setLineJoin("bevel")

				love.graphics.setLineWidth(2)
				love.graphics.setColor(0, 0, 0, 0.3)

				if not (dragT or overSpot) then
					love.graphics.arc("line", "open", x, y, r2, a+w2, c-w2)
					love.graphics.arc("line", "open", x, y, r2, c+w2, e-w2)

					love.graphics.arc("line", "open", x, y, r1, a+w1, c-w1)
					love.graphics.arc("line", "open", x, y, r1, c+w1, e-w1)
				end

				love.graphics.line(x+10, y, x-10, y)
				love.graphics.line(x, y+10, x, y-10)

				for k, v in ipairs(spots) do
					local sx = fx + ix + v.sx*iw
					local sy = fy + iy + v.sy*ih
					local dx = fx + ix + v.dx*iw
					local dy = fy + iy + v.dy*ih
					local s = v.size*scale
					local f = s*(1-v.falloff)

					local l = math.sqrt((sx-dx)^2 + (sy-dy)^2)
					local vx = (sx-dx)/l*s
					local vy = (sy-dy)/l*s
					love.graphics.line(dx+vx, dy+vy, sx, sy)

					love.graphics.circle("line", dx, dy, s)
					love.graphics.arc("line", "open", dx, dy, f, a+w2, c-w2)
					love.graphics.arc("line", "open", dx, dy, f, c+w2, e-w2)
					love.graphics.arc("line", "open", sx, sy, s, a+w2, b-w2)
					love.graphics.arc("line", "open", sx, sy, s, b+w2, c-w2)
					love.graphics.arc("line", "open", sx, sy, s, c+w2, d-w2)
					love.graphics.arc("line", "open", sx, sy, s, d+w2, e-w2)
				end

				love.graphics.setLineWidth(1)
				love.graphics.setColor(style.gray9)

				if not (dragT or overSpot) then
					love.graphics.arc("line", "open", x, y, r2, a+w2, c-w2)
					love.graphics.arc("line", "open", x, y, r2, c+w2, e-w2)

					love.graphics.arc("line", "open", x, y, r1, a+w1, c-w1)
					love.graphics.arc("line", "open", x, y, r1, c+w1, e-w1)
				end

				love.graphics.line(x+10, y, x-10, y)
				love.graphics.line(x, y+10, x, y-10)

				for k, v in ipairs(spots) do
					local sx = fx + ix + v.sx*iw
					local sy = fy + iy + v.sy*ih
					local dx = fx + ix + v.dx*iw
					local dy = fy + iy + v.dy*ih
					local s = v.size*scale
					local f = s*(1-v.falloff)

					local l = math.sqrt((sx-dx)^2 + (sy-dy)^2)
					local vx = (sx-dx)/l*s
					local vy = (sy-dy)/l*s
					love.graphics.line(dx+vx, dy+vy, sx, sy)

					love.graphics.circle("line", dx, dy, s)
					love.graphics.arc("line", "open", dx, dy, f, a+w2, c-w2)
					love.graphics.arc("line", "open", dx, dy, f, c+w2, e-w2)
					love.graphics.arc("line", "open", sx, sy, s, a+w2, b-w2)
					love.graphics.arc("line", "open", sx, sy, s, b+w2, c-w2)
					love.graphics.arc("line", "open", sx, sy, s, c+w2, d-w2)
					love.graphics.arc("line", "open", sx, sy, s, d+w2, e-w2)
				end

				love.graphics.setScissor()
			end

		end
	end
	function o.toolButton(node, idx, name)
		local elem = node:addElem("bool", idx, name, false)
		widget.setExclusive(elem)
		elem.onChange = setToolCallback
	end

	return o
end

return spotmask
