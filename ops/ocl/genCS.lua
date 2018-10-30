--[[
  Copyright (C) 2011-2018 G. Bajlekov

    ImageFloat is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ImageFloat is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local process = require "lib.opencl.process"

local source = {}
for k, v in ipairs{"SRGB", "LRGB", "XYZ", "LAB", "LCH", "Y", "L"} do
  local f = assert(io.open("ops/ocl/cs_kernels_"..v..".cl", "rb"))
  source[v] = f:read("*a")
  f:close()
end

local function init(d, c, q, name)
  local proc = process.new()

  proc:init(d, c, q)
  proc:loadSourceString(source[name])

  local function execute()
    proc:getAllBuffers("in", "out")
		proc.buffers["in"].__write = false
		proc.buffers.out.__read = false
    proc:executeKernel(name, proc:size2D("out"))
  end

  return execute
end

return init
