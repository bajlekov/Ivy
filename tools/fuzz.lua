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

local oplist = nil

local ops = require "ops"
local node = require "ui.node"
local pipeline = require "tools.pipeline"

math.randomseed(os.clock())
local function gc()
	collectgarbage("collect")
end
--debug.sethook(gc, "c")

local function fuzz()
	if not oplist then -- fill list with all possible ops
		oplist = {}
		for k, v in pairs(ops) do
			if type(v)=="function" and k~="output" and k~="input" and k~="paintMaskSmart" then
				table.insert(oplist, v)
			elseif type(v)=="table" then
				for k, v in pairs(v) do
					if type(v)=="function" then
						table.insert(oplist, v)
					else
						error("Operators tree is deeper than 2 levels, extend fuzzer op scan")
					end
				end
			end
		end
	end

	love.timer.sleep(math.random()*0.1) -- sleep for a random time

	-- add random node
	if math.random()<0.1 then
		local n = oplist[math.random(#oplist)](math.random(1600)+200, math.random(800)+200)
		--local n = ops.paintMaskSmart(math.random(1600)+200, math.random(800)+200)
		n.dirty = true
	end

	-- get list of all nodes
	local nodes = {}
	for n in node.stack:traverseUp() do
		table.insert(nodes, n)
	end

	-- set random node to dirty
	for i = 1, 10 do
		local n = nodes[math.random(#nodes)]
		n.dirty = true
	end

	-- connect two random nodes
	for i = 1, 10 do
		local n1 = nodes[math.random(#nodes)]
		local p1 = n1.portOut[math.random(0, n1.elem.n)]
		local n2 = nodes[math.random(#nodes)]
		local p2 = n2.portIn[math.random(0, n2.elem.n)]
		if p1 and p2 then
			node.connect(p1, p2)
		end
	end

	-- remove link left
	do
		local n = nodes[math.random(#nodes)]
		local p = n.portOut[math.random(0, n.elem.n)]
		if p and p.link then
			p.link:remove()
		end
	end

	-- remove link right
	do
		local n = nodes[math.random(#nodes)]
		local p = n.portIn[math.random(n.elem.n)]
		if p and p.link then
			p.link:removeOutput(p)
		end
	end

	-- change values
	for i = 1, 100 do
		local n = nodes[math.random(#nodes)]
		local e = n.elem[math.random(n.elem.n)]
		if e and e.type=="float" then
			e.value = e.min + math.random()*(e.max - e.min)
		end
		if e and e.type=="int" then
			e.value = math.random(e.min, e.max)
		end
		if e and e.type=="bool" then
			e.value = not e.value
		end
	end

	-- connect random node to output
	local old = pipeline.output.portIn[0].link
	local i = 0
	repeat
		local n = nodes[math.random(#nodes)]
		local p = n.portOut[math.random(0, n.elem.n)]
		if p then
			node.connect(p, pipeline.output.portIn[0])
		end
		i = i + 1
		if i>100 then
			pipeline.output.portIn[0].link = old
			return
		end
	until pipeline.output.portIn[0].link and pipeline.output.portIn[0].link~=old

	-- remove random node
	if #nodes>10 then
		local n = nodes[math.random(#nodes)]
		if n~=pipeline.input and n~=pipeline.output then
			n:remove()
		end
	end

	collectgarbage("collect") -- run garbage collector
end

return fuzz
