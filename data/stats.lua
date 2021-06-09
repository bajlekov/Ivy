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

local ffi = require "ffi"

local stats = {}

--local meta = {__mode = "k"}

local listDev = {}
local listHost = {}

--setmetatable(listDev, meta)
--setmetatable(listHost, meta)

local memDev = 0
local memHost = 0
local bufDev = 0
local bufHost = 0
local memDevMax = 0
local memHostMax = 0
local bufDevMax = 0
local bufHostMax = 0

local function sum(list)
    local n = 0
    local s = 0

    for _, v in pairs(list) do
        n = n + 1
        s = s + v
    end

    return s, n
end

function stats.allocDev(ptr, mem)
    ptr = tonumber(ffi.cast("uintptr_t", ptr))
    listDev[ptr] = mem
    memDev, bufDev = sum(listDev)
    memDevMax = math.max(memDev, memDevMax)
    bufDevMax = math.max(bufDev, bufDevMax)
end

function stats.allocHost(ptr, mem)
    ptr = tonumber(ffi.cast("uintptr_t", ptr))
    listHost[ptr] = mem
    memHost, bufHost = sum(listHost)
    memHostMax = math.max(memHost, memHostMax)
    bufHostMax = math.max(bufHost, bufHostMax)
end

function stats.freeDev(ptr)
    ptr = tonumber(ffi.cast("uintptr_t", ptr))
    listDev[ptr] = nil
    memDev, bufDev = sum(listDev)
end

function stats.freeHost(ptr)
    ptr = tonumber(ffi.cast("uintptr_t", ptr))
    listHost[ptr] = nil
    memHost, bufHost = sum(listHost)
end

function stats.getMemDev()
    return memDev
end

function stats.getMemHost()
    return memHost
end

function stats.getMemDevMax()
    return memDevMax
end

function stats.getMemHostMax()
    return memHostMax
end

function stats.getBufDev()
    return bufDev
end

function stats.getBufHost()
    return bufHost
end

function stats.getBufDevMax()
    return bufDevMax
end

function stats.getBufHostMax()
    return bufHostMax
end

function stats.clearDevMax()
    memDev, bufDev = sum(listDev)
    memDevMax = memDev
    bufDevMax = bufDev
end

function stats.clearHostMax()
    memHost, bufHost = sum(listHost)
    memHostMax = memHost
    bufHostMax = bufHost
end

return stats