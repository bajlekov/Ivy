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

// x64 native tools:
// ispc ../../ops/ispc/preview.ispc -o preview.obj
// link /dll preview.obj msvcrt.lib /def:preview.def
// .def file indicates functions to export!

uniform struct dataStruct{
  float * uniform data;		// buffer data
  int x, y, z;	  // dimensions
  int sx, sy, sz;	// strides
  int ox, oy, oz; // offsets
  int cs;					// color space
};

uniform struct imageStruct{
  unsigned int8 * uniform data;		// buffer data
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

// FIXME: hard-code this, as no broadcasting is needed and strides are known in advance
inline int idx(imageStruct *d, int x, int y, int z) {
  //x = clamp(x, 0, d->x-1);
  //y = clamp(y, 0, d->y-1);
  //z = clamp(z, 0, d->z-1);
  return x*4 + (d->y-y-1)*d->sy + z; // flip y upside-down
}

inline float get(dataStruct *d, int x, int y, int z) {
  return d->data[idx(d, x, y, z)];
}

inline void set(dataStruct *d, int x, int y, int z, float v) {
  d->data[idx(d, x, y, z)] = v;
}

inline float get(imageStruct *d, int x, int y, int z) {
  return d->data[idx(d, x, y, z)]/255.0;
}

inline void set(imageStruct *d, int x, int y, int z, float v) {
  d->data[idx(d, x, y, z)] = clamp(round(v*255.0), 0.0, 255.0);
}

inline float filterLinear(float y0, float y1, float x) {
  return y1*x + y0*(1-x);
}

inline float filterCubic(float y0, float y1, float y2, float y3, float x) {
  float a = 0.5*(-y0 + 3*y1 -3*y2 +y3);
  float b = y0 -2.5*y1 + 2*y2 - 0.5*y3;
  float c = 0.5*(-y0 + y2);
  float d = y1;

  return a*x*x*x + b*x*x + c*x + d;
}

inline float getBilinear(dataStruct *d, float x, float y, int z) {
  float xm = floor(x);
  float xf = x - xm;
  float ym = floor(y);
  float yf = y - ym;

  float v00, v01, v10, v11;

  v00 = get(d, xm  , ym  , z);
  v01 = get(d, xm  , ym+1, z);
  v10 = get(d, xm+1, ym  , z);
  v11 = get(d, xm+1, ym+1, z);

  return filterLinear(filterLinear(v00, v01, yf), filterLinear(v10, v11, yf), xf);
}

inline float getBicubic(dataStruct *d, float x, float y, int z) {
  float xm = floor(x);
  float xf = x - xm;
  float ym = floor(y);
  float yf = y - ym;

  float v00, v01, v02, v03;
  float v10, v11, v12, v13;
  float v20, v21, v22, v23;
  float v30, v31, v32, v33;

  v00 = get(d, xm-1, ym-1, z);
	v01 = get(d, xm-1, ym  , z);
	v02 = get(d, xm-1, ym+1, z);
	v03 = get(d, xm-1, ym+2, z);
	v10 = get(d, xm  , ym-1, z);
	v11 = get(d, xm  , ym  , z);
	v12 = get(d, xm  , ym+1, z);
	v13 = get(d, xm  , ym+2, z);
	v20 = get(d, xm+1, ym-1, z);
	v21 = get(d, xm+1, ym  , z);
	v22 = get(d, xm+1, ym+1, z);
	v23 = get(d, xm+1, ym+2, z);
	v30 = get(d, xm+2, ym-1, z);
	v31 = get(d, xm+2, ym  , z);
	v32 = get(d, xm+2, ym+1, z);
	v33 = get(d, xm+2, ym+2, z);

  return filterCubic(
    filterCubic(v00, v01, v02, v03, yf),
    filterCubic(v10, v11, v12, v13, yf),
    filterCubic(v20, v21, v22, v23, yf),
    filterCubic(v30, v31, v32, v33, yf),
    xf);
}

export void preview(dataStruct * uniform src, imageStruct * uniform dst, uniform int y0, uniform int y1) {
  foreach (z=0...3, y = y0...y1, x = 0...dst->x) {
    varying float v = get(src, x, y, z);
    set(dst, x, y, z, v);
  }
}

export void crop(dataStruct * uniform src, dataStruct * uniform dst, uniform dataStruct * uniform offset, uniform int y0, uniform int y1) {
  float ox = get(offset, 0, 0, 0);
  float oy = get(offset, 0, 0, 1);
  float s = get(offset, 0, 0, 2);
  foreach (z=0...3, y = y0...y1, x = 0...dst->x) {
    varying float v = get(src, (int)(x*s+ox), (int)(y*s+oy), z);
    set(dst, x, y, z, v);
  }
}

float A = 0;
float B = 0;
float C = 0;

inline float rd(float ru) {
  return A*ru*ru*ru*ru + B*ru*ru*ru + C*ru*ru + (1-A-B-C)*ru;
}

export void cropCorrect(dataStruct * uniform src, dataStruct * uniform dst, uniform dataStruct * uniform offset, uniform int y0, uniform int y1) {
  float ox = get(offset, 0, 0, 0);
  float oy = get(offset, 0, 0, 1);
  float s = get(offset, 0, 0, 2);

  A = get(offset, 0, 0, 3);
  B = get(offset, 0, 0, 4);
  C = get(offset, 0, 0, 5);

  float x_2 = src->x/2;
  float y_2 = src->y/2;
  float fn_1 = min(x_2, y_2);
  float fn = 1.0/fn_1;

  foreach (z=0...3, y = y0...y1, x = 0...dst->x) {
    float cy = y*s+oy;
    float cx = x*s+ox;

    float cxn = (cx - x_2)*fn;
    float cyn = (cy - y_2)*fn;

    float r = sqrt(cxn*cxn + cyn*cyn);

    float sd = rd(r)/(r+1.0e-12);
    cx = sd*cxn*fn_1 + x_2;
    cy = sd*cyn*fn_1 + y_2;

    varying float v = getBicubic(src, cx, cy, z);
    set(dst, x, y, z, v);
  }
}
