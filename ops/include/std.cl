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

#ifndef __INCLUDE_STD
#define __INCLUDE_STD

#include "colorspace.cl"
#include "random.cl"
#include "atomic.cl"

inline float range(float p, float w, float x) {
  x = (x - (p - w)) / (2 * w + 0.000001f);
  x = clamp(x, 0.0f, 1.0f);

  return 2.0f * pown(x, 3) - 3.0f * pown(x, 2) + 1.0f;
}

#endif