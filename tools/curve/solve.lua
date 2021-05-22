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

local solve = {}

--[[
adapted from:
https://kluge.in-chemnitz.de/opensource/spline/
https://github.com/ttk592/spline/
Copyright (C) 2011, 2014, 2016, 2021 Tino Kluge (ttk448 at gmail.com)
Licensed under GPL 2+
--]]
local function lu_decompose(A) -- limited to a tridiagonal matrix!!
  local n = #A.d
  for i = 1, n do -- pre-condition A
    local norm = 1/A.d[i]
    A.l[i] = A.l[i]*norm
    A.u[i] = A.u[i]*norm
    A.d[i] = 1
    A.n[i] = norm
  end
  for i = 1, n-1 do
    A.l[i+1] = A.l[i+1]/A.d[i]
    A.d[i+1] = A.d[i+1] - A.l[i+1]*A.u[i]
  end
end

local function l_solve(A, b)
  local n = #A.d
  local x = {}
  x[1] = 0
  for i = 2, n do
    x[i] = b[i]*A.n[i] - A.l[i]*x[i-1]
  end
  return x
end

local function r_solve(A, b)
  local n = #A.d
  local x = {}
  x[n] = 0
  for i = n-1, 1, -1 do
    x[i] = (b[i] - A.u[i]*x[i+1] ) / A.d[i]
  end
  return x
end

function solve.lu(A, b) -- tridiagonal matrix
  lu_decompose(A)
  local x = l_solve(A, b)
  local x = r_solve(A, x)
  return x
end


-- adapted from https://en.wikipedia.org/wiki/Gaussian_elimination
function solve.gauss(A, b) -- full matrix
  local m = #A
  local n = m + 1

  for i = 1, m do
    A[i][n] = b[i]
  end

  local h = 1
  local k = 1
  while h <= m and k <= n do

    local i_max = -math.huge
    local max = -math.huge
    for i = h, m do
      if math.abs(A[i][k]) > max then
        max = math.abs(A[i][k])
        i_max = i
      end
    end

    if A[i_max][k] == 0 then
      k = k + 1
    else
      -- swap rows h, i_max
      for j = 1, n do
        A[h][j], A[i_max][j] = A[i_max][j], A[h][j]
      end

      for i = h + 1, m do
        local f = A[i][k] / A[h][k]
        A[i][k] = 0
        for j = k + 1, n do
          A[i][j] = A[i][j] - A[h][j] * f
        end
      end

      h = h + 1
      k = k + 1
    end
  end

  for i = m, 1, -1 do
    -- divide row
    if A[i][i]~=0 then
      A[i][n] = A[i][n] / A[i][i]
      A[i][i] = 1
    end

    -- subtract row
    for k = i-1, 1, -1 do
      A[k][n] = A[k][n] - A[i][n] * A[k][i]
      A[k][i] = 0
    end
  end

  for i = 1, m do
    b[i] = A[i][n]
    A[i][n] = nil
  end

  return b
end

return solve
