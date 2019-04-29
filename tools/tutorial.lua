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

local style = require "ui.style"
local process = require "tools.process"
local pipeline = require "tools.pipeline"

local tutorial = {}

-- mouse control

-- mouse icons
local mouseButton = 0

local lmbIcon = love.graphics.newImage("res/icons/lmb.png")
local rmbIcon = love.graphics.newImage("res/icons/rmb.png")

local mouseX
local mouseY

-- annotations layer



-- tutorial nodes
local Node = require "ui.node"

function tutorial.node(x, y)
	local n = Node:new("Tutorial Node")

	n:addElem("text", 1, "Text")

	n:addElem("button", 11, "Exit", tutorial.exit)
	n:addElem("button", 12, "Next", tutorial.next)

	n.call = function()	end
	n.tint = style.lime
	n.w = 300
	n.protected = true
	n:setPos(x, y)
	return n
end

local set
local step
local tutorialNode
local helperNode1
local helperNode2
local helperNode3

local __mousemoved
local __mousepressed
local __mousereleased

local mouseDisabled

local function mouseDisable()
	mouseX, mouseY = love.mouse.getPosition()
	function love.mousemoved() end
	function love.mousepressed() end
	function love.mousereleased() end
	mouseDisabled = true
end

local function mouseEnable()
	function love.mousemoved(x, y, dx, dy)
		__mousemoved(x, y, dx, dy)
		mouseX = x
		mouseY = y
	end

	function love.mousepressed(x, y, button, isTouch)
		__mousepressed(x, y, button, isTouch)
		mouseButton = button
		print(">", mouseX, mouseY)
	end

	function love.mousereleased(x, y, button, isTouch)
		__mousereleased(x, y, button, isTouch)
		mouseButton = 0
		print("<", mouseX, mouseY)
	end
	mouseDisabled = false
end

function tutorial.start(setName)
	if not tutorialNode then
		process.save("temporaryProcess.lua")

		tutorialNode = tutorial.node(15*14, 5*14)
		set = tutorial.set[setName]
		step = 0
		tutorial.next()

		__mousemoved = love.mousemoved
		__mousepressed = love.mousepressed
		__mousereleased = love.mousereleased
	end
end

function tutorial.next()
	step = step + 1
	tutorialNode.title = (set[step].title).." ["..step.."/"..#set.."]"
	tutorialNode.elem[1].left = set[step].text
	if step == #set then
		tutorialNode.elem[12] = nil
	end

	if set[step].preFunction then
		set[step].preFunction()
	end
	if set[step].action then
		tutorial.startAction(set[step].action)
	end
	if set[step].postFunction then
		set[step].postFunction()
	end
end

function tutorial.exit()
	tutorialNode:remove()
	tutorialNode = nil
	mouseEnable()
	love.mousemoved = __mousemoved
	love.mousepressed = __mousepressed
	love.mousereleased = __mousereleased

	process.load("temporaryProcess.lua")
end

do
	local move = "move"
	local click = "click"
	local hold = "hold"
	local release = "release"

	tutorial.set = {}
	tutorial.set.basic = {}
	local basic = tutorial.set.basic
	basic[1] = {
		title = "Basic Tutorial",
		text = [[
		Welcom to Ivy, a flexible image processor. It looks like this is your first time launching Ivy, would you like to follow a short tutorial to get acquainted? You can exit the tutorial by clicking "Exit" at any time. This and other tutorials can be found in the "Help" menu.
		Click "Next" to continue.
		]]
	}

	basic[2] = {
		title = "Basic Tutorial",
		text = [[
		Ivy uses a processing pipeline to execute multiple operations. These operations are performed in a specified order starting from an input image, and resulting in an output image. Each operation is represented by a node, and intermediate results are transferred to subsequent nodes by links between them.
		]],
		preFunction = function()
			-- clean-up
			local remove = {}
			for t in Node.stack:traverseDown() do
				if t==tutorialNode then
					t:setPos(15*14, 5*14)
				elseif t==pipeline.input then
					t:setPos(250, 300)
					t.portOut[0].link:remove()
				elseif t==pipeline.output then
					t:setPos(600, 400)
				else
					remove[#remove + 1] = t
				end
			end
			for k, v in ipairs(remove) do v:remove() end
		end,
		postFunction = function() end,
		action = {
			{move, 300, 310},
			{hold, 1},
			{move, 500, 160},
			{move, 500, 460},
			{move, 300, 310},
			{release, 1},
		}
	}

	basic[3] = {
		title = "Basic Tutorial",
		text = [[
		Ivy uses a processing pipeline to execute multiple operations. These operations are performed in a specified order starting from an input image, and resulting in an output image. Each operation is represented by a node, and intermediate results are transferred to subsequent nodes by links between them.
		]],
		preFunction = function()
			-- clean-up
			local remove = {}
			for t in Node.stack:traverseDown() do
				if t==tutorialNode then
					t:setPos(15*14, 5*14)
				elseif t==pipeline.input then
					t:setPos(250, 300)
					if t.portOut[0].link then
						t.portOut[0].link:remove()
					end
				elseif t==pipeline.output then
					t:setPos(600, 400)
				else
					remove[#remove + 1] = t
				end
			end
			for k, v in ipairs(remove) do v:remove() end
		end,
		postFunction = function() end,
		action = {
			{move, 330, 310},
			{hold, 1},
			{move, 500, 160},
			{move, 500, 460},
			{move, 595, 410},
			{release, 1},
		}
	}

end


function tutorial.draw()
	if mouseDisabled then
		if mouseButton==1 then
			love.graphics.setColor(0, 0, 0, 0.5)
			love.graphics.rectangle("fill", mouseX-56, mouseY-2, 46, 38, 3)
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.draw(lmbIcon, mouseX-54, mouseY)

			if love.keyboard.isDown("lctrl") then
				tutorial.startAction(action)
				local x, y = love.mouse.getPosition()
				__mousereleased(x, y, 1)
				mouseButton = 0
			end
		elseif mouseButton==2 then
			love.graphics.setColor(0, 0, 0, 0.5)
			love.graphics.rectangle("fill", mouseX-56, mouseY-2, 46, 38, 3)
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.draw(rmbIcon, mouseX-54, mouseY)
		end

		if mouseX and mouseY then
			local lime = style.lime
			love.graphics.setColor(lime[1], lime[2], lime[3], 0.3)
			love.graphics.circle("fill", mouseX, mouseY, 72)
		end
	end
end

local action
function tutorial.startAction(actionSet)
	mouseDisable()
	action = actionSet
	action.step = 0
end

local stepSize = 10
local delay = false
function tutorial.update()
	if action then
		if action.step==0 then
			if delay==false then
				delay = true
			else
				action.step = action.step + 1
				love.timer.sleep(0.5)
				delay = false
			end
		elseif action[action.step][1]=="move" then
			local targetX = action[action.step][2]
			local targetY = action[action.step][3]

			local d = math.sqrt((targetX-mouseX)^2 + (targetY-mouseY)^2)

			local x, y
			if d<stepSize then
				x, y = targetX, targetY
			else
				x = mouseX + math.floor((targetX-mouseX)/d*stepSize)
				y = mouseY + math.floor((targetY-mouseY)/d*stepSize)
			end

			if mouseX==targetX and mouseY==targetY then
				action.step = action.step + 1
				love.timer.sleep(0.5)
			end

			love.mouse.setPosition(x, y)
			__mousemoved(x, y, x - (mouseX or 0), y - (mouseY or 0))
			mouseX = x
			mouseY = y
		elseif action[action.step][1]=="hold" then
			if mouseButton==0 then
				__mousepressed(mouseX, mouseY, action[action.step][2])
				mouseButton = action[action.step][2]
			else
				action.step = action.step + 1
				love.timer.sleep(1)
			end
		elseif action[action.step][1]=="release" then
			if mouseButton~=0 then
				__mousereleased(mouseX, mouseY, action[action.step][2])
				mouseButton = 0
			else
				action.step = action.step + 1
				love.timer.sleep(1)
			end
		elseif action[action.step][1]=="click" then
			if mouseButton==0 then
				__mousepressed(mouseX, mouseY, action[action.step][2])
				mouseButton = action[action.step][2]
			else
				__mousereleased(mouseX, mouseY, action[action.step][2])
				mouseButton = 0
				action.step = action.step + 1
				love.timer.sleep(1)
			end
		end

		if action.step > #action then
			action = nil
			mouseEnable()
		end
	end
end






return tutorial
