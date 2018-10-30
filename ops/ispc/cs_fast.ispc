/*
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
*/

uniform struct dataStruct{
  float * uniform data;		// buffer data
  int x, y, z;	  // dimensions
  int sx, sy, sz;	// strides
  int ox, oy, oz; // offsets
  int cs;					// color space
};

inline int idx(dataStruct *d, int x, int y, int z) {
  //x = clamp(x, 0, d->x-1);
  //y = clamp(y, 0, d->y-1);
  //z = clamp(z, 0, d->z-1);
  return x*d->sx + y*d->sy + z*d->sz;
}

inline float get(dataStruct *d, int x, int y, int z) {
  return d->data[idx(d, x, y, z)];
}

inline void set(dataStruct *d, int x, int y, int z, float v) {
  d->data[idx(d, x, y, z)] = v;
}

// GtoL and LtoG gamma correcting functions
const uniform float GAMMA_a = 0.055;
const uniform float GAMMA_G = 1/0.42;
const uniform float GAMMA_a_1 = 1/1.055;
const uniform float GAMMA_G_1 = 0.42;

const uniform float GAMMA_f = 12.342887114692;
const uniform float GAMMA_k = 0.039827586206897;
const uniform float GAMMA_k_f = 0.0032267641951848;
const uniform float GAMMA_f_1 = 0.08101832178386;

inline float LRGBtoSRGB(float i) {
	cif (i<=GAMMA_k_f) {
  	return i * GAMMA_f;
  } else {
  	return (GAMMA_a+1)*pow(i, GAMMA_G_1)-GAMMA_a;
  }
}

inline float SRGBtoLRGB(float i) {
  cif (i<=GAMMA_k) {
  	return i * GAMMA_f_1;
  } else {
  	return pow((i+GAMMA_a)*GAMMA_a_1, GAMMA_G);
  }
}

export void LRGB_SRGB(dataStruct * uniform src, dataStruct * uniform dst, uniform int y0, uniform int y1) {
  foreach (z=0...3, y = y0...y1, x = 0...dst->x) {
    varying float v = get(src, x, y, z);
    v = LRGBtoSRGB(v);
    set(dst, x, y, z, v);
  }
}

export void SRGB_LRGB(dataStruct * uniform src, dataStruct * uniform dst, uniform int y0, uniform int y1) {
  foreach (z=0...3, y = y0...y1, x = 0...dst->x) {
    varying float v = get(src, x, y, z);
    v = SRGBtoLRGB(v);
    set(dst, x, y, z, v);
  }
}

// LRGB <-> XYZ matrices
const uniform float M[] = {
   0.4124564,  0.3575761,  0.1804375,
   0.2126729,  0.7151522,  0.0721750,
   0.0193339,  0.1191920,  0.9503041,
};

const uniform float M_1[] = {
   3.2404542, -1.5371385, -0.4985314,
  -0.9692660,  1.8760108,  0.0415560,
   0.0556434, -0.2040259,  1.0572252,
};

export void LRGB_XYZ(dataStruct * uniform src, dataStruct * uniform dst, uniform int y0, uniform int y1) {
  foreach (yy = y0...y1, xx = 0...dst->x) {
    varying float r = get(src, xx, yy, 0);
    varying float g = get(src, xx, yy, 1);
    varying float b = get(src, xx, yy, 2);

    varying float x = M[0]*r + M[1]*g + M[2]*b;
    varying float y = M[3]*r + M[4]*g + M[5]*b;
    varying float z = M[6]*r + M[7]*g + M[8]*b;

    set(dst, xx, yy, 0, x);
    set(dst, xx, yy, 1, y);
    set(dst, xx, yy, 2, z);
  }
}

export void XYZ_LRGB(dataStruct * uniform src, dataStruct * uniform dst, uniform int y0, uniform int y1) {
  foreach (yy = y0...y1, xx = 0...dst->x) {
    varying float x = get(src, xx, yy, 0);
    varying float y = get(src, xx, yy, 1);
    varying float z = get(src, xx, yy, 2);

    varying float r = M_1[0]*x + M_1[1]*y + M_1[2]*z;
    varying float g = M_1[3]*x + M_1[4]*y + M_1[5]*z;
    varying float b = M_1[6]*x + M_1[7]*y + M_1[8]*z;

    set(dst, xx, yy, 0, r);
    set(dst, xx, yy, 1, g);
    set(dst, xx, yy, 2, b);
  }
}

// Lab whitepoint
const uniform float wp_x = 0.95042854537718;
const uniform float wp_y = 1.0;
const uniform float wp_z = 1.0889003707981;
const uniform float LAB_e = 216.0/24389.0;
const uniform float LAB_k = 24389.0/27.0;

inline float LAB_f(float x) {
  cif (x>pow(LAB_e, 3)) {
    return pow(x, 1.0/3.0);
  } else {
    return (LAB_k*x + 16.0)/116.0;
  }
}

inline float LAB_f_1(float x) {
  cif (pow(x, 3)>LAB_e) {
    return pow(x, 3);
  } else {
    return (116.0*x - 16.0)/LAB_k;
  }
}

export void XYZ_LAB(dataStruct * uniform src, dataStruct * uniform dst, uniform int y0, uniform int y1) {
  foreach (yy = y0...y1, xx = 0...dst->x) {
    varying float x = get(src, xx, yy, 0);
    varying float y = get(src, xx, yy, 1);
    varying float z = get(src, xx, yy, 2);

    x = LAB_f(x/wp_x);
    y = LAB_f(y/wp_y);
    z = LAB_f(z/wp_z);

    varying float l = 1.16*y - 0.16;
    varying float a = 5.0*(x-y);
    varying float b = 2.0*(y-z);

    set(dst, xx, yy, 0, l);
    set(dst, xx, yy, 1, a);
    set(dst, xx, yy, 2, b);
  }
}

export void LAB_XYZ(dataStruct * uniform src, dataStruct * uniform dst, uniform int y0, uniform int y1) {
  foreach (yy = y0...y1, xx = 0...dst->x) {
    varying float l = get(src, xx, yy, 0);
    varying float a = get(src, xx, yy, 1);
    varying float b = get(src, xx, yy, 2);

    varying float y = (l+0.16)/1.16;
    varying float x = a*0.2 + y;
    varying float z = y - b*0.5;

    x = wp_x*LAB_f_1(x);
    y = wp_y*LAB_f_1(y);
    z = wp_z*LAB_f_1(z);

    set(dst, xx, yy, 0, x);
    set(dst, xx, yy, 1, y);
    set(dst, xx, yy, 2, z);
  }
}

// LCH constants
const uniform float pi2 = 6.2831853071796;
const uniform float pi2_1 = 0.1591549430919;

export void LAB_LCH(dataStruct * uniform src, dataStruct * uniform dst, uniform int y0, uniform int y1) {
  foreach (yy = y0...y1, xx = 0...dst->x) {
    varying float l = get(src, xx, yy, 0);
    varying float a = get(src, xx, yy, 1);
    varying float b = get(src, xx, yy, 2);

    varying float c = sqrt(pow(a, 2) + pow(b, 2)); // pow(a, 2) + pow(b, 2) does not work properly!!!??
    varying float h = atan2(b, a)*pi2_1;

    set(dst, xx, yy, 0, l);
    set(dst, xx, yy, 1, c);
    set(dst, xx, yy, 2, h);
  }
}

export void LCH_LAB(dataStruct * uniform src, dataStruct * uniform dst, uniform int y0, uniform int y1) {
  foreach (yy = y0...y1, xx = 0...dst->x) {
    varying float l = get(src, xx, yy, 0);
    varying float c = get(src, xx, yy, 1);
    varying float h = get(src, xx, yy, 2)*pi2;

    varying float a = c*cos(h);
    varying float b = c*sin(h);

    set(dst, xx, yy, 0, l);
    set(dst, xx, yy, 1, a);
    set(dst, xx, yy, 2, b);
  }
}
