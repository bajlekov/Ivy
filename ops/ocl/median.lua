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

local source = [==[
const A = {1,4,7,0,3,6,1,4,7,0,5,4,3,1,2,4,4,6,4}
const B = {2,5,8,1,4,7,2,5,8,3,8,7,6,4,5,7,2,4,2}

function swap(pix, idx)
  if pix[A[idx]] < pix[B[idx]] then
    var t = pix[B[idx]]
    pix[B[idx]] = pix[A[idx]]
    pix[A[idx]] = t
  end
end

kernel median(I, O)
  const x = get_global_id(0)
  const y = get_global_id(1)
  const z = get_global_id(2)

  var pix = array(9)

  pix[0] = I[x - 1, y - 1, z]
  pix[1] = I[x + 0, y - 1, z]
  pix[2] = I[x + 1, y - 1, z]
  pix[3] = I[x - 1, y + 0, z]
  pix[4] = I[x + 0, y + 0, z]
  pix[5] = I[x + 1, y + 0, z]
  pix[6] = I[x - 1, y + 1, z]
  pix[7] = I[x + 0, y + 1, z]
  pix[8] = I[x + 1, y + 1, z]

  for idx = 0, 18 do
    swap(pix, idx)
  end

  O[x, y, z] = pix[4]
end
]==]

local function execute()
  local I, O = proc:getAllBuffers(2)
  proc:executeKernel("median", proc:size3D(O), {I, O})
end

local function init(d, c, q)
  proc:init(d, c, q)
  proc:loadSourceString(source)
  return execute
end

return init
