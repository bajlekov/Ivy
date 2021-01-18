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

local proc = require "lib.opencl.process.ivy".new()

-- TODO: convert to LMS ratios

local source = [[
const M = {
  { 0.8951000,  0.2664000, -0.1614000},
  {-0.7502000,  1.7135000,  0.0367000},
  { 0.0389000, -0.0685000,  1.0296000}
}

function lms(i)
  var o = vec(0.0)
  o.x = M[0, 0]*i.x + M[0, 1]*i.y + M[0, 2]*i.z
  o.y = M[1, 0]*i.x + M[1, 1]*i.y + M[1, 2]*i.z
  o.z = M[2, 0]*i.x + M[2, 1]*i.y + M[2, 2]*i.z
  return o
end

kernel sample(I, P, S)
  const x = P[0]
  const y = P[1]

  var s = vec(0.0)
	for i = -2, 2 do
		for j = -2, 2 do
			s = s + I[x+i, y+j]
    end
  end

  s = s/25.0
  s = s/s.y
  const wp = vec(0.95047, 1.0, 1.08883)

  S[0, 0] = lms(wp)/lms(s)
end
]]

local function execute()
	local I, P, S = proc:getAllBuffers(3)
	proc:executeKernel("sample", {1, 1}, {I, P, S})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
