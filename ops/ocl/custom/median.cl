/*
name = "Median"
colorspace = XYZ
*/

constant int A[19] = {1,4,7,0,3,6,1,4,7,0,5,4,3,1,2,4,4,6,4};
constant int B[19] = {2,5,8,1,4,7,2,5,8,3,8,7,6,4,5,7,2,4,2};

kernel void median(
	global float *I,
	global float *O) {

  const int x = get_global_id(0);
  const int y = get_global_id(1);
	const int z = get_global_id(2);

	float pix[9];

	pix[0] = $I[x - 1, y - 1, z];
  pix[1] = $I[x + 0, y - 1, z];
  pix[2] = $I[x + 1, y - 1, z];
  pix[3] = $I[x - 1, y + 0, z];
  pix[4] = $I[x + 0, y + 0, z];
  pix[5] = $I[x + 1, y + 0, z];
  pix[6] = $I[x - 1, y + 1, z];
  pix[7] = $I[x + 0, y + 1, z];
  pix[8] = $I[x + 1, y + 1, z];

	for (int i=0; i<19; i++) {
		if (pix[A[i]]<pix[B[i]]) {
			float t = pix[B[i]];
			pix[B[i]] = pix[A[i]];
			pix[A[i]] = t;
		}
	}

	$O[x, y, z] = pix[4];
}
