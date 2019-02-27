--[[
  Copyright (C) 2011-2018 G. Bajlekov

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

local function parse(parseType, device, context, queue)
	local menuRegister = device

	local f = io.open("ops/ocl/custom/list.txt", "r")
	assert(f, "ERROR: list.txt not found!")

	for l in f:lines() do
		l = l:match("^%W*(.-)%W*$")

		local file = l
		local name = l:gsub("%.cl$", "")

		local f, e = assert(io.open("ops/ocl/custom/"..l, "r"))
		local s = f:read("*all")
		f:close()

		local spec = s:match("/%*%s*(.-)%s*%*/")
		local cs = spec and spec:match("colorspace%W*=%W*(%w+)") or "LRGB"
		local fullName = spec and spec:match('name%W*=%W*"([^%"]*)"') or name
		local params = {}
		if spec then
			for k, v in spec:gmatch("[IOPT](%d+)%W*=%W*(%b{})") do
				assert(not params[tonumber(k)], "ERROR: Overwriting parameter specification at index "..k)
				params[tonumber(k)] = loadstring("return"..v)()
			end
		end

		local signature = s:match("kernel%W*void%W*"..name.."%W*(%b())")
		assert(signature, "Custom kernel should have the same name as the file it is in: '"..name.."'!")
		signature = signature:sub(2, - 2)..","
		local args = {}
		local argOut = nil
		for a in signature:gmatch("global%W*float%W*%*%W*(%w+)%W*,") do
			if not argOut and a:sub(1, 1) == "O" then argOut = a end
			table.insert(args, a)
		end
		assert(argOut, "ERROR: no kernel output defined")

		local dim0 = s:match("get_global_id%W*%(%W*0%W*%)") and true or false
		local dim1 = s:match("get_global_id%W*%(%W*1%W*%)") and true or false
		local dim2 = s:match("get_global_id%W*%(%W*2%W*%)") and true or false

		if parseType == "ocl" then
			local ops = require "thread.workerDev"
			local proc = require "lib.opencl.process".new()

			proc:init(device, context, queue)
			proc:loadSourceFile("custom/"..file)

			ops["__custom_"..name] = function()
				proc:getAllBuffers(unpack(args))
				proc:executeKernel(name, proc[dim2 and "size3D" or "size2D"](proc, unpack(args)))
			end
		end

		if parseType == "node" then
			-- create spec and use it
			local spec = {
				name = fullName,
				procName = "__custom_"..name
			}

			spec.input = {}
			spec.output = {}
			spec.param = {}
			spec.temp = {}

			for k, v in ipairs(args) do
				local t, n = v:match("([IOPT])(%d*)")
				assert(t, "ERROR: Invalid kernel argument name \""..v.."\" in  file \""..file.."\"")
				n = tonumber(n) or 0

				if t == "I" then
					assert(spec.input[n] == nil)
					assert(spec.param[n] == nil or spec.param[n].type == "text")
					assert(spec.temp[n] == nil)
					spec.input[n] = {cs = cs, arg = k}
					if n > 0 then spec.param[n] = params[n] or {type = "text", left = "Input "..n} end
				elseif t == "P" then
					assert(spec.input[n] == nil)
					assert(spec.param[n] == nil or spec.param[n].type == "text")
					assert(spec.temp[n] == nil)
					spec.input[n] = {cs = "Y", arg = k}
					if n > 0 then spec.param[n] = params[n] or {type = "float", name = "Param "..n, min = 0, max = 1, default = 0} end
				elseif t == "T" then
					assert(spec.input[n] == nil)
					assert(spec.param[n] == nil)
					assert(spec.temp[n] == nil)
					spec.temp[n] = {shape = "image", arg = k}
				elseif t == "O" then
					spec.output[n] = {cs = cs, arg = k}
					if (not spec.param[n]) and n > 1 then
						spec.param[n] = params[n] or {type = "text", right = "Output "..n}
					end
				end
			end

			local ops = require "ops"
			local tools = require "ops.tools"
			tools.register(ops, spec)

			if menuRegister then
				local overlay = require "ui.overlay"
				local overlayCustom = overlay.defaultFrame.elem[9].frame
				overlayCustom:addElem("addNode", overlayCustom.elem.n + 1, fullName, {ops, "__custom_"..name})
			end

		end
	end

	f:close()
end

return parse
