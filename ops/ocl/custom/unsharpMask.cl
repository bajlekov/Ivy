/*
name = "Unsharp Maks"
colorspace = LAB
P1 = {type = "float", name = "Radius", min = 0, max = 2, default = 0.8}
P2 = {type = "float", name = "Strength", min = 0, max = 5, default = 1}
*/

float gaussian(float x, float s) {
	return exp(-0.5f*pown(x/s, 2));
}

kernel void unsharpMask(
	global float *I,
	global float *P1,
	global float *P2,
	global float *O) {

  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float w = P1[0];
	float i = $I[x, y, 0];
	float v;

	if (w==0.0f) {
		v = i;
	} else {
		float g[4] = {gaussian(0, w), gaussian(1, w), gaussian(2, w), gaussian(3, w)};
		float n = g[0] + 2*g[1] + 2*g[2] + 2*g[3];
		g[0] /= n;
		g[1] /= n;
		g[2] /= n;
		g[3] /= n;

		v = 0;
		for (int i = -3; i<=3; i++)
			for (int j = -3; j<=3; j++)
				v += $I[x+i, y+j, 0] * g[abs(i)]*g[abs(j)];
	}

	float o = i + (i-v)*P2[0];

	$O[x, y, 0] = o;
	$O[x, y, 1] = $I[x, y, 1];
	$O[x, y, 2] = $I[x, y, 2];
}
