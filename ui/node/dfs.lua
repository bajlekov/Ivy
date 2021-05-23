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

-- directed graph depth first search for cycles
--[[

Detects cycles in DAG
Traces dependencies for nodes
Creates ordering of the nodes for linear processing

--]]

local visited
local cycles
local order

local function dfs_node(node, reverse)
	visited[node] = "gray"

	--local portDirection = reverse and "portOut" or "portIn"
	-- traverse over all connections

	if not reverse then
		for n = 0, node.elem.n do
			if node.portIn[n] and node.portIn[n].link then
				local next = node.portIn[n].link.portIn.parent
				if visited[next] == "gray" then
					table.insert(cycles, node.portIn[n].link)
				elseif not visited[next] then
					dfs_node(next, reverse)
				end
			end
		end
	else
		for n = 0, node.elem.n do
			if node.portOut[n] and node.portOut[n].link then
				for k, v in pairs(node.portOut[n].link.portOut) do
					local next = k.parent -- port's parent is the connected node
					if visited[next] == "gray" then
						table.insert(cycles, node.portOut[n].link)
					elseif not visited[next] then
						dfs_node(next, reverse)
					end
				end
			end
		end
	end

	visited[node] = "black"
	table.insert(order, node)
end

local function dfs(nodeTree, startNode, reverse)
	visited = {} -- clear visited nodes
	cycles = {}
	order = {}


	if startNode and type(startNode) == "table" then -- find dependencies multiple nodes
		for k, v in ipairs(startNode) do
			dfs_node(v, reverse)
		end
		return order
	elseif startNode then -- find dependencies for single node
		dfs_node(startNode, reverse)
		return order
	else -- traverse over all nodes
		for node in nodeTree.stack:traverseUp() do
			if not visited[node] then
				dfs_node(node, reverse)
			end
		end
		return cycles
	end
end

return dfs
