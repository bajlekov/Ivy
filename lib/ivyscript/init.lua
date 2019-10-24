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

local ivy = {}
ivy.meta = {__index = ivy}

local ffi = require "ffi"

ffi.cdef([[
    typedef struct translator translator_t;

    translator_t *translator_new(const char *);
    char *translator_generate(translator_t *, const char *);
    void translator_free(translator_t *);

    void translator_clear_inputs(translator_t *);

    uint64_t translator_add_buffer_srgb(translator_t *,
        uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t);
    uint64_t translator_add_buffer_lrgb(translator_t *,
        uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t);
    uint64_t translator_add_buffer_xyz(translator_t *,
        uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t);
    uint64_t translator_add_buffer_lab(translator_t *,
        uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t);
    uint64_t translator_add_buffer_lch(translator_t *,
        uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t);
    uint64_t translator_add_buffer_y(translator_t *,
        uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t);
    uint64_t translator_add_buffer_l(translator_t *,
        uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t);

    char *translator_get_id(translator_t *, const char *);
]])

local lib = ffi.load "lib/ivyscript/target/release/ivyscript.dll"

function ivy.new(source)
  local t = lib.translator_new(source)
  ffi.gc(t, lib.translator_free)

  local o = {
    t = t
  }

  setmetatable(o, ivy.meta)
  return o
end

function ivy:clear()
  lib.translator_clear_inputs(self.t)
end

local cs = {
  SRGB = lib.translator_add_buffer_srgb,
  LRGB = lib.translator_add_buffer_lrgb,
  XYZ = lib.translator_add_buffer_xyz,
  LAB = lib.translator_add_buffer_lab,
  LCH = lib.translator_add_buffer_lch,
  Y = lib.translator_add_buffer_y,
  L = lib.translator_add_buffer_l,
}

function ivy:addBuffer(buf)
  return cs[buf.cs](self.t, buf.x, buf.y, buf.z, buf.sx, buf.sy, buf.sz)
end

function ivy:generate(kernel)
  return ffi.string(lib.translator_generate(self.t, kernel))
end

function ivy:id(kernel)
  return ffi.string(lib.translator_get_id(self.t, kernel))
end

return ivy
