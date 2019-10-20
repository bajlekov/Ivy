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

-- node library
local node = {type = "node"}
node.meta = {__index = node}

node.stack = require("ui.node.stack"):new()
node.draw = require "ui.node.draw"

local link = require "ui.node.link"
local event = require "ui.node.event"

node.list = {}
setmetatable(node.list, {__mode="v"})




function node:new(title)
  local node = {
    title = title,      -- node title
    portIn = {},        -- incoming connections
    portOut = {},       -- outgoing connections
    elem = {           -- ui elemenets
      n = 0,
    },
    process = function() end,  -- function to run for processing
    ui = {              -- store UI related stuff (redraw images etc.)
      x = math.huge,
      y = math.huge,
      minimized = false,
      redraw = true,
      -- TODO: drawing buffers for quicker redraws
    },
    history = {},       -- state changes
    presets = {},       -- store presets
    profile = {},       -- store profile data on each run
    storage = {},       -- local storage for each node
    data    = {},       -- image data for processing
		dirty = true,			-- indicates whether processing is needed
  }

  node.id = tonumber(tostring(node):match("0x[0-9a-f]+"))
  assert(self.list[node.id]==nil, "Node ID collision, fix ID creation method to prevent this")
  self.list[node.id] = node

  self.stack:add(node)
  return setmetatable(node, self.meta)
end

function node:setPos(x, y)
  assert(type(x)=="number", "X position coordinate not a number")
  assert(type(y)=="number", "Y position coordinate not a number")

  -- auto-connect
	local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
	local autoConnect = settings.nodeAutoConnect
	if shift then autoConnect = not autoConnect end

  if autoConnect and self.ui.x==math.huge then -- node is newly placed
    local prevNode
    local prevDist = math.huge
    local nextNode
    local nextDist = math.huge
    for n in node.stack:traverseUp() do
      local dist = 0.5*(x - n.ui.x)^2 + (y - n.ui.y)^2
      if n.ui.x<x then
        if dist<prevDist then prevNode = n prevDist = dist end
      else
        if dist<nextDist then nextNode = n nextDist = dist end
      end
    end

		if nextNode and nextNode.portIn[0] then
			if nextNode.portIn[0].link and self.portIn[0] and self.portOut[0] then -- splice if nextNode port connected
				node.connect(nextNode.portIn[0].link.portIn, self.portIn[0])
				node.connect(self.portOut[0], nextNode.portIn[0])
			end

			if not nextNode.portIn[0].link and self.portOut[0] then	-- connect to nextNode only if not already connected, unable to splice
				node.connect(self.portOut[0], nextNode.portIn[0])
			end
		end

		if prevNode and prevNode.portOut[0] and self.portIn[0] and not self.portIn[0].link then -- connect to prevNode if not spliced before
			node.connect(prevNode.portOut[0], self.portIn[0])
		end

  end


  self.ui.x = x
  self.ui.y = y
  event.move(self)
  return self
end

function node:shiftPos(dx, dy)
  assert(type(dx)=="number", "X position coordinate not a number")
  assert(type(dy)=="number", "Y position coordinate not a number")
  self.ui.x = self.ui.x + dx
  self.ui.y = self.ui.y + dy
  event.move(self)
  return self
end

function node:getPos()
  return self.ui.x, self.ui.y
end

function node:addPortIn(n, cs)
	assert(cs and type(cs)=="string")
  assert(type(n)=="number")
  assert(n>=0)
  self.portIn[n] = {
    link = nil,
    type = nil,
    cs = cs,
    visible = true,
    parent = self,
    n = n,
  }
  if self.elem.n < n then self.elem.n = n end
  return self
end

function node:addPortOut(n, cs)
	assert(cs and type(cs)=="string")
  assert(type(n)=="number")
  assert(n>=0)
  self.portOut[n] = {
    link = nil,
    type = nil,
    cs = cs,
    visible = true,
    parent = self,
    n = n,
  }
  if self.elem.n < n then self.elem.n = n end
  return self
end

local elem = require "ui.elem"
function node:addElem(type, ...)
  assert(self.elem, "ERROR: frame does not support elements")
  return elem[type](self, ...)
end

function node:remove()

  -- auto-connect
	local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
	local autoConnect = settings.nodeAutoConnect
	if shift then autoConnect = not autoConnect end

  if autoConnect and self.portIn[0] and self.portIn[0].link and self.portOut[0] and self.portOut[0].link then
		for p in pairs(self.portOut[0].link.portOut) do
			node.connect(self.portIn[0].link.portIn, p)
		end
  end

  for k, port in pairs(self.portIn) do
    if port.link then
      port.link:removeOutput(port)
    end
  end
  for k, port in pairs(self.portOut) do
    if port.link then
      port.link:remove()
    end
  end
  self.stack:remove(self)

end

function node.connect(portOut, portIn)
  local link = link:connect(portOut, portIn) -- inverse of the link directions
  link:updateCurve()
  return link
end

-- TODO: disconnect equivalent

return node
