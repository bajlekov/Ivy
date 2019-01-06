/*
name = "Bokeh"
colorspace = LRGB
P1 = {type = "float", name = "Radius", min = 1, max = 128, default = 1}
*/

kernel void bokeh(
	global float *I,
	global float *P1,
	global float *O) {

  const int x = get_global_id(0);
  const int y = get_global_id(1);
	const int z = get_global_id(2);

	float r = $P1[x, y];
	float o = 0.0f;
	float n = 0.0f;

	for (int i = -r; i<=r; i++) {
		for (int j = -r; j<=r; j++) {
			if (x+i>=0 && x+i<$O.x$ && y+j>=0 && y+j<$O.y$) {
				if (i*i+j*j < r*r) {
					o += $I[x+i, y+j, z];
					n += 1.0f;
				}
			}
		}
	}

	$O[x, y, z] = o/n;
}
