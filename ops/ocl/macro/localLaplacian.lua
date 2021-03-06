local ffi = require "ffi"
local data = require "data"
local downsize = require "tools.downsize"

local function init(proc)
  proc:loadSourceFile("localLaplacian.ivy", "pyr_c_2d.ivy")
end

local function execute(proc, I, D, R, O, lvl, post)
  post = post or post==nil
  -- allocate buffers
  local T = {}
  local G = {}
  local L = {}

  local n = 16

  local x, y, z = I:shape()

  T[1] = data:new(x, y, 1)
  L[1] = T[1]:new()
  for i = 2, n do
    T[i] = data:new(downsize(T[i-1]))
    L[i] = T[i]:new()
    G[i-1] = T[i]:new()
  end
  T[n+1] = data:new(downsize(T[n]))
  G[n] = T[n+1]:new()

  -- clear L output pyramid
  for i = 1, n do
    proc:executeKernel("zero_LL", proc:size2D(L[i]), {L[i]})
  end

  -- generate gaussian pyramid
  proc:executeKernel("pyrDown", proc:size2D(G[1]), {I, G[1]})
  for i = 2, n do
    proc:executeKernel("pyrDown", proc:size2D(G[i]), {G[i-1], G[i]})
  end

  local cl_m = ffi.new("cl_float[1]", 0) -- midpoint
  local cl_i = ffi.new("cl_int[1]", 0) -- current lvl
  local cl_lvl = ffi.new("cl_int[1]", lvl) -- max lvl

  -- loop over levels
  for i = 0, lvl do
    cl_m[0] = i/lvl
    cl_i[0] = i

    proc:executeKernel("transform", proc:size2D(I), {I, D, R, O, cl_m})

    -- generate transformed laplacian pyramid
    proc:executeKernel("pyrDown", proc:size2D(T[2]), {O, T[2]})
    proc:executeKernel("pyrUpL", proc:size2D(T[2]), {O, T[2], T[1]})
    for i = 2, n do
      proc:executeKernel("pyrDown", proc:size2D(T[i+1]), {T[i], T[i+1]})
      proc:executeKernel("pyrUpL", proc:size2D(T[i+1]), {T[i], T[i+1], T[i]})
    end

    -- apply appropriate laplacians from T to L according to G
    proc:executeKernel("apply_LL", proc:size2D(T[1]), {I, T[1], L[1], cl_i, cl_lvl})
    for i = 2, n do
      proc:executeKernel("apply_LL", proc:size2D(T[i]), {G[i-1], T[i], L[i], cl_i, cl_lvl})
    end

  end

  -- combine L + G pyramids
  for i = n, 2, -1 do
    proc:executeKernel("pyrUpG", proc:size2D(G[i]), {L[i], G[i], G[i-1], data.one})
  end
  proc:executeKernel("pyrUpG", proc:size2D(G[1]), {L[1], G[1], O, data.one})

  if post then
    proc:executeKernel("post_LL", proc:size2D(I), {I, O})
  end

  for i = 1, n do
    T[i]:free()
    T[i] = nil
    L[i]:free()
    L[i] = nil
    G[i]:free()
    G[i] = nil
  end
  T[n+1]:free()
  T[n+1] = nil
end

return{
  init = init,
  execute = execute,
}
