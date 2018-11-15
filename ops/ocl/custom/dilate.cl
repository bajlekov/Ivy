/*
name = "Dilate"
colorspace = XYZ
*/

kernel void dilate(
	global float *I,
	global float *O) {

  const int x = get_global_id(0);
  const int y = get_global_id(1);
	const int z = get_global_id(2);

	float p1 = $I[x - 1, y - 1, z];
  float p2 = $I[x + 0, y - 1, z];
  float p3 = $I[x + 1, y - 1, z];
  float p4 = $I[x - 1, y + 0, z];
  float p5 = $I[x + 0, y + 0, z];
  float p6 = $I[x + 1, y + 0, z];
  float p7 = $I[x - 1, y + 1, z];
  float p8 = $I[x + 0, y + 1, z];
  float p9 = $I[x + 1, y + 1, z];

	float m = max(max(max(max(max(max(max(max(p1, p2), p3), p4), p5), p6), p7), p8), p9);

	$O[x, y, z] = m;
}
