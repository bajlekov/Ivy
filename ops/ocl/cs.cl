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

#define A    0.055f
#define G    2.4f
#define N    0.03928571428571429f
#define F    12.923210180787855f

//continuous conversion
float srgb(float v) {
	if (v<N/F) {
		return F*v;
	} else {
		return (1+A)*pow(v, 1/G) - A;
	}
}

float lrgb(float V) {
	if (V<N) {
		return V/F;
	} else {
		return pow((V+A)/(1+A), G);
	}
}

float3 SRGB_LRGB(float3 i) {
	return (float3)(lrgb(i.x), lrgb(i.y), lrgb(i.z));
}

float3 LRGB_SRGB(float3 i) {
	return (float3)(srgb(i.x), srgb(i.y), srgb(i.z));
}

// sRGB to XYZ D65 conversion matrix
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

float3 LRGB_XYZ(float3 i) {
	float3 o;
	o.x = i.x*M[0] + i.y*M[1] + i.z*M[2];
	o.y = i.x*M[3] + i.y*M[4] + i.z*M[5];
	o.z = i.x*M[6] + i.y*M[7] + i.z*M[8];
	return o;
}

float3 XYZ_LRGB(float3 i) {
	float3 o;
	o.x = i.x*M_1[0] + i.y*M_1[1] + i.z*M_1[2];
	o.y = i.x*M_1[3] + i.y*M_1[4] + i.z*M_1[5];
	o.z = i.x*M_1[6] + i.y*M_1[7] + i.z*M_1[8];
	return o;
}

float XYZ_Y(float3 i) { return i.y; }
float3 Y_XYZ(float i) {
	float3 o;
	o.x = i*(M[0]+M[1]+M[2]);
	o.y = i;
	o.z = i*(M[6]+M[7]+M[8]);
	return o;
}
float3 Y_LRGB(float i) { return (float3)(i); }
float3 Y_SRGB(float i) { return (float3)(srgb(i));}
float LRGB_Y(float3 i) { return i.x*M[3] + i.y*M[4] + i.z*M[5]; }

#define wp_x 0.95042854537718f
#define wp_y 1.0f
#define wp_z 1.0889003707981f
#define E (216.0f/24389.0f)
#define K (24389.0f/27.0f)

float lab(float v) {
  if (v>E) {
    return pow(v, 1.0f/3.0f);
  } else {
    return (K*v + 16.0f)/116.0f;
  }
}

float xyz(float V) {
  if (pown(V, 3)>E) {
    return pown(V, 3);
  } else {
    return (116.0f*V - 16.0f)/K;
  }
}

float3 XYZ_LAB(float3 i) {
	float3 o;
	i.x = lab(i.x/wp_x);
	i.y = lab(i.y/wp_y);
	i.z = lab(i.z/wp_z);
	o.x = 1.16f*i.y - 0.16f;
	o.y = 5.0f*(i.x - i.y);
	o.z = 2.0f*(i.y - i.z);
	return o;
}

float Y_L(float i) {
	return 1.16f*lab(i) - 0.16f;
}

float3 LAB_XYZ(float3 i) {
	float3 o;
	o.y = (i.x + 0.16f)/1.16f;
	o.x = i.y*0.2f + o.y;
	o.z = o.y - i.z*0.5f;
	o.x = wp_x*xyz(o.x);
	o.y = wp_y*xyz(o.y);
	o.z = wp_z*xyz(o.z);
	return o;
}

float L_Y(float i) {
	return xyz((i + 0.16f)/1.16f);
}

#define M_2PI   6.283185307179586f
#define M_1_2PI 0.15915494309189535f

float3 LAB_LCH(float3 i) {
	float3 o;
	o.x = i.x;
	o.y = sqrt(pown(i.y, 2) + pown(i.z, 2));
	o.z = atan2(i.z, i.y)*M_1_2PI;
	return o;
}

float3 LCH_LAB(float3 i) {
	float3 o;
	o.x = i.x;
	o.y = i.y*cos(i.z*M_2PI);
	o.z = i.y*sin(i.z*M_2PI);
	return o;
}

float LXX_L(float3 i) { return i.x; }
float3 L_LXX(float i) { return (float3)(i, 0, 0); }


// list of convenience chained conversion functions
float3 SRGBtoSRGB(float3 i) {	return i; }
float3 SRGBtoLRGB(float3 i) {
	return SRGB_LRGB(i);
}
float3 SRGBtoXYZ(float3 i) {
	return LRGB_XYZ(SRGB_LRGB(i));
}
float3 SRGBtoLAB(float3 i) {
	return XYZ_LAB(LRGB_XYZ(SRGB_LRGB(i)));
}
float3 SRGBtoLCH(float3 i) {
	return LAB_LCH(XYZ_LAB(LRGB_XYZ(SRGB_LRGB(i))));
}
float SRGBtoY(float3 i) {
	return LRGB_Y(SRGB_LRGB(i));
}
float SRGBtoL(float3 i) {
	return Y_L(LRGB_Y(SRGB_LRGB(i)));
}

float3 LRGBtoSRGB(float3 i) {
	return LRGB_SRGB(i);
}
float3 LRGBtoLRGB(float3 i) { return i; }
float3 LRGBtoXYZ(float3 i) {
	return LRGB_XYZ(i);
}
float3 LRGBtoLAB(float3 i) {
	return XYZ_LAB(LRGB_XYZ(i));
}
float3 LRGBtoLCH(float3 i) {
	return LAB_LCH(XYZ_LAB(LRGB_XYZ(i)));
}
float LRGBtoY(float3 i) {
	return LRGB_Y(i);
}
float LRGBtoL(float3 i) {
	return Y_L(LRGB_Y(i));
}


float3 XYZtoSRGB(float3 i) {
	return LRGB_SRGB(XYZ_LRGB(i));
}
float3 XYZtoLRGB(float3 i) {
	return XYZ_LRGB(i);
}
float3 XYZtoXYZ(float3 i) { return i; }
float3 XYZtoLAB(float3 i) {
	return XYZ_LAB(i);
}
float3 XYZtoLCH(float3 i) {
	return LAB_LCH(XYZ_LAB(i));
}
float XYZtoY(float3 i) {
	return XYZ_Y(i);
}
float XYZtoL(float3 i) {
	return Y_L(XYZ_Y(i));
}

float3 LABtoSRGB(float3 i) {
	return LRGB_SRGB(XYZ_LRGB(LAB_XYZ(i)));
}
float3 LABtoLRGB(float3 i) {
	return XYZ_LRGB(LAB_XYZ(i));
}
float3 LABtoXYZ(float3 i) {
	return LAB_XYZ(i);
}
float3 LABtoLAB(float3 i) { return i; }
float3 LABtoLCH(float3 i) {
	return LAB_LCH(i);
}
float LABtoY(float3 i) {
	return L_Y(LXX_L(i));
}
float LABtoL(float3 i) {
	return LXX_L(i);
}

float3 LCHtoSRGB(float3 i) {
	return LRGB_SRGB(XYZ_LRGB(LAB_XYZ(LCH_LAB(i))));
}
float3 LCHtoLRGB(float3 i) {
	return XYZ_LRGB(LAB_XYZ(LCH_LAB(i)));
}
float3 LCHtoXYZ(float3 i) {
	return LAB_XYZ(LCH_LAB(i));
}
float3 LCHtoLAB(float3 i) {
	return LCH_LAB(i);
}
float3 LCHtoLCH(float3 i) { return i; }
float LCHtoY(float3 i) {
	return L_Y(LXX_L(i));
}
float LCHtoL(float3 i) {
	return LXX_L(i);
}

float3 YtoSRGB(float i) {
	return Y_SRGB(i);
}
float3 YtoLRGB(float i) {
	return Y_LRGB(i);
}
float3 YtoXYZ(float i) {
	return Y_XYZ(i);
}
float3 YtoLAB(float i) {
	return L_LXX(Y_L(i));
}
float3 YtoLCH(float i) {
	return L_LXX(Y_L(i));
}
float YtoY(float i) { return i; }
float YtoL(float i) {
	return Y_L(i);
}

float3 LtoSRGB(float i) {
	return Y_SRGB(L_Y(i));
}
float3 LtoLRGB(float i) {
	return Y_LRGB(L_Y(i));
}
float3 LtoXYZ(float i) {
	return Y_XYZ(L_Y(i));
}
float3 LtoLAB(float i) {
	return L_LXX(i);
}
float3 LtoLCH(float i) {
	return L_LXX(i);
}
float LtoY(float i) {
	return L_Y(i);
}
float LtoL(float i) { return i; }
