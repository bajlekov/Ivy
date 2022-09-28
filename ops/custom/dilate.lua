local proc = require "lib.opencl.process.ivy".new()

local source = [==[
kernel dilate(I, O)
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

  var m = pix[0]
  for idx = 1, 8 do
    m = max(m, pix[idx])
  end

  O[x, y, z] = m
end
]==]

local function execute()
  local I, O = proc:getAllBuffers(2)
  proc:executeKernel("dilate", proc:size3D(O), {I, O})
end

local function init(d, c, q)
  proc:init(d, c, q)
  proc:loadSourceString(source)
  return execute
end

return init