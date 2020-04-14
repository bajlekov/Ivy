/*
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
*/

uniform struct dataStruct{
  float * uniform data;		// buffer data
  int x, y, z;	  // dimensions
  int sx, sy, sz;	// strides
  int ox, oy, oz; // offsets
  int cs;					// color space
};

inline int idx(dataStruct *d, int x, int y, int z) {
  x = clamp(x, 0, d->x-1);
  y = clamp(y, 0, d->y-1);
  z = clamp(z, 0, d->z-1);
  return x*d->sx + y*d->sy + z*d->sz;
}

inline float get(dataStruct *d, int x, int y, int z) {
  return d->data[idx(d, x, y, z)];
}

inline void set(dataStruct *d, int x, int y, int z, float v) {
  d->data[idx(d, x, y, z)] = v;
}


// use a = 0.4
const uniform float k0 = 0.05;
const uniform float k1 = 0.25;
const uniform float k2 = 0.40;
const uniform float k3 = 0.25;
const uniform float k4 = 0.05;


export void pyrDownX(dataStruct * uniform src, dataStruct * uniform dst, uniform int y0, uniform int y1) {
  foreach (z = 0...dst->z, y = y0...y1, x = 0...dst->x) {

  }
}
