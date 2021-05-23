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

local event = {}
local cursor = require "ui.cursor"

event.press = {}
event.move = {}
event.release = {}

local pt = nil
function event.press.curve(graph, mouse)
	local w = graph.w
	local h = graph.h
	if graph.py < h - 20 then
		local x = (graph.px - 2) / (w - 4)
		local y = 1 - (graph.py - 2) / (h - 24)

		pt = graph.curve:getPt(x, y)

		if mouse.button == 1 then
			cursor.sizeA()
			if not pt then
				pt = graph.curve:addPt(x, y)
				graph:updateCurve()
			end
		end

		if pt and mouse.button == 2 then
			graph.curve:removePt(pt)
			graph:updateCurve()
		end
		return
	end

	local p0 = 2
	local p1 = 2 + math.round((w - 4) * 0.25)
	local p2 = 2 + math.round((w - 4) * 0.50)
	local p3 = 2 + math.round((w - 4) * 0.75)
	local p4 = 2 + w - 4
	if graph.py >= h - 16 and graph.py < h - 2 then
		if graph.px >= p0 and graph.px < p1 - 1 then
			graph.curve.type = "linear"
		elseif graph.px >= p1 and graph.px < p2 then
			graph.curve.type = "bezier"
		elseif graph.px >= p2 + 1 and graph.px < p3 - 1 then
			graph.curve.type = "hermite"
		elseif graph.px >= p3 and graph.px < p4 then
			graph.curve.type = "cubic"
		end
		graph:updateCurve()
	end
end

function event.move.curve(graph, mouse)
	local factor_x = 1 / (graph.w - 4)
	local factor_y = 1 / (graph.h - 24)
	if mouse.button == 1 and pt and graph.py < graph.h - 20 then
		local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
		graph.curve:movePt(pt, mouse.dx * factor_x * (shift and 0.1 or 1), -mouse.dy * factor_y * (shift and 0.1 or 1))
		graph:updateCurve()
	end
end

function event.release.curve(graph, mouse)
	cursor.arrow()
end

local pt = nil
function event.press.equalizer(graph, mouse)
	local w = graph.w
	local h = graph.h
	local x, y = (graph.px - 2) / (w - 4), 1 - (graph.py - 2) / (h - 4)

	local ch = graph.channel
	for k, v in ipairs(graph.pts[ch]) do
		if x < (k - 0.5)/8 + 1/16 and x > (k - 0.5)/8 - 1/16 then -- and y < v + 1/16 and y > v - 1/16 then
			if mouse.button == 1 then
				cursor.sizeV()
				pt = k
			elseif mouse.button == 2 then
				graph.pts[ch][k] = graph.default[ch] or 0.5
				graph.parent.dirty = true
			end
			return
		end
	end
	pt = nil
end

function event.move.equalizer(graph, mouse)
	graph.parent.dirty = true
	if mouse.button == 1 and pt then
		local h = graph.h
		local ch = graph.channel
		local py = (1 - graph.pts[ch][pt]) * (h - 4) + 2

		local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
		py = py + mouse.dy * (shift and 0.1 or 1)

		if py < 2.5 then
			py = 2.5
		end
		if py > graph.h - 2.5 then
			py = graph.h - 2.5
		end

		graph.pts[ch][pt] = 1 - (py - 2) / (h - 4)
	end
end

function event.release.equalizer(graph, mouse)
	cursor.arrow()
end


function event.press.colorwheel(graph, mouse)
	if mouse.button==1 then
		cursor.sizeA()
	elseif mouse.button==2 then
		graph.x = 0
		graph.y = 0
	end
end

function event.move.colorwheel(graph, mouse)
	graph.parent.dirty = true
	if mouse.button == 1 then
		local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
		local x, y = graph.x, graph.y
		x = x + mouse.dx/50 * (shift and 0.1 or 1)
		y = y + mouse.dy/50 * (shift and 0.1 or 1)

		local r = math.sqrt(x^2 + y^2)
		if r>1 then
			x = x/r
			y = y/r
		end

		graph.x, graph.y = x, y
	end
end

function event.release.colorwheel(graph, mouse)
	cursor.arrow()
end

return event
