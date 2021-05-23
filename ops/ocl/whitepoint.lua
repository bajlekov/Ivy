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

-- adjust color to a new whitepoint expressed as a LMS multiplyer P

-- forward and inverse Bradford matrices
-- http://www.brucelindbloom.com/index.html?Eqn_ChromAdapt.html
local source = [[
const M = {
  { 0.8951000,  0.2664000, -0.1614000},
  {-0.7502000,  1.7135000,  0.0367000},
  { 0.0389000, -0.0685000,  1.0296000}
}

const M_1 = {
  { 0.9869929, -0.1470543,  0.1599627},
  { 0.4323053,  0.5183603,  0.0492912},
  {-0.0085287,  0.0400428,  0.9684867}
}

kernel whitepoint(I, P, O)
  const x = get_global_id(0)
  const y = get_global_id(1)

  var i = I[x, y]
	var p = P[0, 0]

	var lms = vec(0.0)
	lms.x = M[0, 0]*i.x + M[0, 1]*i.y + M[0, 2]*i.z
	lms.y = M[1, 0]*i.x + M[1, 1]*i.y + M[1, 2]*i.z
	lms.z = M[2, 0]*i.x + M[2, 1]*i.y + M[2, 2]*i.z

	lms = lms*p

	var o = vec(0.0)
	o.x = M_1[0, 0]*lms.x + M_1[0, 1]*lms.y + M_1[0, 2]*lms.z
	o.y = M_1[1, 0]*lms.x + M_1[1, 1]*lms.y + M_1[1, 2]*lms.z
	o.z = M_1[2, 0]*lms.x + M_1[2, 1]*lms.y + M_1[2, 2]*lms.z

  O[x, y] = o
end
]]

local function execute()
	local I, P, O = proc:getAllBuffers(3)
	proc:executeKernel("whitepoint", proc:size2D(O), {I, P, O})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
