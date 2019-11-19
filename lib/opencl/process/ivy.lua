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

local ivy = require "lib.ivyscript"

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
	o.ivy = nil

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

function process:loadSourceString(s)
	assert(type(s) == "string")
	self.source = self.source .. s
	self.ivy = nil
	self.kernels = {}
end

function process:loadSourceFile(...)
	local s = ""
	for k, v in ipairs({...}) do
		local f = assert(io.open("ops/ocl/"..v, "rb"))
		s = s..f:read("*a")
		f:close()
	end
	self.source = self.source .. s
	self.ivy = nil
	self.kernels = {}
end

function process:clearSource()
	self.source = ""
	self.ivy = nil
	self.kernels = {}
end

do
	function process:getBuffer()
		local buf = dataCh:demand()
		assert(type(buf) == "table", buf)
		return data.fromChTable(buf)
	end

	function process:buffersReady()
		assert(dataCh:demand() == "execute")
	end

	-- get multiple buffers in a row without calling buffersReady, allowing for use of getBuffer before or after
	function process:getBuffers(n)
		local buffers = {}
		for i = 1, n do
			table.insert(buffers, self:getBuffer(v))
		end
		return unpack(buffers)
	end

	-- gets all buffers and calls buffersReady
	function process:getAllBuffers(n)
		local buffers = {}
		for i = 1, n do
			table.insert(buffers, self:getBuffer(v))
		end
		self:buffersReady()
		return unpack(buffers)
	end
end

local i32 = ffi.typeof("cl_int[1]")
local f32 = ffi.typeof("cl_float[1]")

function process:getKernel(name, buffers)
	if not self.ivy then
		self.ivy = ivy.new(self.source)
	end
	self.ivy:clear()
	for k, v in ipairs(buffers) do
		if type(v)=="cdata" then
			if ffi.istype(v, i32) then
				self.ivy:addInt()
			elseif ffi.istype(v, f32) then
				self.ivy:addFloat()
			end
		else
			self.ivy:addBuffer(v)
		end
	end

	local id = self.ivy:id(name)

	if self.kernels[id] then
		return self.kernels[id]
	else
		local source = self.ivy:generate(name)
		if #source>0 then
			local program = self.context:create_program_with_source(source)
			if not pcall(program.build, program, tools.buildParams) then
				messageCh:push{"error", "ERROR ["..name.."]: \n"..program:get_build_info(self.device, "log")}
				return nil
			else
				local kernel = program:create_kernel(name)
				self.kernels[id] = kernel
				return kernel
			end
		else
			messageCh:push{"error", "ERROR ["..name.."]: \nIvyScript unable to parse source!"}
			return nil
		end
	end
end

local function setArgs(kernel, buffers)
	local n = 0
	for k, v in ipairs(buffers) do
		if type(v)=="table" then
			assert(type(v.dataOCL)=="cdata")
			if oclDebug then print("["..(k-1).."]", b.dataOCL, tostring(b)) end
			kernel:set_arg(n, v.dataOCL)
			n = n + 1
			kernel:set_arg(n, v.strOCL)
		else
			assert(type(v)=="cdata")
			assert(ffi.istype(v, i32) or ffi.istype(v, f32))
			kernel:set_arg(n, v)
		end
		n = n + 1
	end
end

-- use uniform workgroup sizes, settings-selectable
function process:enqueueKernel(name, size, buffers)
	local kernel = self:getKernel(name, buffers)
	if not kernel then return end

	size[1] = size[1] or 1
	size[2] = size[2] or 1
	size[3] = size[3] or 1

	local workgroupSize = self.workgroupSize or workgroupSize
	local workgroup = {math.min(size[1], workgroupSize[1]), math.min(size[2], workgroupSize[2]), math.min(size[3], workgroupSize[3])}

	local sx = workgroup[1]
	local sy = workgroup[2]
	local sz = size[3]
	local px = size[1]%sx
	local py = size[2]%sy
	local ox = size[1] - px
	local oy = size[2] - py
	local oz = size[3] and 0 or nil

	setArgs(kernel, buffers)

	local event = {}
	event[1] = self.queue:enqueue_ndrange_kernel(kernel, nil, {ox, oy, sz}, workgroup)
	if px ~= 0 then
		workgroup[1] = px
		event[2] = self.queue:enqueue_ndrange_kernel(kernel, {ox, 0, oz}, {px, oy, sz}, workgroup)
		if py ~= 0 then
			workgroup[2] = py
			event[3] = self.queue:enqueue_ndrange_kernel(kernel, {ox, oy, oz}, {px, py, sz}, workgroup)
			workgroup[1] = sx
		end
	end
	if py ~= 0 then
		workgroup[2] = py
		event[4] = self.queue:enqueue_ndrange_kernel(kernel, {0, oy, oz}, {ox, py, sz}, workgroup)
	end

	if oclProfile then
		local time = 0
		for i = 1, 4 do
			if event[i] then
				time = time + tools.profile(name.."["..i.."]", event[i], self.queue, true)
			end
		end
		print("[OCL]"..name..": "..string.format("%.3fms", (time))) -- TODO: unify with profile print from lib.opencl.tools
		return time
	end
end

function process:executeKernel(kernel, size, buffers)
	if kernel then
		self:enqueueKernel(kernel, size, buffers)
	else
		error("No kernel supplied")
	end
end

function process:size2D(buf)
	return {buf.x, buf.y}
end

function process:size2Dmax(...)
	local x, y = 0, 0
	for k, v in ipairs{...} do
		if v.x > x then x = v.x end
		if v.y > y then y = v.y end
	end
	return {x, y}
end

function process:size3D(buf)
	return {buf.x, buf.y, buf.z}
end

function process:size3Dmax(...)
	local x, y, z = 0, 0, 0
	for k, v in ipairs{...} do
		if v.x > x then x = v.x end
		if v.y > y then y = v.y end
		if v.z > z then z = v.z end
	end
	return {x, y, z}
end

function process.profile()
	return oclProfile
end

return process
