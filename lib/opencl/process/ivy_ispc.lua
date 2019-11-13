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

local generator = require "lib.ivyscript"

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
	local o = {
		source = "",
		generator = nil,
		kernels = {}
	}
	setmetatable(o, process.meta)
	return o
end

function process:init() end

function process:setWorkgroupSize(size)
	self.workgroupSize = size
end

function process:loadSourceString(s)
	assert(type(s) == "string")
	self.source = self.source .. s
	self.generator = nil
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
	self.generator = nil
	self.kernels = {}
end

function process:clearSource()
	self.source = ""
	self.generator = nil
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

local i32 = ffi.typeof("int[1]")
local f32 = ffi.typeof("float[1]")

local function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then
		 io.close(f)
		 return true
	 else
		 return false
	 end
end

ffi.load("lib/ispc/chkstk.dll")
ffi.load("lib/ispc/tasksys.dll")

function process:getKernel(name, buffers)
	if not self.generator then
		self.generator = generator.new(self.source, "ISPC")
	end
	self.generator:clear()
	local decl = {}
	for k, v in ipairs(buffers) do
		if type(v)=="cdata" then
			if ffi.istype(v, i32) then
				self.generator:addInt()
				decl[k] = "int"
			elseif ffi.istype(v, f32) then
				self.generator:addFloat()
				decl[k] = "float"
			end
		else
			self.generator:addBuffer(v)
			decl[k] = "float *"
		end
	end

	local id = self.generator:id(name)

	decl = "void "..id.."(int *, "..table.concat(decl, ", ")..");"

	if self.kernels[id] then
		return self.kernels[id], id
	else
		local source = self.generator:generate(name)
		if #source>0 then
			local f = io.open("___temp.ispc", "wb")
			f:write(source)
			f:close()

			os.execute("lib\\ispc\\ispc ___temp.ispc -o ___temp.o -O3 --wno-perf --opt=fast-math --math-lib=fast -Iops/ocl/")
			if not file_exists("___temp.o") then
				messageCh:push{"error", "ERROR ["..name.."]: \nISPC unable to compile source!"}
				return nil
			end
			os.remove("___temp.ispc")

			os.execute("g++ -shared lib/ispc/chkstk.dll lib/ispc/tasksys.dll ___temp.o -o ISPCcache/"..id..".dll")
			if not file_exists("ISPCcache/"..id..".dll") then
				messageCh:push{"error", "ERROR ["..name.."]: \nGCC unable to link object!"}
				return nil
			end
			os.remove("___temp.o")

			local kernel = ffi.load("ISPCcache/"..id..".dll")
			ffi.cdef(decl)

			self.kernels[id] = kernel
			return kernel, id
		else
			messageCh:push{"error", "ERROR ["..name.."]: \nIvyScript unable to parse source!"}
			return nil
		end
	end
end

local function args(buffers)
	local args = {}
	for k, v in ipairs(buffers) do
		if type(v)=="table" then
			assert(type(v.data)=="cdata")
			args[k] = v.data
		else
			assert(type(v)=="cdata")
			assert(ffi.istype(v, i32) or ffi.istype(v, f32))
			args[k] = v[0]
		end
	end
	return unpack(args)
end


-- use uniform workgroup sizes, settings-selectable
local dim = ffi.new("int[9]")
dim[0] = 0 -- offset x
dim[1] = 0 -- offset y
dim[2] = 0 -- offset z
dim[6] = 512 -- workgroup x
dim[7] = 512 -- workgroup y
dim[8] = 1

function process:enqueueKernel(name, size, buffers)
	local kernel, id = self:getKernel(name, buffers)
	if not kernel then return end

	dim[3] = size[1] or 1
	dim[4] = size[2] or 1
	dim[5] = size[3] or 1

	local t1 = love.timer.getTime()
	kernel[id](dim, args(buffers))
	local t2 = love.timer.getTime()

	if oclProfile then
		local time = t2 - t1
		print("[ISPC]"..name..": "..string.format("%.3fms", (time*1000)))
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
