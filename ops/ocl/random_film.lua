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

local messageCh = love.thread.getChannel("messageCh")

local source = [[
function count(A, N)
  var sum = 0
  for i = 0, N-1 do
    for j = 0, N-1 do
      sum = sum + A[i, j]
    end
  end
  return sum
end

function all(A, N)
  for i = 0, N-1 do
    for j = 0, N-1 do
      if A[i, j]==false then
        return false
      end
    end
  end
  return true
end

kernel random(I, L, G, HQ, V, D, FF, O, seed)
  const x = get_global_id(0)
  const y = get_global_id(1)
  const z = get_global_id(2)

  var key = seed + z

  var N = 8
  if HQ[0]>0.5 then
    N = 128
  end

  var sample = bool_array(128, 128)

  for i = 0, N-1 do
    for j = 0, N-1 do
      sample[i, j] = 0
    end
  end

  var ff = int((FF[0]-1)*0.5)

  for px = -ff, ff do
    for py = -ff, ff do

      var idx = x+px + I.x*(y+py)

      var v = I[x+px, y+py, z]
      var l = (L[x+px, y+py, z]*100)^2
      var n = int(rpois(key, idx, v*l))

      var ro = (G[x+px, y+py, z]*0.5)^2*N
      var rv = V[x+px, y+py, z]

      var diffusion = max(D[x+px, y+py, z], 0.05)

      var c = 0
      for k = 1, n do
        var ox = (rnorm(key, idx, k)*diffusion + px + 0.5) * N
        var oy = (rnorm(key, idx, k+n)*diffusion + py + 0.5) * N

        var r = 0.0
        if rv>0.001 then
          r = abs(ro + rv*ro*rnorm(key, k, idx))
        else
          r = ro
        end
        r = min(r, float(ff*N))
        var r2 = r^2

        if ox>-r and ox<N+r and oy>-r and oy<N+r then

          var imin = max(int(ceil(ox-r)), 0)
          var imax = min(int(ceil(ox+r)), N-1)
          var jmin = max(int(ceil(oy-r)), 0)
          var jmax = min(int(ceil(oy+r)), N-1)

          for i = imin, imax do
            for j = jmin, jmax do
              var d2 = (ox-i+0.5)^2 + (oy-j+0.5)^2
              if d2<r2 then
                sample[i, j] = 1
              end
            end
          end

        end

        c = c + 1
        if c==256 then
          if all(sample, N) then
            break
          end
          c = 0
        end

      end

    end
  end

  O[x, y, z] = float(count(sample, N))/(N*N)
end
]]

local function execute()
	local I, L, G, HQ, V, D, FF, O = proc:getAllBuffers(8)
  local seed = ffi.new("int[1]", math.random(-2147483648, 2147483647))

  local size = proc:size3D(O)
  local x, y, z = size[1], size[2], size[3]

  proc:setWorkgroupSize({8, 8, 1})

  local s = 256
  for ox = 0, x-1, s do
    for oy = 0, y-1, s do
      local sx = math.min(s, x-ox)
      local sy = math.min(s, y-oy)
  	  proc:executeKernel("random", {sx, sy, z}, {ox, oy, 0}, {I, L, G, HQ, V, D, FF, O, seed})

      messageCh:push{"info", ("[Film Grain]: %.1f%%"):format((ox*y + oy*sx)/(x*y)*100)}
      proc.queue:finish()
    end
  end
  messageCh:push{"info", ""}
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
