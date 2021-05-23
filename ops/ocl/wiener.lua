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

local proc = require "lib.opencl.process.ivy".new()
local ffi = require "ffi"

local source = [[
-- adapted from https://github.com/prittt/AdaptiveWienerFilter
const G7 = {0.034044, 0.044388, 0.055560, 0.066762, 0.077014, 0.085288, 0.090673, 0.092542, 0.090673, 0.085288, 0.077014, 0.066762, 0.055560, 0.044388, 0.034044}

kernel wiener(I, W, O)
  const x = get_global_id(0)
  const y = get_global_id(1)
  const z = get_global_id(2)

  var pix = array(15, 15)
  for i = 0, 14 do
    for j = 0, 14 do
      pix[i, j] = I[x+i-7, y+j-7, z]
    end
  end

  var mean = 0.0
  for i = 0, 14 do
    for j = 0, 14 do
      mean = mean +  pix[i, j]*G7[i]*G7[j]
    end
  end

  var variance = 0.0
  for i = 0, 14 do
    for j = 0, 14 do
      variance = variance + (pix[i, j] - mean)^2*G7[i]*G7[j]
    end
  end

  var i = I[x, y, z]
  var w = W[x, y, z]^2*0.005

  if variance==0.0 then
    O[x, y, z] = I[x, y, z]
  else
    O[x, y, z] = mean + (i - mean)*max(0.0, variance - w)/variance
  end
end
]]

local function execute()
	local I, W, O = proc:getAllBuffers(3)
	proc:executeKernel("wiener", proc:size3D(O), {I, W, O})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
