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

local ffi = require "ffi"

local exif = {}

local exifTags = {
  [0x010F] = "Make",
  [0x0110] = "Model",
  --[0x0112] = "Orientation",
  [0x0132] = "CreateDate",
  --[0x013B] = "Artist",
  --[0x8298] = "Copyright",
  [0x829A] = "ShutterSpeed",
  [0x829D] = "Aperture",
  --MaxApertureValue  = 0x9205,
  --[0x8822] = "Program",
  [0x8827] = "ISO",
  --[0x9204] = "Exposure",
  --[0x9207] = "Metering",
  --[0x9209] = "Flash",

  [0x920A] = "FocalLength",
  [0xA434] = "LensModel",
  --[0xA302] = "CFA",
}

local function query(file, tags)
  local stream
  if ffi.os=="Windows" then
    stream = io.popen("lib\\exiftool\\Windows\\exiftool -n -"..table.concat(tags, " -").." \""..file.."\"", "rb")
  elseif ffi.os=="Linux" then
    stream = io.popen("exiftool -n -"..table.concat(tags, " -").." \""..file.."\"", "r")
  end

  local entries = {}

  for i = 1, #tags do
    local str = stream:read("*l") or "-"

    local p1, p2, tag, value = str:find("^(.-)%s*: (.*)$")
    if p1 then
      tag = tag:gsub("%s", "")
      entries[tag] = value
      print(tag, value)
    end
  end

  stream:close()

  return entries
end

function exif.read(fileName)
  if type(fileName)~="string" then
    fileName = fileName:getFilename()
  end

  return query(fileName, {"Make", "Model", "ExposureProgram", "ExposureCompensation", "ShutterSpeed", "Aperture", "ISO", "FocalLength", "LensModel"})
end


-- 0x927C -> maker notes
  -- 0x2010 -> equipment
  -- 0x2020 -> camera settings
  -- 0x2040 -> raw development
  -- 0x2040 -> image processing
  -- 0x2050 -> focus info

return exif
