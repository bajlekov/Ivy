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

#define wp_x 0.95047f // http://brucelindbloom.com/index.html?Eqn_ChromAdapt.html
#define wp_y 1.0f
#define wp_z 1.08883f
#define E (216.0f/24389.0f) // http://www.brucelindbloom.com/index.html?LContinuity.html
#define K (24389.0f/27.0f)

inline float _lab(float v) {
  if (v>E) {
    return cbrt(v);
  } else {
    return (K*v + 16.0f)/116.0f;
  }
}

inline float _xyz(float V) {
  if (pown(V, 3)>E) {
    return pown(V, 3);
  } else {
    return (116.0f*V - 16.0f)/K;
  }
}

inline float3 _XYZ_LAB(float3 i) {
	float3 o;
	i.x = _lab(i.x/wp_x);
	i.y = _lab(i.y/wp_y);
	i.z = _lab(i.z/wp_z);
	o.x = 1.16f*i.y - 0.16f;
	o.y = 5.0f*(i.x - i.y);
	o.z = 2.0f*(i.y - i.z);
	return o;
}

inline float _Y_L(float i) {
	return 1.16f*_lab(i) - 0.16f;
}

inline float3 _LAB_XYZ(float3 i) {
	float3 o;
	o.y = (i.x + 0.16f)/1.16f;
	o.x = i.y*0.2f + o.y;
	o.z = o.y - i.z*0.5f;
	o.x = wp_x*_xyz(o.x);
	o.y = wp_y*_xyz(o.y);
	o.z = wp_z*_xyz(o.z);
	return o;
}

inline float _L_Y(float i) {
	return _xyz((i + 0.16f)/1.16f);
}

#undef wp_x
#undef wp_y
#undef wp_z
#undef E
#undef K
