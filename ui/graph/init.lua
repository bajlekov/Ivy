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

local graph = {}
graph.meta = {__index = graph}

function graph.new(node, w, h)
	node.graph = {
		h = h,
		w = w or node.w or style.nodeWidth,
		parent = node,
	}
	node.w = w
	setmetatable(node.graph, graph.meta)
	return node.graph
end

local draw = require "ui.graph.draw"
function graph:draw(x, y, w, h)
	draw[self.type](self, x, y, w, h)
end

local input = require "ui.graph.input"
function graph:press(x, y, mouse)
	return input.press(self, x, y, mouse)
end

-- put values in curve buffer
local function updateCurve(graph, channel, data)
	graph.parent.dirty = true
	local curve = graph.parent.data.curve
	local pts = data or graph.pts
	local channel = (channel or graph.channel or 1) - 1
	local n = #pts

	for i = 0, math.floor(pts[1].x * 255) do
		local c = pts[1].y
		curve:set(i, 0, channel, c)
	end
	for k = 2, n do
		local x1, x2 = pts[k - 1].x * 255, pts[k].x * 255
		local y1, y2 = pts[k - 1].y, pts[k].y
		for i = math.ceil(x1), math.floor(x2) do
			local c = y1 + (i - x1) / (x2 - x1) * (y2 - y1)
			curve:set(i, 0, channel, c)
		end
	end
	for i = math.ceil(pts[n].x * 255), 255 do
		local c = pts[n].y
		curve:set(i, 0, channel, c)
	end
end

function graph.curve(node, pts)
	local graph = graph.new(node, 150, 150)
	graph.type = "curve"
	graph.pts = pts or {{x = 0, y = 0}, {x = 1, y = 1}}
	updateCurve(graph, 1, graph.pts)
	graph.updateCurve = updateCurve
end

function graph.curveRGB(node)
	local graph = graph.new(node, 150, 150)
	graph.type = "curve"
	graph.ptsR = {{x = 0, y = 0}, {x = 1, y = 1}}
	graph.ptsG = {{x = 0, y = 0}, {x = 1, y = 1}}
	graph.ptsB = {{x = 0, y = 0}, {x = 1, y = 1}}

	updateCurve(graph, 1, graph.ptsR)
	updateCurve(graph, 2, graph.ptsG)
	updateCurve(graph, 3, graph.ptsB)

	graph.pts = graph.ptsR
	graph.channel = 1

	graph.updateCurve = updateCurve
	graph.setR = function()
		graph.pts = graph.ptsR
		graph.channel = 1
	end
	graph.setG = function()
		graph.pts = graph.ptsG
		graph.channel = 2
	end
	graph.setB = function()
		graph.pts = graph.ptsB
		graph.channel = 3
	end
end

function graph.equalizer(node, channels)
	channels = channels>1 and channels or 1
	local graph = graph.new(node, 150, 150)
	graph.type = "equalizer"
	graph.pts = {}
	graph.default = {}
	for i = 1, channels do
		graph.pts[i] = {0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5}
		graph.default[i] = 0.5
	end
	graph.channel = 1
end

function graph.histogram(node)
	local graph = graph.new(node, 150, 100)
	graph.type = "histogram"
end

function graph.colorwheel(node)
	local graph = graph.new(node, 100, 100)
	graph.type = "colorwheel"
	graph.x = 0
	graph.y = 0
end

function graph.waveform(node)
	local graph = graph.new(node, 150, 100)
	graph.type = "waveform"
end

function graph.colorwheelTriplet(node)
	local graph = graph.new(node, 300, 100)
	graph.type = "colorwheelTriplet"
end

function graph.preview(node)
	local graph = graph.new(node, 150, 150)
	graph.type = "preview"
end

return graph
