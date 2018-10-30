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

-- TODO: add object functionality instead of a single instance
-- TODO: allow only indirect calls to prev, next etc, no direct access to list array!
-- TODO: check whether weak keys are needid for proper garbage collection

local stack = {type = "stack"}
stack.meta = {__index = stack}

--doubly linked stack
function stack:new()
  local stack = {list = {}}
  return setmetatable(stack, self.meta)
end

function stack:add(node) -- always add to top of stack
  assert(type(node)=="table") -- nodes should be tables
  assert(self.list[node]==nil) -- only add new nodes, duplicates are not handled well

  if not self.top and not self.bottom then
    local new = {prev=nil, next=nil, value=node}
    self.list[node] = new
    self.top = new
    self.bottom = new
  else
    local new = {prev = nil, next = self.top, value=node}
    self.list[node] = new
    self.top.prev = new
    self.top = new
  end
end

function stack:remove(node)
  assert(type(node)=="table") -- nodes should be tables
  assert(self.list[node]) -- only remove if node exists

  if self.list[node]==self.top and self.list[node]==self.bottom then -- last node
    self.top = nil
    self.bottom = nil
    self.list[node] = nil
  elseif self.list[node]==self.top then
    local next = self.list[node].next
    self.top = next
    next.prev = nil
    self.list[node] = nil
  elseif self.list[node]==self.bottom then
    local prev = self.list[node].prev
    self.bottom = prev
    prev.next = nil
    self.list[node] = nil
  else
    local prev = self.list[node].prev
    local next = self.list[node].next
    prev.next = next
    next.prev = prev
    self.list[node] = nil
  end
end


local function traverseDown(stack, value) -- TODO: fix to use links instead of table lookups
  if value==nil then return stack.top.value end
  if value==stack.bottom.value then return nil end
  return stack.list[value].next.value
end
function stack:traverseDown()
  return traverseDown, self
end

local function traverseUp(stack, value) -- TODO: fix to use links instead of table lookups
  if value==nil then return stack.bottom.value end
  if value==stack.top.value then return nil end
  return stack.list[value].prev.value
end
function stack:traverseUp()
  return traverseUp, self
end

function stack:toTop(node) -- TODO: make more efficient!
  self:remove(node)
  self:add(node)
end

return stack
