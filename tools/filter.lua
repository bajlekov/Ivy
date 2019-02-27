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

local lut = require "tools.lut"

local filter = {}



filter.kernel = {}

-- hermite: a = -0.5
-- sinc: a = -1.0
-- continuous second derivative: -0.75
local a
function filter.kernel.cubic(x)
  assert(x>=0, x)
  assert(x<=2, x)
  if x<=1 then
    return (a+2)*x^3 - (a+3)*x^2 + 1
  else
    return a*x^3 - 5*a*x^2 + 8*a*x - 4*a
  end
end
a = -0.5
filter.kernel.cubic050LUT = lut.create(filter.kernel.cubic, 0, 2, 1024)
a = -0.75
filter.kernel.cubic075LUT = lut.create(filter.kernel.cubic, 0, 2, 1024)
a = -1.0
filter.kernel.cubic100LUT = lut.create(filter.kernel.cubic, 0, 2, 1024)

local sin = math.sin
local pi = math.pi

local a
function filter.kernel.lanczos(x)
  assert(x>=0, x)
  assert(x<=2, x)
  if x==0 then
    return 1
  else
    return (sin(pi*x)/(pi*x))*(sin(pi*x/a))/(pi*x/a)
  end
end
a = 2
filter.kernel.lanczos2LUT = lut.create(filter.kernel.lanczos, 0, 2, 1024)
a = 3
filter.kernel.lanczos3LUT = lut.create(filter.kernel.lanczos, 0, 2, 1024)



function filter.conv4(k, y0, y1, y2, y3, x)
  return y0*k(1+x) + y1*k(x) + y2*k(1-x) + y3*k(2-x)
end

function filter.conv4norm(k, y0, y1, y2, y3, x)
  local a, b, c, d = k(1+x), k(x), k(1-x), k(2-x)
  return (y0*a + y1*b + y2*c + y3*d)/(a+b+c+d)
end


function filter.cubic(...) return filter.conv4(filter.kernel.cubic050LUT, ...) end
function filter.lanczos(...) return filter.conv4norm(filter.kernel.lanczos2LUT, ...) end


-- optimized filters overwrite convolutional ones
function filter.cubic(y0, y1, y2, y3, x)
  local a = 0.5*(-y0 + 3*y1 -3*y2 +y3)
  local b = y0 -2.5*y1 + 2*y2 - 0.5*y3
  local c = 0.5*(-y0 + y2)
  local d = y1

  return a*x^3 + b*x^2 + c*x + d
end

function filter.linear(y0, y1, x)
  return y1*x + y0*(1-x)
end

return filter
