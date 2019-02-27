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

local process = require "lib.opencl.process"

local function init(d, c, q, name, filename)
  local proc = process.new()

  proc:init(d, c, q)
  proc:loadSourceFile(filename)

  local function execute()
    proc:getAllBuffers("in", "out")
		proc.buffers["in"].__write = false
		proc.buffers.out.__read = false
    proc:executeKernel(name, proc:size3D("out"))
  end

  return execute
end

return init
