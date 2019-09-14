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

local process = {}

local ops = require "ops"

local node = require "ui.node"
local link = require "ui.node.link"

local serpent = require("lib.serpent")

local pipeline = require "tools.pipeline"


function process.new()
	while node.stack.top do
		node.stack:remove(node.stack.top.value)
	end

	if pipeline.input.portOut[0].link then
		pipeline.input.portOut[0].link:remove()
	end

	node.stack:add(pipeline.input)
	node.stack:add(pipeline.output)

	node.connect(pipeline.input.portOut[0], pipeline.output.portIn[0])
end


function process.load(file, append)
	if not append then process.new() end

	local process = assert(loadfile(file), "ERROR: Could not load process file")()

	if not append then
		pipeline.input.ui.x = process.nodes.input.x or 300
		pipeline.input.ui.y = process.nodes.input.y or 200
		pipeline.output.ui.x = process.nodes.output.x or 500
		pipeline.output.ui.y = process.nodes.output.y or 200
	end

	process.nodes.input.node = pipeline.input
	process.nodes.output.node = pipeline.output

	-- disable autoconnect on load
	local autoconnect = settings.nodeAutoConnect
	settings.nodeAutoConnect = false

	do
		for k, v in pairs(process.nodes) do
			if not (k=="input" or k=="output") and v.call then -- skip input and output
				local call = ops
				for i = 1, #v.call do
					call = call[v.call[i]]
				end
				assert(type(call)=="function", "ERROR: Could not recreate node, missing constructor function")
				v.node = call(v.x, v.y) -- should have an autoconnect argument?
				v.node.call = v.call
			end

			-- set elem values
			for k, e in pairs(v.elem) do
				if type(k)=="number" then
					local elem = v.node.elem[k]
					elem.value = e
					if elem.value and elem.action then
						elem.action()
					end
				end
			end

			-- curve handling
			if v.elem.graph and v.elem.graph.type=="curve" then
				v.node.graph.curve.points = v.elem.graph.pts
				if v.node.graph.curveR then v.node.graph.curveR.points = v.elem.graph.ptsR end
				if v.node.graph.curveG then v.node.graph.curveG.points = v.elem.graph.ptsG end
				if v.node.graph.curveB then v.node.graph.curveB.points = v.elem.graph.ptsB end
				v.node.graph.channel = v.elem.graph.channel

				if v.node.graph.updateCurve then
					v.node.graph:updateCurve()
					if v.node.graph.curveR then v.node.graph:updateCurve(1, v.node.graph.curveR) print("update R") end
					if v.node.graph.curveG then v.node.graph:updateCurve(2, v.node.graph.curveG) print("update G") end
					if v.node.graph.curveB then v.node.graph:updateCurve(3, v.node.graph.curveB) print("update B") end
				end
			end

			if v.elem.graph and v.elem.graph.type=="equalizer" then
				v.node.graph.pts = v.elem.graph.pts
				v.node.graph.channel = v.elem.graph.channel
			end

			if v.elem.graph and v.elem.graph.type=="colorwheel" then
				v.node.graph.x = v.elem.graph.x
				v.node.graph.y = v.elem.graph.y
			end
		end

		-- connect nodes
		local n1, p1, n2, p2
		for k, v in pairs(process.links) do

			if process.nodes[k] then
				n1 = process.nodes[k].node
			else
				break
			end
			for k, v in pairs(v) do
				p1 = n1.portOut[k]
				if not p1 then break end
				for k, v in pairs(v) do

					if not (append and k=="output") then

						if process.nodes[k] then
							n2 = process.nodes[k].node
						else
							break
						end
						for k, v in pairs(v) do
							p2 = n2.portIn[k]
							if not p2 then break end

							assert(p1)
							assert(p2)
							node.connect(p1, p2)
						end

					end
				end
			end

		end
	end

	settings.nodeAutoConnect = autoconnect
end


function process.save(name)
	local process = {}
	process.nodes = {}
	process.links = {}

	local function id(id)
		if id==pipeline.input.id then
			return "input"
		elseif id==pipeline.output.id then
			return "output"
		else
			return id
		end
	end

	local function link(n1, p1, n2, p2)
		process.links[n1] = process.links[n1] or {}
		process.links[n1][p1] = process.links[n1][p1] or {}
		process.links[n1][p1][n2] = process.links[n1][p1][n2] or {}
		process.links[n1][p1][n2][p2] = true
	end

	for t in node.stack:traverseDown() do
		assert(t.call or id(t.id)=="input" or id(t.id)=="output")
		process.nodes[id(t.id)] = {
			call = t.call,
			x = t.ui.x,
			y = t.ui.y,
			elem = {}
		}

		local e = process.nodes[id(t.id)].elem
		for i = 0, t.elem.n do
			if t.elem[i] and t.elem[i].value~=nil then
				e[i] = t.elem[i].value
			end
		end

		if t.graph then
			e.graph = {}
			e.graph.type = t.graph.type

			if t.graph.type=="curve" then
				e.graph.pts = t.graph.curve.points
				e.graph.ptsR = t.graph.curveR and t.graph.curveR.points
				e.graph.ptsG = t.graph.curveG and t.graph.curveG.points
				e.graph.ptsB = t.graph.curveB and t.graph.curveB.points
				e.graph.channel = t.graph.channel
			end

			if t.graph.type=="equalizer" then
				e.graph.pts = t.graph.pts
				e.graph.channel = t.graph.channel
			end

			if t.graph.type=="colorwheel" then
				e.graph.x = t.graph.x
				e.graph.y = t.graph.y
			end
		end

		for i = 0, t.elem.n do
			if t.portIn[i] and t.portIn[i].link then
				local n1 = id(t.portIn[i].link.portIn.parent.id)
				local p1 = t.portIn[i].link.portIn.n
				local n2 = id(t.id)
				local p2 = i
				link(n1, p1, n2, p2)
			end
		end

		for i = 0, t.elem.n do
			if t.portOut[i] and t.portOut[i].link then
				for p in pairs(t.portOut[i].link.portOut) do
					local n1 = id(t.id)
					local p1 = i
					local n2 = id(p.parent.id)
					local p2 = p.n
					link(n1, p1, n2, p2)
				end
			end
		end
	end

	local f = io.open(name, "w")
	f:write(serpent.dump(process, {indent = "  ", nocode = true}))
	f:close()
end

return process
