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

--[[
0x4949 | 0x4D4D : Intel | Motorola
0x2A00 : usually for tiff header
0x???????? : IFD0 offset
]]

--[[
standard tags to get:

Make
Model
Lens
Focal length
Mode
Exp. comp.
Shutter
Aperture
ISO
Date taken
--]]

local ffi = require "ffi"

-- byte align
local exifData
local exifLE = false
local function endianness(v)
  if v == 0x4949 then
    exifLE = true
  elseif v == 0x4D4D then
    exifLE = false
  else
    error("no valid endianness value supplied: "..v)
  end
end

local function read16(o)
  if exifLE then
    return exifData[o + 0] + exifData[o + 1]*2^8
  else
    return exifData[o + 0]*2^8 + exifData[o + 1]
  end
end

local function read32(o)
  if exifLE then
    return exifData[o + 0] + exifData[o + 1]*2^8 + exifData[o + 2]*2^16 + exifData[o + 3]*2^24
  else
    return exifData[o + 0]*2^24 + exifData[o + 1]*2^16 + exifData[o + 2]*2^8 + exifData[o + 3]
  end
end

-- helper functions
local function hex(v)
  return ("0x%04x"):format(v)
end

local exifRead = {}

function exifRead.ASCII(o)
  local n = read32(o + 4)
  if n > 4 then
    local a = read32(o + 8)
    return ffi.string(exifData + a, n)
  else
    return ffi.string(exifData + o + 8, n)
  end
end

function exifRead.UByte(o)
  local n = read32(o + 4)
  if n == 1 then
    return exifData[o + 8]
  else
    return "UByte["..n.."]"
  end
end

function exifRead.UShort(o)
  local n = read32(o + 4)
  if n == 1 then
    return read16(o + 8)
  else
    return "UShort["..n.."]"
  end
end

function exifRead.ULong(o)
  local n = read32(o + 4)
  if n == 1 then
    return read32(o + 8)
  else
    return "ULong["..n.."]"
  end
end

function exifRead.URational(o)
  local n = read32(o + 4)
  local a = read32(o + 8)
  if n == 1 then
    return read32(a).."/"..read32(a + 4)
  else
    return "URational["..n.."]"
  end
end



local exifType = {
  [1] = "UByte",
  [2] = "ASCII",
  [3] = "UShort",
  [4] = "ULong",
  [5] = "URational",
  [6] = "Byte",

  [8] = "Short",
  [9] = "Long",
  [10] = "Rational",
  [11] = "Float",
  [12] = "Double",
  [13] = "Maker",
}
local meta = {
  __index = function(t, k)
    return "(Type: "..k..")"
  end
}
setmetatable(exifType, meta)


-- read file
local f = io.open("/home/galin/Desktop/P9279827.ORF", "rb")
local s = f:read("*a")
f:close()
exifData = ffi.new("uint8_t[?]", #s, s)

print(("0x%02x, 0x%02x, 0x%02x, 0x%02x"):format(exifData[0], exifData[1], exifData[2], exifData[3]))

endianness(read16(0))

local baseAddr = read32(4) -- base offset

local function parseIFD(offset)
  local numEntries = read16(offset)
  print("Number of entries: "..numEntries)
  local offset = offset + 2
  for i = 1, numEntries do
    local tag = read16(offset)
    local type = exifType[read16(offset + 2)]
    local size = read32(offset + 4)
    local value = read32(offset + 8)
    if exifRead[type] then
      print(hex(tag), exifRead[type](offset))
    else
      print(hex(tag), type, hex(size), hex(value))
    end
    offset = offset + 12
  end
  return read32(offset)
end

-- next ifd
print(hex(parseIFD(baseAddr)))
print(hex(parseIFD(0x10A)))


--[[
EEEE 	No. of directory entry
TTTT 	ffff 	NNNNNNNN 	DDDDDDDD 	Entry 0
TTTT 	ffff 	NNNNNNNN 	DDDDDDDD 	Entry 1
. . . . . . . . . 	. . . . . .
TTTT 	ffff 	NNNNNNNN 	DDDDDDDD 	Entry EEEE-1
LLLLLLLL 	Offset to next IFD
--]]

--os.exit(true)
