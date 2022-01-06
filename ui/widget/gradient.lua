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

-- expand to circular, ellipsoid, mirrored gradients

local function gradient(mode, p1, p2, p3, p4) -- x, y, a, w
	local o = {}

	local XYgrabbed = false
	local Agrabbed = false
	local Wgrabbed = false
	local function getXYpos()
		local x, y = p1.value, 1 - p2.value
		local fx, fy = widget.frame.x, widget.frame.y
		local ix, iy, iw, ih = widget.imagePos()
		x = fx + ix + x*iw
		y = fy + iy + y*ih
		return x, y
	end
	local function getApos()
		local x, y = getXYpos()
		local a = p3.value
		local dx = math.cos(a*math.pi)
		local dy = -math.sin(a*math.pi)
		x = x + dx*200
		y = y + dy*200
		return x, y, dx, dy
	end
	local function getWpos()
		local x, y = getXYpos()
		local a = p3.value
		local w = p4.value
		local dx = math.cos(a*math.pi)
		local dy = -math.sin(a*math.pi)
		x = x + dx*100
		y = y + dy*100
		a = a + 0.5
		local dx = math.cos(a*math.pi)
		local dy = -math.sin(a*math.pi)
		local _, _, s = widget.imageSize()
		x = x + dx*w*1024*s
		y = y + dy*w*1024*s
		return x, y, dx, dy
	end

	local node

	local function gradientReleaseCallback()
		widget.cursor.gradient()

		XYgrabbed = false
		Agrabbed = false
		Wgrabbed = false
	end
	local function gradientDragCallback(mouse)
		if XYgrabbed then
			local fx, fy = widget.frame.x, widget.frame.y
			local ix, iy = widget.imageCoord(mouse.x - fx, mouse.y - fy)
			local w, h = widget.imageSize()
			p1.value = ix/w
			p2.value = iy/h
			node.dirty = true
		end

		if Agrabbed then
			local x, y = getXYpos()
			p3.value = math.atan2(-mouse.y+y, mouse.x-x)/math.pi
			local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
			if ctrl then
				p3.value = math.round(p3.value*12)/12
			end
			node.dirty = true
		end

		if Wgrabbed then
			local x, y = getXYpos()
			local a = p3.value + 0.5
			local dx = math.cos(a*math.pi)
			local dy = -math.sin(a*math.pi)
			local d = (mouse.x-x)*dx + (mouse.y-y)*dy
			local _, _, s = widget.imageSize()
			p4.value = d/1024/s
			node.dirty = true
		end

	end
	local function gradientPressCallback(mouse)
		-- XY widget
		local x, y = getXYpos()
		local d2 = (x-mouse.x)^2 + (y-mouse.y)^2
		if d2<50^2 then
			cursor.sizeA()
			XYgrabbed = true
			local fx, fy = widget.frame.x, widget.frame.y
			local ix, iy = widget.imageCoord(mouse.x - fx, mouse.y - fy)
			local w, h, s = widget.imageSize()
			p1.value = ix/w/s
			p2.value = 1-iy/h/s
			node.dirty = true
		end

		local ax, ay = getApos()
		local d2 = (ax-mouse.x)^2 + (ay-mouse.y)^2
		if d2<20^2 then
			cursor.sizeV()
			Agrabbed = true
			p3.value = math.atan2(-mouse.y+y, mouse.x-x)/math.pi
			local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
			if ctrl then
				p3.value = math.round(p3.value*12)/12
			end
			node.dirty = true
		end

		local wx, wy, dx, dy = getWpos()
		local d2 = (wx-mouse.x)^2 + (wy-mouse.y)^2
		if d2<20^2 then
			cursor.sizeV()
			Wgrabbed = true
			local d = (mouse.x-x)*dx + (mouse.y-y)*dy
			p4.value = d/1024
			node.dirty = true
		end

	end
	local function gradientScrollCallback(x, y)
		p4.value = p4.value + 0.02 * y
		node.dirty = true
		return true
	end

	local function setToolCallback(elem)
		if elem.value then
			node = elem.parent

			-- dynamically register callback functions
			widget.mode = "gradient"
			widget.press.gradient = gradientPressCallback
			widget.drag.gradient = gradientDragCallback
			widget.release.gradient = gradientReleaseCallback
			widget.scroll.gradient = gradientScrollCallback

			if mode=="linear" then
				widget.cursor.gradient = cursor.arrow
				widget.draw.gradient.cursor = function(mouse)
					local fx, fy, fw, fh = widget.frame.x, widget.frame.y, widget.frame.w, widget.frame.h
					love.graphics.setScissor(fx, fy, fw, fh)

					local x, y = getXYpos()
					local ax, ay, dx, dy = getApos()
					local wx, wy = getWpos()
					local wx2, wy2 = 2*x-wx, 2*y-wy

					love.graphics.setLineWidth(3)
					love.graphics.setColor(0, 0, 0, 0.3)
					love.graphics.circle("line", x, y, 50)

					love.graphics.line(x-50*dx, y-50*dy, x-500*dx, y-500*dy)
					love.graphics.line(x+50*dx, y+50*dy, x+180*dx, y+180*dy)
					love.graphics.line(x+220*dx, y+220*dy, x+500*dx, y+500*dy)

					love.graphics.circle("line", ax, ay, 20)

					love.graphics.line(wx+20*dx, wy+20*dy, wx+50*dx, wy+50*dy)
					love.graphics.line(wx-20*dx, wy-20*dy, wx-250*dx, wy-250*dy)
					love.graphics.line(wx2+250*dx, wy2+250*dy, wx2-50*dx, wy2-50*dy)

					love.graphics.circle("line", wx, wy, 20)

					love.graphics.setLineWidth(1)
					love.graphics.setColor(style.gray9)
					love.graphics.circle("line", x, y, 50)

					love.graphics.line(x-50*dx, y-50*dy, x-500*dx, y-500*dy)
					love.graphics.line(x+50*dx, y+50*dy, x+180*dx, y+180*dy)
					love.graphics.line(x+220*dx, y+220*dy, x+500*dx, y+500*dy)

					love.graphics.circle("line", ax, ay, 20)

					love.graphics.line(wx+20*dx, wy+20*dy, wx+50*dx, wy+50*dy)
					love.graphics.line(wx-20*dx, wy-20*dy, wx-250*dx, wy-250*dy)
					love.graphics.line(wx2+250*dx, wy2+250*dy, wx2-50*dx, wy2-50*dy)

					love.graphics.circle("line", wx, wy, 20)

					love.graphics.setScissor()
				end
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

return gradient
