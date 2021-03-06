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

local style = require("ui.style")

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

local function updateCurve(graph, channel, curve)
	local data = graph.parent.data.curve
	local curve = curve or graph.curve
	local channel = (channel or graph.channel or 1) - 1

	graph.parent.dirty = true
	curve.recalculate = true

	local py = 0
	for px = 0, 255 do
		py = curve:sample(px/255) or py
		py = math.clamp(py, 0, 1)
		data:set(px, 0, channel, py)
	end
end

function graph.curve(node, a, b, c)
	local graph = graph.new(node, 200, 220)
	graph.type = "curve"
	graph.curve = require "tools.curve":new(a, b, c)
	graph.curve.parent = graph
	updateCurve(graph)
	graph.updateCurve = updateCurve
end

function graph.curveRGB(node)
	local graph = graph.new(node, 200, 220)
	graph.type = "curve"
	graph.curveR = require "tools.curve":new()
	graph.curveG = require "tools.curve":new()
	graph.curveB = require "tools.curve":new()
	graph.curveR.parent = graph
	graph.curveG.parent = graph
	graph.curveB.parent = graph
	updateCurve(graph, 1, graph.curveR)
	updateCurve(graph, 2, graph.curveG)
	updateCurve(graph, 3, graph.curveB)

	graph.curve = graph.curveR
	graph.channel = 1

	graph.updateCurve = updateCurve
	graph.setR = function()
		graph.curve = graph.curveR
		graph.channel = 1
	end
	graph.setG = function()
		graph.curve = graph.curveG
		graph.channel = 2
	end
	graph.setB = function()
		graph.curve = graph.curveB
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

function graph.curveView(node) -- same as histogram, single curve
	local graph = graph.new(node, 150, 100)
	graph.type = "curveView"
end

function graph.colorwheel(node)
	local graph = graph.new(node, 100, 100)
	graph.type = "colorwheel"
	graph.x = 0
	graph.y = 0
end

function graph.plot(node)
	local graph = graph.new(node, 150, 150)
	graph.type = "plot"
	graph.grid = {
		horizontal = false,
		vertical = false,
		cross = false,
		polar = false,
	}
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
