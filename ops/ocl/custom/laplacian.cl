/*
name = "Laplacian"
colorspace = Y
*/

kernel void laplacian(
	global float *I,
	global float *O) {

  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float xn = $I[x-1, y];
	float xp = $I[x+1, y];
	float yn = $I[x, y-1];
	float yp = $I[x, y+1];
	float i = $I[x, y];

	$O[x, y] = (xn + xp + yn + yp)*0.25f - i;
}
