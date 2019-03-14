/*
name = "Gradient"
colorspace = Y
O1 = {type = "text", right = "dX"}
O2 = {type = "text", right = "dY"}
*/

kernel void gradient(
	global float *I,
	global float *O1,
	global float *O2) {

  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float xn = $I[x-1, y];
	float xp = $I[x+1, y];
	float yn = $I[x, y-1];
	float yp = $I[x, y+1];

	$O1[x, y] = (xp-xn)*0.5f;
	$O2[x, y] = (yp-yn)*0.5f;
}
