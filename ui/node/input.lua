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

local input = {}

local style = require "ui.style"
local node = require "ui.node"

local nodeHeight

local function mouseOverNode(node, x, y)
	local left = next(node.portIn) and true
	local right = next(node.portOut) and true
	local w = node.w or style.nodeWidth

	nodeHeight = style.titleHeight + style.elemHeight * math.ceil(node.elem.n / node.elem.cols) - (node.elem.n == 0 and style.nodeBorder or style.elemBorder)
	local xmin = node.ui.x - style.nodeBorder - (left and style.elemHeight / 2 or 0)
	local xmax = xmin + w + style.nodeBorder * 2 + (left and style.elemHeight / 2 or 0) + (right and style.elemHeight / 2 or 0)
	local ymin = node.ui.y - style.nodeBorder
	local ymax = ymin + nodeHeight + style.nodeBorder * 2 + (node.graph and (node.graph.h + style.nodeBorder) or 0)
	return x >= xmin and x < xmax and y >= ymin and y < ymax
end

local function mouseOverTitle(node, x, y)
	local xmin = node.ui.x
	local xmax = xmin + (node.w or style.nodeWidth)
	if x >= xmin and x < xmax then
		local ymin = node.ui.y
		local ymax = ymin + style.titleHeight - style.nodeBorder
		if y >= ymin and y < ymax then
			return true
		end
	end
	return false
end

local function mouseOverGraph(node, x, y)
	local xmin = node.ui.x
	local xmax = xmin + (node.w or style.nodeWidth)
	if x >= xmin and x < xmax then
		local ymin = node.ui.y + nodeHeight + style.nodeBorder
		local ymax = ymin + node.graph.h
		if y >= ymin and y < ymax then
			return true
		end
	end
	return false
end

local function mouseOverElem(node, x, y)
	local xmin = node.ui.x
	local xmax = xmin + (node.w or style.nodeWidth)

	if x >= xmin and x < xmax then
		if node.elem.cols == 1 then
			local i = math.floor((y - node.ui.y - style.titleHeight) / style.elemHeight) + 1
			if node.elem[i] then

				local ymin = node.ui.y + style.titleHeight + style.elemHeight * (i - 1)
				local ymax = ymin + style.elemHeight - style.elemBorder

				if y >= ymin and y < ymax then
					return node.elem[i], xmin, ymin, xmax-xmin-1, ymax-ymin-1
				end

			end
		else
			assert(node.elem.cols > 1)

			local i_h = math.floor((x-xmin) * node.elem.cols / (node.w or style.nodeWidth))
			local i_v = math.floor((y - node.ui.y - style.titleHeight) / style.elemHeight)
			local i_n = i_v*node.elem.cols + i_h + 1

			if node.elem[i_n] then

				local w = (node.w or style.nodeWidth)/node.elem.cols
				local lxmin = math.floor(xmin + w * i_h + 1)
				local lxmax = math.floor(xmin + w * (i_h + 1))
				if i_h==0 then
					lxmin = xmin
				elseif i_h==node.elem.cols-1 then
					lxmax = xmax
				end

				local lymin = node.ui.y + style.titleHeight + style.elemHeight * i_v
				local lymax = lymin + style.elemHeight - style.elemBorder

				-- check for column xmin, xmax

				if y >= lymin and y < lymax and x >= lxmin and x < lxmax then
					return node.elem[i_n], lxmin, lymin, lxmax-lxmin-1, lymax-lymin-1
				end

			end
		end
	end

	return false, nil, nil
end

local function mouseOverPortIn(node, x, y)
	local xmax = node.ui.x - style.nodeBorder
	local xmin = xmax - (style.elemHeight - style.elemBorder) / 2 - 1
	if x >= xmin and x < xmax then
		if node.portIn[0] then
			local ymin = node.ui.y + style.titleHeight - style.elemHeight - style.nodeBorder + style.elemBorder
			local ymax = ymin + style.elemHeight - style.elemBorder
			if y >= ymin and y < ymax then
				return node.portIn[0]
			end
		end

		local i = math.floor((y - node.ui.y - style.titleHeight) / style.elemHeight) + 1
		if node.portIn[i] then
			local ymin = node.ui.y + style.titleHeight + style.elemHeight * (i - 1)
			local ymax = ymin + style.elemHeight - style.elemBorder
			if x >= xmin and x < xmax and y >= ymin and y < ymax then
				return node.portIn[i]
			end
		end
	end
	return false
end

local function mouseOverPortOut(node, x, y)
	local xmin = node.ui.x + (node.w or style.nodeWidth) + style.nodeBorder
	local xmax = xmin + (style.elemHeight - style.elemBorder) / 2
	if x >= xmin and x < xmax then
		if node.portOut[0] then
			local ymin = node.ui.y + style.titleHeight - style.elemHeight - style.nodeBorder + style.elemBorder
			local ymax = ymin + style.elemHeight - style.elemBorder
			if y >= ymin and y < ymax then
				return node.portOut[0]
			end
		end

		local i = math.floor((y - node.ui.y - style.titleHeight) / style.elemHeight) + 1
		if node.portOut[i] then
			local ymin = node.ui.y + style.titleHeight + style.elemHeight * (i - 1)
			local ymax = ymin + style.elemHeight - style.elemBorder
			if x >= xmin and x < xmax and y >= ymin and y < ymax then
				return node.portOut[i]
			end
		end
	end
	return false
end


local moveNode
local dx, dy, s = 0, 0, style.elemHeight
local function snap(x, s)
	s = s or 10
	return math.round(x / s) * s
end
local function releaseNodeCallback(mouse)
	dx, dy = 0, 0
end
local function moveNodeCallback(mouse)
	local ctrl = love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
	if ctrl then
		moveNode:setPos(snap(mouse.x + dx, s), snap(mouse.y + dy, s))
	else
		moveNode:shiftPos(mouse.dx, mouse.dy)
	end
	return releaseNodeCallback
end
local function pressNodeCallback(mouse)
	dx, dy = moveNode:getPos()
	dx = dx - mouse.x
	dy = dy - mouse.y
	return true, moveNodeCallback
end

local moveLink
local function releaseLinkCallback(mouse)
	for n in node.stack:traverseDown() do
		local portIn = mouseOverPortIn(n, mouse.x, mouse.y)
		if portIn then
			moveLink:setOutput(portIn)
			break
		end
	end
	if table.empty(moveLink.portOut) then
		moveLink:remove() -- link has no connected branches
	else
		moveLink:updateCurve() -- link has connected branches
	end
end
local function moveLinkCallback(mouse)
	moveLink:updateCurve(mouse.x, mouse.y)
	return releaseLinkCallback
end

local elemInput = require "ui.elem.input"

function input.press(mouse)
	for n in node.stack:traverseDown() do
		if mouseOverNode(n, mouse.x, mouse.y) then
			node.stack:toTop(n)

			if mouseOverTitle(n, mouse.x, mouse.y) then
				if mouse.button == 1 then
					moveNode = n
					return pressNodeCallback(mouse)
				elseif mouse.button == 2 then
					if not n.protected then
						n:remove()
					end
				end
				return true
			end

			if n.graph and mouseOverGraph(n, mouse.x, mouse.y) then
				return true, n.graph:press(mouse.x - n.ui.x, mouse.y - n.ui.y - nodeHeight - style.nodeBorder, mouse)
			end

			local elem, ex, ey, ew, eh = mouseOverElem(n, mouse.x, mouse.y)
			if elem then
				mouse.ex = ex
				mouse.ey = ey
				mouse.ew = ew
				mouse.eh = eh
				return true, elemInput.press(elem, mouse)
			end

			local portOut = mouseOverPortOut(n, mouse.x, mouse.y)
			if portOut then
				if mouse.button == 1 then
					moveLink = node.connect(portOut, nil)
					return true, moveLinkCallback
				elseif mouse.button == 2 and portOut.link then
					portOut.link:remove() -- remove complete link tree
				end
				return true
			end

			local portIn = mouseOverPortIn(n, mouse.x, mouse.y)
			if portIn and portIn.link then
				if mouse.button == 1 then
					local portOut = portIn.link.portIn
					portIn.link:removeOutput(portIn)
					moveLink = node.connect(portOut, nil)
					moveLink:updateCurve(mouse.x, mouse.y)
					return true, moveLinkCallback
				elseif mouse.button == 2 then
					portIn.link:removeOutput(portIn) -- remove single output
				end
				return true
			end

			return true
		end
	end
end

function input.hover(mouse)
	for n in node.stack:traverseDown() do
		if mouseOverNode(n, mouse.x, mouse.y) then
			return n
		end
	end
	return false
end

return input
