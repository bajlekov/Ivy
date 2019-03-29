/*
name = "Overshoot Limit"
colorspace = LAB
I1 = {type = "text", left = "Reference"}
P2 = {type = "float", name = "Limit", min = 0, max = 1, default = 0.5}
*/

kernel void limit(
	global float *I0,
	global float *I1,
	global float *P2,
	global float *O) {

  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float o = $I0[x, y, 0];

	float mmin = INFINITY;
	float mmax = -INFINITY;

	for (int i = -1; i<=1; i++) {
		for (int j = -1; j<=1; j++) {
			mmin = fmin(mmin, $I1[x+i, y+j, 0]);
			mmax = fmax(mmax, $I1[x+i, y+j, 0]);
		}
	}

	o = fmin(o, mmax + P2[0]*fabs(mmax-mmin));
	o = fmax(o, mmin - P2[0]*fabs(mmax-mmin));

	$O[x, y, 0] = o;
	$O[x, y, 1] = $I0[x, y, 1];
	$O[x, y, 2] = $I0[x, y, 2];
}
