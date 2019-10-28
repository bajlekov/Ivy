/*
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
*/

#ifndef __INCLUDE_CS
#define __INCLUDE_CS

#define A    0.055f
#define G    2.4f
#define N    0.03928571428571429f
#define F    12.923210180787855f

//continuous conversion
float _srgb(float v) {
	if (v<N/F) {
		return F*v;
	} else {
		return (1+A)*pow(v, 1/G) - A;
	}
}

float _lrgb(float V) {
	if (V<N) {
		return V/F;
	} else {
		return pow((V+A)/(1+A), G);
	}
}

#undef A
#undef G
#undef N
#undef F

float3 _SRGB_LRGB(float3 i) {
	return (float3)(_lrgb(i.x), _lrgb(i.y), _lrgb(i.z));
}

float3 _LRGB_SRGB(float3 i) {
	return (float3)(_srgb(i.x), _srgb(i.y), _srgb(i.z));
}

// sRGB to XYZ D65 conversion matrix
// http://www.brucelindbloom.com/index.html?Eqn_RGB_XYZ_Matrix.html
constant float M[] = {
   0.4124564,  0.3575761,  0.1804375,
   0.2126729,  0.7151522,  0.0721750,
   0.0193339,  0.1191920,  0.9503041,
};

constant float M_1[] = {
   3.2404542, -1.5371385, -0.4985314,
  -0.9692660,  1.8760108,  0.0415560,
   0.0556434, -0.2040259,  1.0572252,
};

float3 _LRGB_XYZ(float3 i) {
	float3 o;
	o.x = i.x*M[0] + i.y*M[1] + i.z*M[2];
	o.y = i.x*M[3] + i.y*M[4] + i.z*M[5];
	o.z = i.x*M[6] + i.y*M[7] + i.z*M[8];
	return o;
}

float3 _XYZ_LRGB(float3 i) {
	float3 o;
	o.x = i.x*M_1[0] + i.y*M_1[1] + i.z*M_1[2];
	o.y = i.x*M_1[3] + i.y*M_1[4] + i.z*M_1[5];
	o.z = i.x*M_1[6] + i.y*M_1[7] + i.z*M_1[8];
	return o;
}

float _XYZ_Y(float3 i) { return i.y; }
float3 _Y_XYZ(float i) {
	float3 o;
	o.x = i*(M[0]+M[1]+M[2]);
	o.y = i;
	o.z = i*(M[6]+M[7]+M[8]);
	return o;
}
float3 _Y_LRGB(float i) { return (float3)(i); }
float3 _Y_SRGB(float i) { return (float3)(_srgb(i));}
float _LRGB_Y(float3 i) { return i.x*M[3] + i.y*M[4] + i.z*M[5]; }

#define wp_x 0.95047f // http://brucelindbloom.com/index.html?Eqn_ChromAdapt.html
#define wp_y 1.0f
#define wp_z 1.08883f
#define E (216.0f/24389.0f) // http://www.brucelindbloom.com/index.html?LContinuity.html
#define K (24389.0f/27.0f)

float _lab(float v) {
  if (v>E) {
    return pow(v, 1.0f/3.0f);
  } else {
    return (K*v + 16.0f)/116.0f;
  }
}

float _xyz(float V) {
  if (pown(V, 3)>E) {
    return pown(V, 3);
  } else {
    return (116.0f*V - 16.0f)/K;
  }
}

float3 _XYZ_LAB(float3 i) {
	float3 o;
	i.x = _lab(i.x/wp_x);
	i.y = _lab(i.y/wp_y);
	i.z = _lab(i.z/wp_z);
	o.x = 1.16f*i.y - 0.16f;
	o.y = 5.0f*(i.x - i.y);
	o.z = 2.0f*(i.y - i.z);
	return o;
}

float _Y_L(float i) {
	return 1.16f*_lab(i) - 0.16f;
}

float3 _LAB_XYZ(float3 i) {
	float3 o;
	o.y = (i.x + 0.16f)/1.16f;
	o.x = i.y*0.2f + o.y;
	o.z = o.y - i.z*0.5f;
	o.x = wp_x*_xyz(o.x);
	o.y = wp_y*_xyz(o.y);
	o.z = wp_z*_xyz(o.z);
	return o;
}

#undef wp_x
#undef wp_y
#undef wp_z
#undef E
#undef K

float _L_Y(float i) {
	return _xyz((i + 0.16f)/1.16f);
}

#define M_2PI   6.283185307179586f
#define M_1_2PI 0.15915494309189535f

float3 _LAB_LCH(float3 i) {
	float3 o;
	o.x = i.x;
	o.y = sqrt(pown(i.y, 2) + pown(i.z, 2));
	o.z = atan2(i.z, i.y)*M_1_2PI;
	return o;
}

float3 _LCH_LAB(float3 i) {
	float3 o;
	o.x = i.x;
	o.y = i.y*cos(i.z*M_2PI);
	o.z = i.y*sin(i.z*M_2PI);
	return o;
}

float _LXX_L(float3 i) { return i.x; }
float3 _L_LXX(float i) { return (float3)(i, 0, 0); }


// list of convenience chained conversion functions
float3 SRGBtoSRGB(float3 i) {	return i; }
float3 SRGBtoLRGB(float3 i) {
	return _SRGB_LRGB(i);
}
float3 SRGBtoXYZ(float3 i) {
	return _LRGB_XYZ(_SRGB_LRGB(i));
}
float3 SRGBtoLAB(float3 i) {
	return _XYZ_LAB(_LRGB_XYZ(_SRGB_LRGB(i)));
}
float3 SRGBtoLCH(float3 i) {
	return _LAB_LCH(_XYZ_LAB(_LRGB_XYZ(_SRGB_LRGB(i))));
}
float SRGBtoY(float3 i) {
	return _LRGB_Y(_SRGB_LRGB(i));
}
float SRGBtoL(float3 i) {
	return _Y_L(_LRGB_Y(_SRGB_LRGB(i)));
}

float3 LRGBtoSRGB(float3 i) {
	return _LRGB_SRGB(i);
}
float3 LRGBtoLRGB(float3 i) { return i; }
float3 LRGBtoXYZ(float3 i) {
	return _LRGB_XYZ(i);
}
float3 LRGBtoLAB(float3 i) {
	return _XYZ_LAB(_LRGB_XYZ(i));
}
float3 LRGBtoLCH(float3 i) {
	return _LAB_LCH(_XYZ_LAB(_LRGB_XYZ(i)));
}
float LRGBtoY(float3 i) {
	return _LRGB_Y(i);
}
float LRGBtoL(float3 i) {
	return _Y_L(_LRGB_Y(i));
}


float3 XYZtoSRGB(float3 i) {
	return _LRGB_SRGB(_XYZ_LRGB(i));
}
float3 XYZtoLRGB(float3 i) {
	return _XYZ_LRGB(i);
}
float3 XYZtoXYZ(float3 i) { return i; }
float3 XYZtoLAB(float3 i) {
	return _XYZ_LAB(i);
}
float3 XYZtoLCH(float3 i) {
	return _LAB_LCH(_XYZ_LAB(i));
}
float XYZtoY(float3 i) {
	return _XYZ_Y(i);
}
float XYZtoL(float3 i) {
	return _Y_L(_XYZ_Y(i));
}

float3 LABtoSRGB(float3 i) {
	return _LRGB_SRGB(_XYZ_LRGB(_LAB_XYZ(i)));
}
float3 LABtoLRGB(float3 i) {
	return _XYZ_LRGB(_LAB_XYZ(i));
}
float3 LABtoXYZ(float3 i) {
	return _LAB_XYZ(i);
}
float3 LABtoLAB(float3 i) { return i; }
float3 LABtoLCH(float3 i) {
	return _LAB_LCH(i);
}
float LABtoY(float3 i) {
	return _L_Y(_LXX_L(i));
}
float LABtoL(float3 i) {
	return _LXX_L(i);
}

float3 LCHtoSRGB(float3 i) {
	return _LRGB_SRGB(_XYZ_LRGB(_LAB_XYZ(_LCH_LAB(i))));
}
float3 LCHtoLRGB(float3 i) {
	return _XYZ_LRGB(_LAB_XYZ(_LCH_LAB(i)));
}
float3 LCHtoXYZ(float3 i) {
	return _LAB_XYZ(_LCH_LAB(i));
}
float3 LCHtoLAB(float3 i) {
	return _LCH_LAB(i);
}
float3 LCHtoLCH(float3 i) { return i; }
float LCHtoY(float3 i) {
	return _L_Y(_LXX_L(i));
}
float LCHtoL(float3 i) {
	return _LXX_L(i);
}

float3 YtoSRGB(float i) {
	return _Y_SRGB(i);
}
float3 YtoLRGB(float i) {
	return _Y_LRGB(i);
}
float3 YtoXYZ(float i) {
	return _Y_XYZ(i);
}
float3 YtoLAB(float i) {
	return _L_LXX(_Y_L(i));
}
float3 YtoLCH(float i) {
	return _L_LXX(_Y_L(i));
}
float YtoY(float i) { return i; }
float YtoL(float i) {
	return _Y_L(i);
}

float3 LtoSRGB(float i) {
	return _Y_SRGB(_L_Y(i));
}
float3 LtoLRGB(float i) {
	return _Y_LRGB(_L_Y(i));
}
float3 LtoXYZ(float i) {
	return _Y_XYZ(_L_Y(i));
}
float3 LtoLAB(float i) {
	return _L_LXX(i);
}
float3 LtoLCH(float i) {
	return _L_LXX(i);
}
float LtoY(float i) {
	return _L_Y(i);
}
float LtoL(float i) { return i; }


float3 Y3toL3(float3 i) {
	float3 o;
	o.x = _Y_L(i.x);
	o.y = _Y_L(i.y);
	o.z = _Y_L(i.z);
	return o;
}

float3 L3toY3(float3 i) {
	float3 o;
	o.x = _L_Y(i.x);
	o.y = _L_Y(i.y);
	o.z = _L_Y(i.z);
	return o;
}

//construct rgba
float RGBA(float3 i, float a) {
	union {
		float f;
		uchar u8[4];
	} t;

	t.u8[0] = (uchar)round(clamp(i.x*255.0, 0.0, 255.0));
	t.u8[1] = (uchar)round(clamp(i.y*255.0, 0.0, 255.0));
	t.u8[2] = (uchar)round(clamp(i.z*255.0, 0.0, 255.0));
	t.u8[3] = (uchar)round(clamp(  a*255.0, 0.0, 255.0));

	return t.f;
}

inline void _atomic_float_add(volatile global float *addr, float val) {
	union {
		unsigned int u32;
		float        f32;
	} next, expected, current;
	current.f32 = *addr;

	do {
		expected.f32 = current.f32;
		next.f32 = expected.f32 + val;
		current.u32  = atomic_cmpxchg( (volatile __global unsigned int *)addr, expected.u32, next.u32);
	} while( current.u32 != expected.u32 );
}

inline void _atomic_float_sub(volatile global float *addr, float val) {
	union {
		unsigned int u32;
		float        f32;
	} next, expected, current;
	current.f32 = *addr;

	do {
		expected.f32 = current.f32;
		next.f32 = expected.f32 - val;
		current.u32  = atomic_cmpxchg( (volatile __global unsigned int *)addr, expected.u32, next.u32);
	} while( current.u32 != expected.u32 );
}

inline void _atomic_float_inc(volatile global float *addr) {
	union {
		unsigned int u32;
		float        f32;
	} next, expected, current;
	current.f32 = *addr;

	do {
		expected.f32 = current.f32;
		next.f32 = expected.f32 + 1.0f;
		current.u32  = atomic_cmpxchg( (volatile __global unsigned int *)addr, expected.u32, next.u32);
	} while( current.u32 != expected.u32 );
}

inline void _atomic_float_dec(volatile global float *addr) {
	union {
		unsigned int u32;
		float        f32;
	} next, expected, current;
	current.f32 = *addr;

	do {
		expected.f32 = current.f32;
		next.f32 = expected.f32 - 1.0f;
		current.u32  = atomic_cmpxchg( (volatile __global unsigned int *)addr, expected.u32, next.u32);
	} while( current.u32 != expected.u32 );
}


inline void _atomic_float_min(volatile global float *addr, float val) {
	union {
		unsigned int u32;
		float        f32;
	} next, expected, current;

	current.f32 = *addr;
	next.f32 = val;

	do {
		if (current.f32 <= val) return;
		expected.f32 = current.f32;
		current.u32  = atomic_cmpxchg( (volatile __global unsigned int *)addr, expected.u32, next.u32);
	} while( current.u32 != expected.u32 );
}

inline void _atomic_float_max(volatile global float *addr, float val) {
	union {
		unsigned int u32;
		float        f32;
	} next, expected, current;

	current.f32 = *addr;
	next.f32 = val;

	do {
		if (current.f32 >= val) return;
		expected.f32 = current.f32;
		current.u32  = atomic_cmpxchg( (volatile __global unsigned int *)addr, expected.u32, next.u32);
	} while( current.u32 != expected.u32 );
}



#endif
