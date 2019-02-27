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

package.path = './?.lua;./?/init.lua;' .. package.path

assert(jit, "LuaJIT is required")

-- disable stdout buffer
io.stdout:setvbuf('no')

-- set up debugging link if enabled
if os.getenv('DEBUG_MODE') then
	require 'debugger'()
	require 'debugger.plugins.ffi'
end

-- optimize parameters
jit.opt.start("sizemcode=8000")

-- start profiler
--require("jit.p").start("Fl5-5i1m1v", "profile.txt")
--require("jit.v").start("verbose.txt")
--require("jit.dump").start("tbT", "dump.txt")
--debug.see(jit)

-- prevent global definitions
do
	function _G.global(k, v) -- assign new global
		rawset(_G, k, v or false)
	end
	local function newGlobal(t, k, v) -- disable globals
		print(debug.traceback())
		error("global assignment not allowed: "..k)
	end
	setmetatable(_G, {__newindex = newGlobal})
end

-- helper functions
function table.empty(t) return next(t) == nil end

function table.copy(i)
	local o = {}
	for k, v in pairs(i) do
		o[k] = v
	end
  return o
end

require "tools.math"

love.filesystem.setIdentity("Ivy")

-- expand debug library
require "tools.debug"
