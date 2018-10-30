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

local event = {}

event.press = {}
event.move = {}
event.release = {}

local s = 0.05 --select distance
local function getPoint(pts, x, y, add)
	-- search nearby point
	for k, v in ipairs(pts) do
		if x < v.x + s and x > v.x - s and y < v.y + s and y > v.y - s then
			return k
		end
	end

	if add then
		-- add new point
		for k, v in ipairs(pts) do
			if v.x > x then
				table.insert(pts, k, {x = x, y = y})
				return k
			end
		end
		table.insert(pts, {x = x, y = y})
		return #pts
	end
end

local pt = nil
function event.press.curve(graph, mouse)
	pt = getPoint(graph.pts, (graph.px - 2) / 146, 1 - (graph.py - 2) / 146, mouse.button == 1)
	if pt and pt > 1 and pt < #graph.pts and mouse.button == 2 then
		table.remove(graph.pts, pt)
		graph:updateCurve()
	end
end

function event.move.curve(graph, mouse)
	if mouse.button == 1 and pt then
		local px = graph.pts[pt].x * 146 + 2
		local py = (1 - graph.pts[pt].y) * 146 + 2

		local lx = pt > 1 and (graph.pts[pt - 1].x * 146 + 2) or 2
		local hx = pt < #graph.pts and (graph.pts[pt + 1].x * 146 + 2) or 148

		local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")

		px = px + mouse.dx * (shift and 0.1 or 1)
		py = py + mouse.dy * (shift and 0.1 or 1)

		if px < lx then px = lx end
		if py < 2.5 then py = 2.5 end

		if px > hx then px = hx end
		if py > graph.h - 2.5 then py = graph.h - 2.5 end

		graph.pts[pt].x = (px - 2) / 146
		graph.pts[pt].y = 1 - (py - 2) / 146

		graph:updateCurve()
	end
end

function event.release.curve(graph, mouse)

end


local pt = nil
function event.press.equalizer(graph, mouse)
	local x, y = (graph.px - 2) / 146, 1 - (graph.py - 2) / 146

	local ch = graph.channel
	for k, v in ipairs(graph.pts[ch]) do
		if x < (k-0.5)/8 + s and x > (k-0.5)/8 - s and y < v + s and y > v - s then
			if mouse.button==1 then
				pt = k
			elseif mouse.button==2 then
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
		local ch = graph.channel
		local py = (1 - graph.pts[ch][pt]) * 146 + 2

		local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
		py = py + mouse.dy * (shift and 0.1 or 1)

		if py < 2.5 then py = 2.5 end
		if py > graph.h - 2.5 then py = graph.h - 2.5 end

		graph.pts[ch][pt] = 1 - (py - 2) / 146
	end
end


return event
