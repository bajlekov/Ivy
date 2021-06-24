/*
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
*/

inline void _atomic_float_add(volatile global float *addr, float val) {
  union {
    unsigned int u32;
    float f32;
  } next, expected, current;
  current.f32 = *addr;

  do {
    expected.f32 = current.f32;
    next.f32 = expected.f32 + val;
    current.u32 = atomic_cmpxchg((volatile global unsigned int *)addr,
                                 expected.u32, next.u32);
  } while (current.u32 != expected.u32);
}

inline void _atomic_float_sub(volatile global float *addr, float val) {
  union {
    unsigned int u32;
    float f32;
  } next, expected, current;
  current.f32 = *addr;

  do {
    expected.f32 = current.f32;
    next.f32 = expected.f32 - val;
    current.u32 = atomic_cmpxchg((volatile global unsigned int *)addr,
                                 expected.u32, next.u32);
  } while (current.u32 != expected.u32);
}

inline void _atomic_float_inc(volatile global float *addr) {
  union {
    unsigned int u32;
    float f32;
  } next, expected, current;
  current.f32 = *addr;

  do {
    expected.f32 = current.f32;
    next.f32 = expected.f32 + 1.0f;
    current.u32 = atomic_cmpxchg((volatile global unsigned int *)addr,
                                 expected.u32, next.u32);
  } while (current.u32 != expected.u32);
}

inline void _atomic_float_dec(volatile global float *addr) {
  union {
    unsigned int u32;
    float f32;
  } next, expected, current;
  current.f32 = *addr;

  do {
    expected.f32 = current.f32;
    next.f32 = expected.f32 - 1.0f;
    current.u32 = atomic_cmpxchg((volatile global unsigned int *)addr,
                                 expected.u32, next.u32);
  } while (current.u32 != expected.u32);
}

inline void _atomic_float_min(volatile global float *addr, float val) {
  union {
    unsigned int u32;
    float f32;
  } next, expected, current;

  current.f32 = *addr;
  next.f32 = val;

  do {
    if (current.f32 <= val)
      return;
    expected.f32 = current.f32;
    current.u32 = atomic_cmpxchg((volatile global unsigned int *)addr,
                                 expected.u32, next.u32);
  } while (current.u32 != expected.u32);
}

inline void _atomic_float_max(volatile global float *addr, float val) {
  union {
    unsigned int u32;
    float f32;
  } next, expected, current;

  current.f32 = *addr;
  next.f32 = val;

  do {
    if (current.f32 >= val)
      return;
    expected.f32 = current.f32;
    current.u32 = atomic_cmpxchg((volatile global unsigned int *)addr,
                                 expected.u32, next.u32);
  } while (current.u32 != expected.u32);
}

inline void _atomic_local_float_add(volatile local float *addr, float val) {
  union {
    unsigned int u32;
    float f32;
  } next, expected, current;
  current.f32 = *addr;

  do {
    expected.f32 = current.f32;
    next.f32 = expected.f32 + val;
    current.u32 = atomic_cmpxchg((volatile local unsigned int *)addr,
                                 expected.u32, next.u32);
  } while (current.u32 != expected.u32);
}

inline void _atomic_local_float_sub(volatile local float *addr, float val) {
  union {
    unsigned int u32;
    float f32;
  } next, expected, current;
  current.f32 = *addr;

  do {
    expected.f32 = current.f32;
    next.f32 = expected.f32 - val;
    current.u32 = atomic_cmpxchg((volatile local unsigned int *)addr,
                                 expected.u32, next.u32);
  } while (current.u32 != expected.u32);
}

inline void _atomic_local_float_inc(volatile local float *addr) {
  union {
    unsigned int u32;
    float f32;
  } next, expected, current;
  current.f32 = *addr;

  do {
    expected.f32 = current.f32;
    next.f32 = expected.f32 + 1.0f;
    current.u32 = atomic_cmpxchg((volatile local unsigned int *)addr,
                                 expected.u32, next.u32);
  } while (current.u32 != expected.u32);
}

inline void _atomic_local_float_dec(volatile local float *addr) {
  union {
    unsigned int u32;
    float f32;
  } next, expected, current;
  current.f32 = *addr;

  do {
    expected.f32 = current.f32;
    next.f32 = expected.f32 - 1.0f;
    current.u32 = atomic_cmpxchg((volatile local unsigned int *)addr,
                                 expected.u32, next.u32);
  } while (current.u32 != expected.u32);
}

inline void _atomic_local_float_min(volatile local float *addr, float val) {
  union {
    unsigned int u32;
    float f32;
  } next, expected, current;

  current.f32 = *addr;
  next.f32 = val;

  do {
    if (current.f32 <= val)
      return;
    expected.f32 = current.f32;
    current.u32 = atomic_cmpxchg((volatile local unsigned int *)addr,
                                 expected.u32, next.u32);
  } while (current.u32 != expected.u32);
}

inline void _atomic_local_float_max(volatile local float *addr, float val) {
  union {
    unsigned int u32;
    float f32;
  } next, expected, current;

  current.f32 = *addr;
  next.f32 = val;

  do {
    if (current.f32 >= val)
      return;
    expected.f32 = current.f32;
    current.u32 = atomic_cmpxchg((volatile local unsigned int *)addr,
                                 expected.u32, next.u32);
  } while (current.u32 != expected.u32);
}

inline void local_barrier() { barrier(CLK_LOCAL_MEM_FENCE); }

inline void global_barrier() { barrier(CLK_GLOBAL_MEM_FENCE); }