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
local data = require "data"

local localLaplacianMacro = require "ops.ocl.macro.localLaplacian"

local source = [[
kernel curveY(I, C, L, O)
  const x = get_global_id(0)
  const y = get_global_id(1)

  var i = I[x, y]
  var j = clamp(i.y, 0.0, 1.0)
  if L[0]>0.5 then
    j = YtoL(j)
  end

  var lowIdx = clamp(int(floor(j*255)), 0, 255)
	var highIdx = clamp(int(ceil(j*255)), 0, 255)

	var lowVal = C[lowIdx]
	var highVal = C[highIdx]

  var factor = 0.0
  if lowIdx==highIdx then
    factor = 1.0
  else
    factor = j*255.0-lowIdx
  end

  if L[0]>0.5 then
    i = i * LtoY(mix(lowVal, highVal, factor)) / i.y
  else
    i = i * mix(lowVal, highVal, factor) / i.y
  end

  O[x, y] = max(i, 0.0)
end

kernel mixDetail(B, D1a, D1b, D2a, D2b, O)
  const x = get_global_id(0)
  const y = get_global_id(1)

  var b = B[x, y].L
  var d1a = D1a[x, y].L
  var d1b = D1b[x, y].L
  var d2a = D2a[x, y].L
  var d2b = D2b[x, y].L

  var d1 = d1a - d1b
  var d2 = d2a - d2b
  var a = d1^2 / (d1^2 + d2^2)

  var o = b + a*d1 + (1-a)*d2
  var o_y = LtoY(o)
  var i = D2a[x, y]
  O[x, y] = i*o_y/i.y
end
]]

local function execute()
  local I, C, L, O = proc:getAllBuffers(4)
  local D = data:new(1, 1, 1):set(0, 0, 0, -1):syncDev()
  local R = data:new(1, 1, 1):set(0, 0, 0, 0.1):syncDev()

  -- prefixes:
  -- t: transformed by curve function
  -- l: low-pass using local laplacian operator

  local tI = I:new():set_cs("XYZ")
  local ltI = I:new():set_cs("XYZ")
  local lI = I:new():set_cs("XYZ")
  local tlI = I:new():set_cs("XYZ")
  print(O.cs)
  proc:executeKernel("curveY", proc:size2D(tI), {I, C, L, tI})
  localLaplacianMacro.execute(proc, tI, D, R, ltI, 31)
  localLaplacianMacro.execute(proc, I, D, R, lI, 31)
  proc:executeKernel("curveY", proc:size2D(tlI), {lI, C, L, tlI})

  -- obtain details before and after transform
  -- mix details proportional to magnitude^2

  -- detail mixing:
  -- base: tlI or ltI
  -- d1a: tI
  -- d1b: ltI
  -- d2a: I
  -- d2b: lI

	proc:executeKernel("mixDetail", proc:size2D(O), {ltI, tI, ltI, I, lI, O})

  tI:free()
  ltI:free()
  lI:free()
  tlI:free()
  tI = nil
  ltI = nil
  lI = nil
  tlI = nil
end

local function init(d, c, q)
	proc:init(d, c, q)
  localLaplacianMacro.init(proc)
	proc:loadSourceString(source)
	return execute
end

return init
