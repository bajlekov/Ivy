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

local ffi = require "ffi"
local data = require "data"
local downsize = require "tools.downsize"

local function init(proc)
  proc:loadSourceFile("pyr.ivy")
end

local function execute(proc, I, O, n)
  local G = {}
  
	G[0] = I
	for i = 1, n do
		G[i] = data:new(downsize(G[i-1]:shape()))
		proc:executeKernel("pyrDown", proc:size3D(G[i]), {G[i-1], G[i]})
	end

	G[0] = O
	for i = n, 1, -1 do
		proc:executeKernel("pyrUp", proc:size3D(G[i]), {G[i], G[i-1]})
		G[i]:free()
		G[i] = nil
	end
end

return{
  init = init,
  execute = execute,
}
