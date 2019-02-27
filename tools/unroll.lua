--[[
  Copyright (C) 2011-2018 G. Bajlekov

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

local unroll = {}
unroll.meta = {}

local funStart = "return function(fun, ...) "
local funEnd = "end"

-- single dimension unroll 0..n-1 with variable number of parameters
local function construct(i)
	--print("constructing unroll["..i.."] function")
	local funTable = {}
	table.insert(funTable, funStart)
	for j = 0, i-1 do
		table.insert(funTable, "fun("..j..", ...) ")
	end
	table.insert(funTable, funEnd)
	return loadstring(table.concat(funTable))()
end

-- single dimension unroll 0..n-1 with fixed number of parameters
local function constructFixed(i, p)
	--print("constructing unroll["..i.."]["..p.."] function")
	local paramStr = ""
	if p>0 then
		paramStr = "p1"
		for i = 2, p do
			paramStr = paramStr..", p"..i
		end
	end
	local funStart = "return function(fun, "..paramStr..") "
	local funTable = {}
	table.insert(funTable, funStart)
	for j = 0, i-1 do
		table.insert(funTable, "fun("..j..", "..paramStr..") ")
	end
	table.insert(funTable, funEnd)
	return loadstring(table.concat(funTable))()
end

-- memoize fixed unroll functions
local fixed = {}
function unroll.fixed(i, p)
	if fixed[i]==nil then
		fixed[i] = {}
	end
	if fixed[i][p]==nil then
		fixed[i][p] = constructFixed(i, p)
	end
	return fixed[i][p]
end

-- memoize variable unroll functions, direct array access
-- do not unroll functions with more than 512 iterations
function unroll.meta.__index(self, k)
	if k>512 then
		return function(fun, ...)
			for i = 0, k-1 do
				fun(i, ...)
			end
		end
	elseif k>0 then
		self[k] = construct(k)
		return self[k]
	end
	error("Wrong loop length:"..k)
end
setmetatable(unroll, unroll.meta)

-- add functions for multidimensional unrolling
unroll.construct1 = function(i1, i2)
  local funTable = {}
  table.insert(funTable, funStart)
  for i = i1, i2 do
    table.insert(funTable, "fun("..i..", ...) ")
  end
  table.insert(funTable, funEnd)
  return loadstring(table.concat(funTable))()
end

unroll.construct2 = function(i1, i2, j1, j2)
  local funTable = {}
  table.insert(funTable, funStart)
  for i = i1, i2 do
    for j = j1, j2 do
      table.insert(funTable, "fun("..i..","..j..", ...) ")
    end
  end
  table.insert(funTable, funEnd)
  return loadstring(table.concat(funTable))()
end

unroll.construct3 = function(i1, i2, j1, j2, k1, k2)
  local funTable = {}
  table.insert(funTable, funStart)
  for i = i1, i2 do
    for j = j1, j2 do
      for k = k1, k2 do
        table.insert(funTable, "fun("..i..","..j..","..k..", ...) ")
      end
    end
  end
  table.insert(funTable, funEnd)
  return loadstring(table.concat(funTable))()
end

unroll.construct4 = function(i1, i2, j1, j2, k1, k2, l1, l2)
  local funTable = {}
  table.insert(funTable, funStart)
  for i = i1, i2 do
    for j = j1, j2 do
      for k = k1, k2 do
        for l = l1, l2 do
          table.insert(funTable, "fun("..i..","..j..","..k..","..l..", ...) ")
        end
      end
    end
  end
  table.insert(funTable, funEnd)
  return loadstring(table.concat(funTable))()
end

-- provide single function access with unrolling over up to 4 dimensions with variable indexing
function unroll.construct(i1, i2, j1, j2, k1, k2, l1, l2)
  if      l1 and l2 then return unroll.construct4(i1,i2,j1,j2,k1,k2,l1,l2)
  elseif  k1 and k2 then return unroll.construct3(i1,i2,j1,j2,k1,k2)
  elseif  j1 and j2 then return unroll.construct2(i1,i2,j1,j2)
  elseif  i1 and i2 then return unroll.construct1(i1,i2)
  else
    error("insufficient parameters")
  end
end

return unroll
