--[[
  Copyright (C) 2011-2020 G. Bajlekov

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

local input = {}

local event = require "ui.graph.event"

local moveGraph

local function releaseCallback(mouse)
	if event.release[moveGraph.type] then
		event.release[moveGraph.type](moveGraph, mouse)
	end
end

local function dragCallback(mouse)
	if event.move[moveGraph.type] then
		event.move[moveGraph.type](moveGraph, mouse)
	end
	return releaseCallback
end

function input.press(graph, x, y, mouse)
	graph.px = x
	graph.py = y

	if event.press[graph.type] then
		event.press[graph.type](graph, mouse)
	end

	moveGraph = graph
	return dragCallback
end

return input
