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

local widget = require "ui.widget"
local cursor = require "ui.cursor"
local style = require "ui.style"


local function spotmask(p1, p2, p3) -- size, fall-off, rotation
	local o = {}

	local node

	local spots = {}
	-- sx, sy, dx, dy, size, falloff, rotation

	local dragN = false
	local dragT = false

	local function SCRtoIMG(x, y)
		local fx, fy = widget.frame.x, widget.frame.y
		local ox, oy, fix, fiy = widget.imageOffset()
		local ix, iy, iw, ih = widget.imagePos()
		local _, _, scale = widget.imageSize()

		x = math.clamp(x, ix+fx, ix+iw+fx)
		y = math.clamp(y, iy+fy, iy+ih+fy)
		x = ((x-fx-ix)/scale + ox)/fix
		y = 1 - (oy-(y-fy-iy-ih)/scale)/fiy

		return x, y
	end

	local function IMGtoSCR(x, y)
		local fx, fy = widget.frame.x, widget.frame.y
		local ox, oy, fix, fiy = widget.imageOffset()
		local ix, iy, iw, ih = widget.imagePos()
		local _, _, scale = widget.imageSize()

		x = fx + ix + (x*fix-ox)*scale
		y = fy + iy + ih - ((1-y)*fiy-oy)*scale

		return x, y
	end

	local function findSpot(x, y)
		local _, _, w, h = widget.imageOffset()
		local _, _, s = widget.imageSize()
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
	local function addSpot(sx, sy, dx, dy, size, falloff, rotation)
		size = math.clamp(size, 0, 1920)
		table.insert(spots, {
			sx = sx, sy = sy,
			dx = dx, dy = dy,
			size = size,
			falloff = falloff,
			rotation = rotation,
		})
		return #spots
	end
	local function removeSpot(n)
		table.remove(spots, n)
	end

	function o.getSpots()
		return spots
	end

	function o.addSpot(...)
		local args = {...}
		return addSpot(...)
	end

	local function spotReleaseCallback(mouse)
		dragN = false
		dragT = false
	end

	local function spotDragCallback(mouse)
		local x, y = SCRtoIMG(mouse.x, mouse.y)

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
		local x, y = SCRtoIMG(mouse.x, mouse.y)
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
			dragN = addSpot(x, y, x, y, p1.value, p2.value, p3.value)
			dragT = "src"
		end
		node.dirty = true
	end

	local function spotScrollCallback(scrollX, scrollY)
		local x, y = love.mouse.getPosition()
		local n, t = findSpot(SCRtoIMG(x, y))

		local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
		local alt = love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")
		local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")

		if n then
			if ctrl then
				spots[n].rotation = spots[n].rotation - (shift and 0.005 or 0.05) * scrollY
				spots[n].rotation = spots[n].rotation - math.floor(spots[n].rotation)
			elseif alt then
				spots[n].falloff = math.clamp(spots[n].falloff - (shift and 0.005 or 0.05) * scrollY, 0, 1)
			else
				spots[n].size = math.clamp(spots[n].size + (shift and 1 or 10) * scrollY, 0, 1920)
			end
			node.dirty = true
			return true
		else
			if p1 then
				if p3 and ctrl then
					p3.value = p3.value - (shift and 0.005 or 0.05) * scrollY
					if p3.value > 1 then p3.value = p3.value - 2 end
					if p3.value < -1 then p3.value = p3.value + 2 end
				elseif p2 and alt then
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
				local overSpot = findSpot(SCRtoIMG(x, y))

				love.graphics.setLineWidth(4)
				love.graphics.setColor(0, 0, 0, 0.3)
				love.graphics.circle("fill", x, y, 4)

				love.graphics.setLineWidth(2)
				love.graphics.setColor(style.gray9)
				love.graphics.circle("fill", x, y, 3)

				local fx, fy = widget.frame.x, widget.frame.y
				local ix, iy, iw, ih = widget.imagePos() -- take into account frame offsets
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

				--love.graphics.line(x+10, y, x-10, y)
				--love.graphics.line(x, y+10, x, y-10)

				for k, v in ipairs(spots) do
					local sx, sy = IMGtoSCR(v.sx, v.sy)
					local dx, dy = IMGtoSCR(v.dx, v.dy)
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

					local r = v.rotation*math.pi*2 - math.pi*0.5
					if v.rotation>0.5 then
						love.graphics.arc("line", "open", dx, dy, s + 5, math.pi*1.5, r)
					else
						love.graphics.arc("line", "open", dx, dy, s + 5, -math.pi*0.5, r)
					end
				end

				love.graphics.setLineWidth(1)
				love.graphics.setColor(style.gray9)

				if not (dragT or overSpot) then
					love.graphics.arc("line", "open", x, y, r2, a+w2, c-w2)
					love.graphics.arc("line", "open", x, y, r2, c+w2, e-w2)

					love.graphics.arc("line", "open", x, y, r1, a+w1, c-w1)
					love.graphics.arc("line", "open", x, y, r1, c+w1, e-w1)
				end

				--love.graphics.line(x+10, y, x-10, y)
				--love.graphics.line(x, y+10, x, y-10)

				for k, v in ipairs(spots) do
					local sx, sy = IMGtoSCR(v.sx, v.sy)
					local dx, dy = IMGtoSCR(v.dx, v.dy)
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

					local r = v.rotation*math.pi*2 - math.pi*0.5
					if v.rotation>0.5 then
						love.graphics.arc("line", "open", dx, dy, s + 5, math.pi*1.5, r)
					else
						love.graphics.arc("line", "open", dx, dy, s + 5, -math.pi*0.5, r)
					end
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
