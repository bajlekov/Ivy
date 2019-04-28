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

local dataCh = love.thread.getChannel("dataCh_scheduler")
local syncCh = love.thread.getChannel("syncCh_scheduler")

local ops = {}
ops.meta = {}
setmetatable(ops, ops.meta)

local function register(name)
	ops[name] = require("ops.julia."..name)()
end

ops.meta.__index = function(t, k)
	register(k)
	return ops[k]
end

local data = require "data"

local julia = require "lib.julia"

local function getArray()
	local buf = dataCh:demand()
	assert(type(buf) == "table", buf)
	return julia.array(data.fromChTable(buf))
end

-- mean
do
	local fun = julia.evalString [[
		using Statistics

		function(a, b)
			for z = 1:size(a, 3)
				b[1, 1, z] = mean(view(a, :, :, z))
			end
		end
	]]
	julia.gcPush(mul)

	function ops.stat_mean()
		debug.tic()
		local a = getArray()
		local b = getArray()
		assert(dataCh:demand()=="execute")
		julia.evalFunction(fun, a, b)
		debug.toc("jl_stat_mean")
	end
end


return ops
