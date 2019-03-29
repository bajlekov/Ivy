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

-- replaces remoteOCL and remoteNative functionality in one combined scheduler
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
--local cl = require "lib.opencl"
ffi.cdef[[
	typedef struct _cl_device_id *cl_device_id;
	typedef struct _cl_context *cl_context;
	typedef struct _cl_command_queue *cl_command_queue;
]]

-- host channel
local hostDataCh = love.thread.getChannel("dataCh_scheduler")
local hostSyncCh = love.thread.getChannel("syncCh_scheduler")

local messageCh = love.thread.getChannel("messageCh")

local args = {...}

local device = ffi.cast("cl_device_id", args[1])
local context = ffi.cast("cl_context", args[2])
local queue = ffi.cast("cl_command_queue", args[3])
local threadMax = args[4]

local data = require "data"
data.initDev(context, queue)

local schedule = {}

-- end of device queue
local lastid = false
function schedule.done()
	hostSyncCh:push("done")
	if lastid then
		messageCh:push{"end", lastid}
	end
	lastid = false
end

local function startID()
	local id = hostDataCh:demand()
	if lastid~=id then
		if lastid then
			messageCh:push{"end", lastid}
		end
		messageCh:push{"start", id}
		lastid = id
	end
end


-- OCL execution
local opsDev = require "thread.workerDev"
opsDev.initDev(device, context, queue)

function schedule.dev()
	startID()
	local op = hostDataCh:demand()
	assert(type(op) == "string", "Invalid OCL op of type ["..type(op).."]")

	if opsDev[op] then
		if settings.openclProfile then
			debug.tic()
		end

		opsDev[op]()
		queue:finish()

		if settings.openclProfile then
			debug.toc("OCL scheduler step")
		end

	else
		error("OCL WORKER ERROR: op ["..op.."] not an OpenCL function!\nHint: Check if function is correctly registered in workerOCL.lua!")
	end
end


-- single native thread
local opsHost = require "thread.workerHost"

function schedule.host()
	startID()
	local op = hostDataCh:demand()
	assert(type(op) == "string", "Invalid Native op of type ["..type(op).."]")
	if opsHost[op] then
		opsHost[op]()
	else
		error("NATIVE WORKER ERROR: op ["..op.."] not an native function!\nHint: Check if function is correctly registered in workerNative.lua!")
	end
end


-- parallel native worker channels
local thread = {}
local dataCh = {}
local syncCh = {}

for i = 0, threadMax - 1 do
	thread[i] = love.thread.newThread("thread/workerPar.lua")
	dataCh[i] = love.thread.getChannel("dataCh_worker"..i)
	syncCh[i] = love.thread.getChannel("syncCh_worker"..i)
	dataCh[i]:clear()
	syncCh[i]:clear()

	thread[i]:start(i, threadMax)
end
local lockCh = love.thread.getChannel("lockCh")
lockCh:push(1)

local profile = settings.nativeProfile
local profileOp

function schedule.par()
	startID()
	local done = false
	if profile then
		while hostDataCh:getCount() == 0 do end
		profileOp = hostDataCh:peek()
		debug.tic()
	end

	while not done do
		local com = hostDataCh:demand()
		for i = 0, threadMax - 1 do
			dataCh[i]:push(com)
		end
		done = com == "execute"
	end

	-- TODO: use checks with time-out starting with Love 0.11
	local workerSync = false
	local workerStep = false
	local workerDone = false
	local done
	while not done do
		for i = 0, threadMax - 1 do
			local err = thread[i]:getError()
			if err then
				error("WORKER ERROR: "..err)
			end

			if syncCh[i]:peek() == "done" then workerDone = true end
			if syncCh[i]:peek() == "step" then workerStep = true end
			if syncCh[i]:peek() == "sync" then workerSync = true end
		end

		if workerSync then
			for i = 0, threadMax - 1 do
				assert(syncCh[i]:demand() == "sync", "ERROR: not all workers have reached the synchronisation point")
			end
			for i = 0, threadMax - 1 do
				syncCh[i]:supply("resume")
			end
			workerSync = false
		end

		if workerStep then
			for i = 0, threadMax - 1 do
				assert(syncCh[i]:demand() == "step", "ERROR: not all workers have completed the step")
			end
			done = true
		end

		if workerDone then
			for i = 0, threadMax - 1 do
				assert(syncCh[i]:demand() == "done", "ERROR: not all workers have completed the sequence")
			end
			done = true
			hostSyncCh:push("done")
		end

		if not done then love.timer.sleep(0.001) end
	end
	if profile then
		debug.toc(profileOp)
	end
end


-- sync memory to device
function schedule.SyncDevice()
	local done = false
	while not done do
		local buf = hostDataCh:demand()
		if buf == "execute" then
			done = true
		else
			data.fromChTable(buf):toDevice(true)
		end
	end
end

-- sync memory to host
function schedule.SyncHost()
	local done = false
	while not done do
		local buf = hostDataCh:demand()
		if buf == "execute" then
			done = true
		else
			data.fromChTable(buf):toHost(true) -- blocking sync to ensure memory integrity for following host ops
		end
	end
end

-- reload OCL kernels
function schedule.reloadDev()
	opsDev.initDev(device, context, queue)
end

local t1 = 0
local t2 = 0
local timer = require "love.timer"


-- run process
while true do
	local com = hostDataCh:demand()
	assert(type(com) == "string", "Invalid scheduler of type ["..type(com).."]")
	if schedule[com] then

		if profile then
			t2 = timer.getTime()
			print("Cycle: "..string.format("%.3fms", (t2 - t1) * 1000))
			t1 = t2
		end

		schedule[com]()
	else
		error("SCHEDULER ERROR: scheduler ["..com.."] not known!")
	end
end
