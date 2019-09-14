/*
name = "Essential"
colorspace = LRGB
P1 = {type = "float", name = "Brightness", min = 0, max = 2, default = 1}
P2 = {type = "float", name = "Contrast", min = 0, max = 2, default = 1}
P3 = {type = "float", name = "Vibrance", min = 0, max = 2, default = 1}
*/

#include "cs.cl"

kernel void BCS(
	global float *I,
	global float *P1,
	global float *P2,
	global float *P3,
	global float *O) {

  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float3 i = $I[x, y];
	float Y = LRGBtoY(i);

	float b = $P1[x, y];
	float c = $P2[x, y];
	float s = $P3[x, y];

	float3 r = i/Y;
	float L = YtoL(Y);

	if (L<=0.0f) {
		L = b*(1.0f-c)*L;
	} else if (L>=1.0f) {
		L = 1.0f + (2.0f-b)*(2.0f-c)*(L-1.0f);
	} else {
		// brightness
		L = (1.0f-b)*pown(L, 2) + b*L;
		// contrast
		L = L*2.0f-1.0f;
		float sgn = sign(L);
		L = (1.0f-c)*pown(fabs(L), 2) + fabs(L)*c;
		L = (sgn*L+1.0f)*0.5f;
	}

	Y = LtoY(L);
	i = r*Y;

	// saturation
	float3 d = i-Y;
	float3 m1 = -Y/d;
	float3 m2 = (1.0f-Y)/d;
	float3 m3 = (float3)(d.x<0.0f?m1.x:m2.x, d.y<0.0f?m1.y:m2.y, d.z<0.0f?m1.z:m2.z);
	float m = 1.0f/fmax(fmin(m3.x, fmin(m3.y, m3.z)), 0.0001f); // maximum saturation factor
	m = clamp(m, 0.000001f, 1.0f);
	float ms = (1.0f-s)*pown(m, 2) + s*m;

	i = Y + (ms/m) * d;

	float3 o = i;

	$O[x, y] = o;
}
