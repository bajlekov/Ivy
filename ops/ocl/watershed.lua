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

-- separable watershed filter

--[[

- input markers M: 1 = source, 0 = empty
- output mask O, init: 0 =  source, INF = empty => (0, 1)
- gradient map G: sum of gradients




--]]

local ffi = require "ffi"
local proc = require "lib.opencl.process.ivy".new()
local data = require "data"

local source = [[
const eps = 0.0001

kernel preprocess(I, M1, M2, G, O)
  const x = get_global_id(0)
  const y = get_global_id(1)

  if M1[x, y] > 0.5 then
    if M2[x, y] > 0.5 then
      O[x, y] = 0.0
    else
      O[x, y] = 1.0
    end
  else
    if M2[x, y] > 0.5 then
      O[x, y] = -1.0
    else
      O[x, y] = 0.0
    end
  end

  var in0 = I[x-1, y]
  var ip0 = I[x+1, y]
  var i00 = I[x, y]
  var i0n = I[x, y-1]
  var i0p = I[x, y+1]

  var grad =
    (in0.x-i00.x)^2 + (i00.x-ip0.x)^2 +
    (in0.y-i00.y)^2 + (i00.y-ip0.y)^2 +
    (in0.z-i00.z)^2 + (i00.z-ip0.z)^2 +

    (i0n.x-i00.x)^2 + (i00.x-i0p.x)^2 +
    (i0n.y-i00.y)^2 + (i00.y-i0p.y)^2 +
    (i0n.z-i00.z)^2 + (i00.z-i0p.z)^2

  G[x, y] = 1.0/(1.0 + grad)
end

kernel horizontal(G, O)
	const y = get_global_id(1)

  var last = O[0, y]
  var last_sign = sign(last)

	for x = 0, O.x-1 do
    var grad = G[x, y]
    var curr = O[x, y]
    var curr_sign = sign(curr)

    var new = min(grad, max(abs(last), abs(curr)))
    var new_sign = 1.0

    if abs(curr) >= abs(last) then
      new_sign = curr_sign
    else
      new_sign = last_sign
    end
    new = new * new_sign

    last = new
    last_sign = new_sign
    O[x, y] = new
	end


	for x = O.x - 1, 0, -1 do
    var grad = G[x, y]
    var curr = O[x, y]
    var curr_sign = sign(curr)

    var new = min(grad, max(abs(last), abs(curr)))
    var new_sign = 1.0

    if abs(curr) >= abs(last) then
      new_sign = curr_sign
    else
      new_sign = last_sign
    end
    new = new * new_sign

    last = new
    last_sign = new_sign
    O[x, y] = new
	end
end

kernel vertical(G, O)
	const x = get_global_id(0)

  var last = O[x, 0]
  var last_sign = sign(last)

	for y = 0, O.y-1 do
    var grad = G[x, y]
    var curr = O[x, y]
    var curr_sign = sign(curr)

    var new = min(grad, max(abs(last), abs(curr)))
    var new_sign = 1.0

    if abs(curr) >= abs(last) then
      new_sign = curr_sign
    else
      new_sign = last_sign
    end
    new = new * new_sign

    last = new
    last_sign = new_sign
    O[x, y] = new
	end

	for y = O.y - 1, 0, -1 do
    var grad = G[x, y]
    var curr = O[x, y]
    var curr_sign = sign(curr)

    var new = min(grad, max(abs(last), abs(curr)))
    var new_sign = 1.0

    if abs(curr) >= abs(last) then
      new_sign = curr_sign
    else
      new_sign = last_sign
    end
    new = new * new_sign

    last = new
    last_sign = new_sign
    O[x, y] = new
	end
end

kernel postprocess(O)
  const x = get_global_id(0)
  const y = get_global_id(1)

  var o = O[x, y]
  if o<0 then
    O[x, y] = 0.0
  else
    O[x, y] = 1.0
  end

end

]]

local function execute()
	local I, M1, M2, O, HQ = proc:getAllBuffers(5)

  local x, y, z = O:shape()
  local G = O:new()

	proc:executeKernel("preprocess", proc:size2D(O), {I, M1, M2, G, O})

	for i = 1, HQ:get(0, 0, 0)>0.5 and 100 or 10 do
    proc:executeKernel("vertical", {x, 1}, {G, O})
    proc:executeKernel("horizontal", {1, y}, {G, O})
	end

  G:free()

  proc:executeKernel("postprocess", proc:size2D(O), {O})

end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
