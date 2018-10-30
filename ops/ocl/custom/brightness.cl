/*
name = "Brightness"
colorspace = SRGB
P1 = {type = "float", name = "Brightness", min = 0, max = 2, default = 1}
*/

kernel void brightness(
	global float *I,
	global float *P1,
	global float *O) {

  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float3 i = $I[x, y];
	float p = $P1[x, y, 0];

	$O[x, y] = i*p;
}
