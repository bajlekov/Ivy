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

-- OpenCL setup
local threadModule = {}

local ffi = require "ffi"

local platform
local device
local context
local queue

function threadModule.getDevice() return device end
function threadModule.getContext() return context end
function threadModule.getQueue() return queue end

local thread
local syncCh
local dataCh

function threadModule.init(platform, devNum)
  if platform then
    local cl = require "lib.opencl"
    platform = cl.get_platforms()[platform]
    device = platform:get_devices()[devNum]
    context = cl.create_context({device}) -- FIXME: crashes with intel cpu opencl driver on linux
    queue = context:create_command_queue(device, {"profiling"})
  else
    platform = nil
    device = nil
    context = nil
    queue = nil
  end

  -- start openCL thread controlling openCL queue
  thread = love.thread.newThread("thread/scheduler.lua")
  dataCh = love.thread.getChannel("dataCh_scheduler")
  syncCh = love.thread.getChannel("syncCh_scheduler")
  dataCh:clear()
  syncCh:clear()
  thread:start(
    tonumber(ffi.cast("uintptr_t", device)),
    tonumber(ffi.cast("uintptr_t", context)),
    tonumber(ffi.cast("uintptr_t", queue))
  )
end

local keepData = {}
local function pushImageData(data)
	table.insert(keepData, data)
	dataCh:push(data:toTable())
end
function threadModule.keepData(data)
  table.insert(keepData, data)
end
function threadModule.freeData()
	keepData = {}
	collectgarbage("collect")
end

local data = require "data"
function threadModule.done(OCL)
  local err = thread:getError()
  if err then
    error("SCHEDULER ERROR: "..err)
  end
	if syncCh:pop()=="done" then
		--data.stats.thread = syncCh:demand()
		return true
	else
		return false
	end
end

do
  local remoteFunctionName

  local function process(buffers, node)
    local scheduler
    local nodeID = false
    if type(node)=="table" then
      scheduler = node.procType
      nodeID = node.id
    elseif node then -- legacy scheduler passing instead of node structure. Still used outside of node processing!!!
      scheduler = node
    end

    assert(scheduler=="dev" or scheduler=="host", "Invalid scheduler \""..scheduler.."\"")

    dataCh:push(scheduler)
    dataCh:push(nodeID)
    dataCh:push(remoteFunctionName)
    for k, v in ipairs(buffers) do
      pushImageData(v)
    end
    dataCh:push("execute")
  end

  local function opsIndex(t, k)
    remoteFunctionName = k
    return process
  end

  threadModule.ops = setmetatable({}, {__index = opsIndex})

  function threadModule.ops.syncHost(buffer)
    dataCh:push("SyncHost")
    pushImageData(buffer)
    dataCh:push("execute")
  end

  function threadModule.ops.syncDevice(buffer)
    dataCh:push("SyncDevice")
    pushImageData(buffer)
    dataCh:push("execute")
  end

  function threadModule.ops.syncHostMulti(buffers)
    dataCh:push("SyncHost")
    for k, v in ipairs(buffers) do
      pushImageData(v)
    end
    dataCh:push("execute")
  end

  function threadModule.ops.syncDeviceMulti(buffers)
    dataCh:push("SyncDevice")
    for k, v in ipairs(buffers) do
      pushImageData(v)
    end
    dataCh:push("execute")
  end

  function threadModule.ops.reloadDev()
    dataCh:push("reloadDev")
  end

	function threadModule.ops.done()
		dataCh:push("done")
	end

end

return threadModule
