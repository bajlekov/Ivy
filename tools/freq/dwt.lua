--[[
  Copyright (C) 2011-2018 G. Bajlekov

    ImageFloat is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ImageFloat is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

-- haar wavelet transform
-- expand with edge aware wavelets
-- expand with additional wavelets
-- expand with lifting scheme

local fwt = {}

fwt.haar = {}
fwt.lifted = {}
fwt.eaw = {}

-- FIXME: edge behavior when image is not divisible by 2

function fwt.lifted.forward(p1, p2, level, threadNum, threadMax)

end

-- TODO: merge horizontal and vertical loops
-- in-place interleaved representation
function fwt.haar.forward(p1, p2, level, threadNum, threadMax)
  local scale = 2^level

  if p1~=p2 and scale>1 then
    -- copy buffer to fill skipped values
    --TODO: use faster memory copy
    for z = 0, p1.z-1 do
      for y = threadNum, p1.y-1, threadMax do
        for x = 0, p1.x-1 do
          p2:set(x, y, z, p1:get(x, y, z))
        end
      end
    end
  end

  -- combined pass
  for z = 0, p1.z-1 do
    for y = threadNum*scale*2, p1.y-scale, threadMax*scale*2 do
      for x = 0, p1.x-scale, scale*2 do
        -- load
        local a = p1:get(x        , y        , z)
        local b = p1:get(x + scale, y        , z)
        local c = p1:get(x        , y + scale, z)
        local d = p1:get(x + scale, y + scale, z)
        -- horizontal pass
        a, b = (a + b)*0.5, (a - b)*0.5
        c, d = (c + d)*0.5, (c - d)*0.5
        -- vertical pass
        a, c = (a + c)*0.5, (a - c)*0.5
        b, d = (b + d)*0.5, (b - d)*0.5
        -- store
        p2:set(x        , y        , z, a)
        p2:set(x + scale, y        , z, b)
        p2:set(x        , y + scale, z, c)
        p2:set(x + scale, y + scale, z, d)
      end
    end
  end

  --[[
  -- horizontal pass
  for z = 0, p1.z-1 do
    for y = threadNum, p1.y-scale, threadMax*scale do
      for x = 0, p1.x-scale, scale*2 do
        local a = p1:get(x, y, z)
        local b = p1:get(x + scale, y, z)
        p2:set(x, y, z, (a + b)*0.5)
        p2:set(x + scale, y, z, (a - b)*0.5)
      end
    end
  end

  -- vertical pass
  for z = 0, p1.z-1 do
    for y = threadNum, p1.y-scale, threadMax*scale*2 do
      for x = 0, p1.x-scale, scale do
        local a = p2:get(x, y, z)
        local b = p2:get(x, y + scale, z)
        p2:set(x, y, z, (a + b)*0.5)
        p2:set(x, y + scale, z, (a - b)*0.5)
      end
    end
  end
  --]]
end

function fwt.haar.inverse(p1, p2, level, factor, threadNum, threadMax)
  local scale = 2^level

  if p1~=p2 and scale>1 then
    -- copy buffer to fill skipped values
    --TODO: use faster memory copy
    for z = 0, p1.z-1 do
      for y = threadNum, p1.y-1, threadMax do
        for x = 0, p1.x-1 do
          p2:set(x, y, z, p1:get(x, y, z))
        end
      end
    end
  end

  -- combined pass
  for z = 0, p1.z-1 do
    for y = threadNum*scale*2, p1.y-scale, threadMax*scale*2 do
      for x = 0, p1.x-scale, scale*2 do
        -- load
        local a = p1:get(x        , y        , z)
        local b = p1:get(x + scale, y        , z)
        local c = p1:get(x        , y + scale, z)
        local d = p1:get(x + scale, y + scale, z)
        -- get scaling factor
        local f = factor:get(x        , y        , z) +
                  factor:get(x + scale, y        , z) +
                  factor:get(x        , y + scale, z) +
                  factor:get(x + scale, y + scale, z)
        f = f*0.25
        -- horizontal pass
        a, b = (a + b*f), (a - b*f)
        c, d = (c + d*f), (c - d*f)
        -- vertical pass
        a, c = (a + c*f), (a - c*f)
        b, d = (b + d*f), (b - d*f)

        -- store
        p2:set(x        , y        , z, a)
        p2:set(x + scale, y        , z, b)
        p2:set(x        , y + scale, z, c)
        p2:set(x + scale, y + scale, z, d)
      end
    end
  end

  --[[
  -- horizontal pass
  for z = 0, p1.z-1 do
    for y = threadNum, p1.y-scale, threadMax*scale do
      for x = 0, p1.x-scale, scale*2 do
        local a = p1:get(x, y, z)
        local b = p1:get(x + scale, y, z)
        p2:set(x, y, z, a + b*factor)
        p2:set(x + scale, y, z, a - b*factor)
      end
    end
  end

  -- vertical pass
  for z = 0, p1.z-1 do
    for y = threadNum, p1.y-scale, threadMax*scale*2 do
      for x = 0, p1.x-scale, scale do
        local a = p2:get(x, y, z)
        local b = p2:get(x, y + scale, z)
        p2:set(x, y, z, a + b*factor)
        p2:set(x, y + scale, z, a - b*factor)
      end
    end
  end
  --]]
end


return fwt
