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

local pt = nil
function event.press.curve(graph, mouse)
	local x = (graph.px - 2) / 146
	local y = 1 - (graph.py - 2) / 146
	pt = graph.curve:getPt(x, y)

	if not pt and mouse.button==1 then
		pt = graph.curve:addPt(x, y)
		graph:updateCurve()
	end

	if pt and mouse.button==2 then
		graph.curve:removePt(pt)
		graph:updateCurve()
	end
end

local factor = 1/146
function event.move.curve(graph, mouse)
	if mouse.button==1 and pt then
		local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
		graph.curve:movePt(pt, mouse.dx * factor * (shift and 0.1 or 1), -mouse.dy * factor * (shift and 0.1 or 1))
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
		if x < (k-0.5)/8 + 1/16 and x > (k-0.5)/8 - 1/16 and y < v + 1/16 and y > v - 1/16 then
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



function event.press.colorwheel(graph, mouse)
	if mouse.button==2 then
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


return event
