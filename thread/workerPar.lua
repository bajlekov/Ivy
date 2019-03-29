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

require "setup"

global("settings")
if love.filesystem.isFused() then
	if love.filesystem.mount(love.filesystem.getSourceBaseDirectory(), "base") then
		settings = require "base.settings"
	end
else
	settings = require "settings"
end

local ffi = require "ffi"
local data = require "data"
local image = require "ui.image"

local cs = require "tools.cs"

local args = {...}

local threadNum = args[1]
local threadMax = args[2]

local dataCh = love.thread.getChannel("dataCh_worker"..threadNum)
local syncCh = love.thread.getChannel("syncCh_worker"..threadNum)
local lockCh = love.thread.getChannel("lockCh")

local function round(x)
	return math.floor(x+0.5)
end

local function getData()
	local d = dataCh:demand()
	assert(type(d)=="table")
	return data.fromChTable(d)
end

local function getImage()
	local d = dataCh:demand()
	assert(type(d)=="table")
	return image.fromChTable(d)
end

local function getCData()
	local d = dataCh:demand()
	assert(type(d)=="table")
	return data.fromChTable(d):toCStruct()
end

local function getCImage()
	local d = dataCh:demand()
	assert(type(d)=="table")
	return image.fromChTable(d):toCStruct()
end


local ops = {}

function ops.sync()
	syncCh:supply("sync")
	assert(syncCh:demand()=="resume")
end

function ops.lock()
	assert(lockCh:demand()==1)
	assert(lockCh:getCount()==0)
end

function ops.unlock()
	assert(lockCh:getCount()==0)
	lockCh:push(1)
end


function ops.stat_mean()
	local p1 = getData()
	local p2 = getData()
	assert(dataCh:demand()=="execute")

	if threadNum==0 then
		p2:set(0, 0, 0, 0)
		p2:set(0, 0, 1, 0)
		p2:set(0, 0, 2, 0)
	end
	ops.sync()

	local r, g, b = 0, 0, 0
	for y = threadNum, p1.y - 1, threadMax do
		for x = 0, p1.x - 1 do
			r = r + p1:get(x, y, 0)
			g = g + p1:get(x, y, 1)
			b = b + p1:get(x, y, 2)
		end
	end
	r = r/(p1.x*p1.y)
	g = g/(p1.x*p1.y)
	b = b/(p1.x*p1.y)

	ops.lock()
		r = r + p2:get(0, 0, 0)
		p2:set(0, 0, 0, r)
		g = g + p2:get(0, 0, 1)
		p2:set(0, 0, 1, g)
		b = b + p2:get(0, 0, 2)
		p2:set(0, 0, 2, b)
	ops.unlock()


	syncCh:supply("step")
end


-- run process
while true do
	local op = dataCh:demand()
	assert(type(op)=="string")
	if ops[op] then
		require "jit".flush() -- FIXME: temporary fix for severe slowdowns
		ops[op]()
	else
		error("LUA WORKER ERROR: op ["..op.."] not a Native function!")
	end
end
