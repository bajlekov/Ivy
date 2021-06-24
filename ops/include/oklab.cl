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

// OKlab implementation based on:
// https://bottosson.github.io/posts/oklab/

constant float __M1[] = {
   0.8189330101,  0.3618667424, -0.1288597137,
   0.0329845436,  0.9293118715,  0.0361456387,
   0.0482003018,  0.2643662691,  0.6338517070,
};

constant float __M1_1[] = {
   1.2270138511, -0.5577999807,  0.2812561490,
  -0.0405801784,  1.1122568696, -0.0716766787,
  -0.0763812845, -0.4214819784,  1.5861632204,
};

constant float __M2[] = {
   0.2104542553,  0.7936177850, -0.0040720468,
   1.9779984951, -2.4285922050,  0.4505937099,
   0.0259040371,  0.7827717662, -0.8086757660,
};

constant float __M2_1[] = {
   0.9999999985,  0.3963377922,  0.2158037581,
   1.0000000089, -0.1055613423, -0.0638541748,
   1.0000000547, -0.0894841821, -1.2914855379,
};


inline float _lab(float v) {
  return cbrt(v);
}

inline float _xyz(float V) {
  return pown(V, 3);
}

inline float3 _XYZ_LAB(float3 i) {
  float l = i.x*__M1[0] + i.y*__M1[1] + i.z*__M1[2];
  float m = i.x*__M1[3] + i.y*__M1[4] + i.z*__M1[5];
  float s = i.x*__M1[6] + i.y*__M1[7] + i.z*__M1[8];
  l = _lab(l);
  m = _lab(m);
  s = _lab(s);
  float3 o;
  o.x = l*__M2[0] + m*__M2[1] + s*__M2[2];
	o.y = l*__M2[3] + m*__M2[4] + s*__M2[5];
	o.z = l*__M2[6] + m*__M2[7] + s*__M2[8];
  o.y = o.y*3;
  o.z = o.z*3;
	return o;
}

inline float _Y_L(float i) {
	return _lab(i);
}

inline float3 _LAB_XYZ(float3 i) {
  i.y = i.y/3;
  i.z = i.z/3;
  float l = i.x*__M2_1[0] + i.y*__M2_1[1] + i.z*__M2_1[2];
  float m = i.x*__M2_1[3] + i.y*__M2_1[4] + i.z*__M2_1[5];
  float s = i.x*__M2_1[6] + i.y*__M2_1[7] + i.z*__M2_1[8];
  l = _xyz(l);
  m = _xyz(m);
  s = _xyz(s);
  float3 o;
  o.x = l*__M1_1[0] + m*__M1_1[1] + s*__M1_1[2];
	o.y = l*__M1_1[3] + m*__M1_1[4] + s*__M1_1[5];
	o.z = l*__M1_1[6] + m*__M1_1[7] + s*__M1_1[8];
	return o;
}

inline float _L_Y(float i) {
	return _xyz(i);
}
