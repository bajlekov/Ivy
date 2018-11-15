/*
name = "Wiener filter"
colorspace = LAB
P1 = {type = "float", name = "Noise", min = 0, max = 1, default = 0.2}
*/

constant float G7[15] = {0.034044, 0.044388, 0.055560, 0.066762, 0.077014, 0.085288, 0.090673, 0.092542, 0.090673, 0.085288, 0.077014, 0.066762, 0.055560, 0.044388, 0.034044};

kernel void wiener(
	global float *I,
	global float *P1,
	global float *O) {

  const int x = get_global_id(0);
  const int y = get_global_id(1);
	const int z = get_global_id(2);

	// TODO: use separable filter
	// TODO: provide smaller filter for faster processing

	float pix[15][15];
	for (int i=0; i<15; i++)
		for (int j=0; j<15; j++)
			pix[i][j] = $I[x+i-7, y+j-7, z];

	float mean = 0.0f;
	for (int i=0; i<15; i++)
		for (int j=0; j<15; j++)
			mean += pix[i][j] * G7[i] * G7[j];

	float var = 0.0f;
	for (int i=0; i<15; i++)
		for (int j=0; j<15; j++)
			var += pown(pix[i][j]-mean, 2) * G7[i] * G7[j];

	float o = var==0.0f ? $I[x, y, z] : mean + ($I[x, y, z] - mean) * var/(var + pown($P1[x, y, z], 2)*0.0005f);

	$O[x, y, z] = o;
}
