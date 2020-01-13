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

local ffi = require "ffi"

ffi.cdef[[
  struct SDL_mutex;
  typedef struct SDL_mutex SDL_mutex;

  SDL_mutex *SDL_CreateMutex(void);
  int SDL_LockMutex(SDL_mutex * mutex);
  int SDL_UnlockMutex(SDL_mutex * mutex);
  void SDL_DestroyMutex(SDL_mutex * mutex);
]]

local mutex = {}
mutex.meta = {__index = mutex}

function mutex:new(ptr)
  local m = {
    mutex = ptr and ffi.cast("SDL_mutex *", ptr) or  ffi.gc(ffi.C.SDL_CreateMutex(), ffi.C.SDL_DestroyMutex)
  }

  setmetatable(m, self.meta)
  return m
end

function mutex:lock()
  assert(ffi.C.SDL_LockMutex(self.mutex)==0)
end

function mutex:unlock()
  assert(ffi.C.SDL_UnlockMutex(self.mutex)==0)
end

function mutex:ptr()
  return tonumber(ffi.cast("uintptr_t", self.mutex))
end

return mutex
