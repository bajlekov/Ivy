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

local ffi = require "ffi"

local process = {}
process.meta = {__index = process}

local tools = require "lib.opencl.tools"
local data = require "data"

local oclProfile = settings.openclProfile
local oclDebug = settings.openclDebug
local workgroupSize = settings.openclWorkgroupSize
local buildParams = settings.openclBuildParams

local onDemandMemory = settings.openclLowMemory

local dataCh = love.thread.getChannel("dataCh_scheduler")
local syncCh = love.thread.getChannel("syncCh_scheduler")
local messageCh = love.thread.getChannel("messageCh")

function process.new(device, context, queue)
	local o = {}
	o.device = device
	o.context = context
	o.queue = queue

	o.source = ""
	o.buffers = {}
	o.order = {}

	o.kernels = {}

	setmetatable(o, process.meta)
	return o
end

function process:setWorkgroupSize(size)
	self.workgroupSize = size
end

function process:init(device, context, queue)
	self.device = device
	self.context = context
	self.queue = queue
end

local function signature(data, chain)
	chain = chain or ""
	return string.format("%s{%d_%d_%d/%d_%d_%d/%s}", chain, data.x, data.y, data.z, data.sx, data.sy, data.sz, data.cs)
end

local function getID(buffers, order)
	local s = ""
	for k, v in ipairs(order) do
		if type(v)~="cdata" then -- skip cdata
			s = signature(buffers[v], s)
		end
	end
	return s
end

local function getKernel(process, k)
	local ID = getID(process.buffers, process.order) -- FIXME: use tools.getID once it is updated
	if not process.kernels[k] then
		process.kernels[k] = {}
	end
	if not process.kernels[k][ID] then
		local source = tools.parseIndex(process.source, process.buffers)
		process.source_parsed = source
		local program = process.context:create_program_with_source(source)

		if not pcall(program.build, program, tools.buildParams) then
			messageCh:push{"error", "ERROR ["..k.."]: \n"..program:get_build_info(process.device, "log")}
			return nil
		else
			process.kernels[k][ID] = program:create_kernel(k)
		end
	end
	return process.kernels[k][ID]
end

function process:loadSourceString(s)
	assert(type(s) == "string")
	self.source = s
	self.kernels = {}
end

function process:loadSourceFile(...)
	local s = ""
	for k, v in ipairs({...}) do
		local f = assert(io.open("ops/ocl/"..v, "rb"))
		s = s..f:read("*a")
		f:close()
	end
	self.source = s
	self.kernels = {}
end

do
	local n = 1
	function process:getBuffer(name)
		local buf = dataCh:demand()
		assert(type(buf) == "table", buf)
		self.buffers[name] = data.fromChTable(buf)
		self.order[n] = name
		n = n + 1
	end

	-- TODO: get non-data buffers (image etc.)
	function process:getImage(name)
		error("NYI!")
	end

	function process:buffersReady()
		assert(dataCh:demand() == "execute")
		n = 1
	end

	-- get multiple buffers in a row without calling buffersReady, allowing for use of getBuffer before or after
	function process:getBuffers(...)
		for k, v in ipairs({...}) do
			self:getBuffer(v)
		end
	end

	-- gets all buffers and calls buffersReady
	function process:getAllBuffers(...)
		for k, v in ipairs({...}) do
			local buf = dataCh:demand()
			assert(type(buf) == "table", buf)
			self.buffers[v] = data.fromChTable(buf)
			self.order[k] = v
		end
		self:buffersReady()
	end
end

function process:setOrder(order)
	self.order = order
end

local function setArgs(kernel, buffers, order)
	for k, v in ipairs(order) do
		local b = buffers[v]
		if not b then
			assert(type(v)=="cdata")
			kernel:set_arg(k - 1, v)
		else
			if type(b)=="table" then
				if onDemandMemory then process.allocBuffer(b) end
				assert(type(b.dataOCL)=="cdata")
				if oclDebug then print("["..(k-1).."]", b.dataOCL, tostring(b)) end
				kernel:set_arg(k - 1, b.dataOCL)
			else
				assert(type(b)=="cdata")
				kernel:set_arg(k - 1, b)
			end
		end
	end
end

-- use uniform workgroup sizes, settings-selectable
local function enqueueKernel(process, kernelName, size)
	local kernel = getKernel(process, kernelName)
	if not kernel then return end

	size[1] = size[1] or 1
	size[2] = size[2] or 1
	size[3] = size[3] or 1

	local workgroupSize = process.workgroupSize or workgroupSize
	local workgroup = {math.min(size[1], workgroupSize[1]), math.min(size[2], workgroupSize[2]), math.min(size[3], workgroupSize[3])}

	local sx = workgroup[1]
	local sy = workgroup[2]
	local sz = size[3]
	local px = size[1]%sx
	local py = size[2]%sy
	local ox = size[1] - px
	local oy = size[2] - py
	local oz = size[3] and 0 or nil

	if onDemandMemory then
		process.queue:finish()
		process.markBuffers(process.buffers, process.order)
		process.freeBuffers()
	end

	if oclDebug then
		print("=======")
		print(kernelName)
		print("-------")
	end

	setArgs(kernel, process.buffers, process.order)

	local event = {}
	event[1] = process.queue:enqueue_ndrange_kernel(kernel, nil, {ox, oy, sz}, workgroup)
	if px ~= 0 then
		workgroup[1] = px
		event[2] = process.queue:enqueue_ndrange_kernel(kernel, {ox, 0, oz}, {px, oy, sz}, workgroup)
		if py ~= 0 then
			workgroup[2] = py
			event[3] = process.queue:enqueue_ndrange_kernel(kernel, {ox, oy, oz}, {px, py, sz}, workgroup)
			workgroup[1] = sx
		end
	end
	if py ~= 0 then
		workgroup[2] = py
		event[4] = process.queue:enqueue_ndrange_kernel(kernel, {0, oy, oz}, {ox, py, sz}, workgroup)
	end

	if oclProfile then
		local time = 0
		for i = 1, 4 do
			if event[i] then
				time = time + tools.profile(kernelName.."["..i.."]", event[i], process.queue, true)
			end
		end
		print("[OCL]"..kernelName..": "..string.format("%.3fms", (time))) -- TODO: unify with profile print from lib.opencl.tools
		return time
	end
end

function process:executeKernel(kernel, size, order)
	local oldOrder = self.order
	if order then
		self.order = order
	end
	if kernel then
		enqueueKernel(self, kernel, size)
	else
		error("No kernel supplied")
	end
	self.order = oldOrder
end

function process:saveSource(name)
	name = name or "out.cl"
	local f = io.open(name, "wb")
	if f then
		f:write(self.source_parsed or "")
		f:close()
	end
end

function process:size2D(buf)
	return {self.buffers[buf].x, self.buffers[buf].y}
end

function process:size2Dmax(...)
	local x, y = 0, 0
	for k, v in ipairs{...} do
		if self.buffers[v].x > x then x = self.buffers[v].x end
		if self.buffers[v].y > y then y = self.buffers[v].y end
	end
	return {x, y}
end

function process:size3D(buf)
	return {self.buffers[buf].x, self.buffers[buf].y, self.buffers[buf].z}
end

function process:size3Dmax(...)
	local x, y, z = 0, 0, 0
	for k, v in ipairs{...} do
		if self.buffers[v].x > x then x = self.buffers[v].x end
		if self.buffers[v].y > y then y = self.buffers[v].y end
		if self.buffers[v].z > z then z = self.buffers[v].z end
	end
	return {x, y, z}
end

function process.profile()
	return profile
end



local allocatedBuffersList = {}

function process.markBuffers(buffers, order)
	for k, v in ipairs(order) do
		local b = buffers[v]
		if b then
			local id = tonumber(ffi.cast("uintptr_t", b.data))
			if allocatedBuffersList[id] then
				allocatedBuffersList[id].keep = true
				if oclDebug then print("==>", allocatedBuffersList[id].buffer.dataOCL, tostring(allocatedBuffersList[id].buffer)) end
			end
		end
	end
end

function process.allocBuffer(buffer)
	-- updating buffers outside of this worker would fail, outdated copies are being preserved and reloaded
	-- ...only problematic on consecutive kernel enqueues as otherwise buffers are cleared
	-- gpuUpdate flag set on toDevice() calls, forcing reloading of the buffer

	local id = tonumber(ffi.cast("uintptr_t", buffer.data))

	if type(buffer)=="table" and buffer.type=="data" and (not buffer.dataOCL or buffer.dataOCL==NULL) then
		if allocatedBuffersList[id] then
			allocatedBuffersList[id].keep = false
			buffer.dataOCL = allocatedBuffersList[id].dataOCL
			allocatedBuffersList[id].buffer = buffer
			if oclDebug then print(">**", buffer.dataOCL, tostring(buffer)) end

			if buffer.__write then allocatedBuffersList[id].write = true end -- preserve write flag
		else
			buffer:allocDev()
			allocatedBuffersList[id] = {keep = false, buffer = buffer, dataOCL = buffer.dataOCL, write = buffer.__write or nil}
			if oclDebug then print("+++", buffer.dataOCL, tostring(buffer)) end
		end
	else
		if allocatedBuffersList[id] then
			if oclDebug then print(">==", buffer.dataOCL, tostring(buffer)) end
			if buffer.__write then allocatedBuffersList[id].write = true end -- preserve write flag
		else
			if oclDebug then print("*==", buffer.dataOCL, tostring(buffer)) end
		end
	end
end

function process.freeBuffers()
	local n_kept = 0
	local n_removed = 0
	for k, v in pairs(allocatedBuffersList) do
		if not v.keep then
			if oclDebug then print("~~~", v.buffer.dataOCL, tostring(v.buffer)) end
			v.buffer:freeDev(v.write or v.buffer.__write)
			allocatedBuffersList[k] = nil
			n_removed = n_removed + 1
		else
			v.keep = false
			n_kept = n_kept + 1
		end
	end
	if n_kept>0 and oclDebug then print("=======", n_kept.." buffer(s) kept") end
end

function process.clearBuffers()
	for k, v in pairs(allocatedBuffersList) do
		v.buffer:freeDev()
		allocatedBuffersList[k] = nil
	end
end

return process
