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

local style = require "ui.style"
local cursor = require "ui.cursor"

local event = {}

event.press = {}
event.move = {}
event.release = {}

local function dirty(elem) -- TODO: move to elem.parent:onChange()
	if elem.parent.dirty == false then elem.parent.dirty = true end
	if elem.onChange then elem:onChange() end
	if elem.parent.onChange then elem.parent:onChange() end
end

local originalElementValue
function event.press.float(elem, mouse)
	if mouse.button==2 and not elem.disabled then
		elem.value = elem.default
		dirty(elem)
	else
		cursor.sizeH()
		originalElementValue = elem.value
	end
	elem.tint = style.orange
end
function event.move.float(elem, mouse)
	if mouse.button==1 and not elem.disabled then
		local dx, dy = mouse.x - mouse.ox, mouse.y - mouse.oy
		local change = dx / mouse.ew -- FIXME: parameters in UI have different width
		local size = elem.max - elem.min
		if mouse.ctrl then change = math.floor(change * 20) / 20 end
		local value = originalElementValue + change * size * (mouse.shift and 0.1 or 1)
		if value < elem.min then value = elem.min end
		if value > elem.max then value = elem.max end
		elem.value = value
		dirty(elem)
	end
end
function event.release.float(elem)
	cursor.arrow()
	elem.tint = nil
end

function event.press.int(elem, mouse)
	if mouse.button == 2 then
		elem.value = elem.default
		dirty(elem)
		elem.tint = style.orange
		return
	end

	if mouse.button == 1 then
		local value = elem.value
		if mouse.x - mouse.ex > mouse.ew / 2 then
			value = value + elem.step
		else
			value = value - elem.step
		end
		if value < elem.min then value = elem.min end
		if value > elem.max then value = elem.max end
		elem.value = value
		dirty(elem)
		elem.tint = style.orange
		return
	end
end
function event.release.int(elem) elem.tint = nil end

function event.press.bool(elem, mouse)
	if elem.exclusive then
		for k, v in pairs(elem.exclusive) do
			v.value = false
			v.tint = style.orange
		end
		elem.value = true
	else
		if mouse.button == 2 then
			elem.value = elem.default
		else
			elem.value = not elem.value
		end
	end
	elem.tint = style.orange
	dirty(elem)
end
function event.release.bool(elem, mouse)
	if elem.exclusive then
		for k, v in pairs(elem.exclusive) do
			v.tint = nil
		end
	end
	elem.tint = nil

	if elem.action then
		elem.action(elem, mouse)
	end
end

function event.press.enum(elem, mouse)
	if mouse.button == 2 then
		elem.value = elem.default
		dirty(elem)
		elem.tint = style.orange
		return
	end

	if mouse.button == 1 then
		local value = elem.value
		if mouse.x - mouse.ex > mouse.ew / 2 then
			value = value + 1
		else
			value = value - 1
		end
		if value < 1 then value = #elem.enum end
		if value > #elem.enum then value = 1 end
		elem.value = value
		dirty(elem)
		elem.tint = style.orange
		return
	end
end
function event.release.enum(elem, mouse)
	elem.tint = nil

	if elem.action then
		elem.action(elem, mouse)
	end
end

function event.press.button(elem, mouse)
	if mouse.button == 1 then
		elem.tint = style.blue
	end
end
function event.release.button(elem, mouse)
	if mouse.button == 1 then

		elem.parent.visible = false
		elem.tint = nil

		if elem.parent.style == "toolbar" and elem.frame then
			local xoff = elem.parent.x + style.nodeBorder + 1
			local i = math.floor((mouse.x - xoff) / (style.nodeWidth + 1))
			local x = xoff + i * (style.nodeWidth + 1)
			local y = elem.parent.y + style.elemHeight + style.nodeBorder * 2 + 1 + (elem.parent.headless and 0 or style.titleHeight)

			elem.frame.w = style.nodeWidth
			elem.frame:set(x, y)
			elem.frame.visible = true

			return
		end

		if elem.parent.style == "panel" and elem.frame then
			local x = elem.parent.x + 1
			local yoff = elem.parent.y + (elem.parent.headless and 0 or style.titleHeight) + style.nodeBorder + 1
			local i = math.floor((mouse.y - yoff) / style.elemHeight + 1)
			local y = yoff + style.elemHeight * i + style.nodeBorder

			elem.frame.w = elem.parent.w - 2 * style.nodeBorder - 2
			elem.frame:set(x, y)
			elem.frame.visible = true
			return
		end

		if elem.parent.type == "node" and elem.frame then --TODO: fix alignment
			local x = elem.parent.ui.x
			local yoff = elem.parent.ui.y + style.titleHeight
			local i = math.floor((mouse.y - yoff) / style.elemHeight + 1)
			local y = yoff + style.elemHeight * i + style.nodeBorder

			elem.frame.w = elem.parent.w
			elem.frame:set(x, y)
			elem.frame.visible = true
			return
		end

		if elem.action then
			elem.action(elem.parent.x, mouse.y) -- add node
			return
		end

		if elem.frame then
			if elem.menu then
				elem.frame:set(elem.parent.x, mouse.y) -- sub-menu
				elem.frame.visible = true
			elseif elem.dropdown then
				elem.frame:set(mouse.x, mouse.y)
				elem.frame.visible = true
			end
			return
		end

	end
end

function event.press.graphic(graphic, mouse)

end


local pipeline = require "tools.pipeline"
function event.press.textinput(elem, mouse)

	if not elem.tint and mouse.button==1 then
		local _keypressed = love.keypressed
		local _textinput = love.textinput
		local _mousepressed = love.mousepressed
		local _value = elem.value

		elem.tint = style.orange
		love.keyboard.setKeyRepeat(true)

		function love.keypressed(key)
			if key=="return" or key=="escape" then
				if key=="escape" then
					elem.value = _value
				end
				love.keypressed = _keypressed
				love.textinput = _textinput
				love.mousepressed = _mousepressed

				elem.tint = nil
				love.keyboard.setKeyRepeat(false)
				dirty(elem)
				pipeline.update()
				return
			end

			local n = #elem.value
			if key=="backspace" and n > 0 then
				elem.value = elem.value:sub(1, n - 1)
				return
			end
		end

		function love.mousepressed(x, y, button, isTouch)
			love.keypressed("return")
			love.mousepressed(x, y, button, isTouch)
		end

		function love.textinput(text)
			elem.value = elem.value..text
			-- implement cursor
			-- proper editing
		end
	end

	if not elem.tint and mouse.button==2 then
		elem.value = elem.default
		dirty(elem)
		pipeline.update()
	end
end

return event
