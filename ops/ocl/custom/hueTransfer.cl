/*
name = "Hue Transfer"
colorspace = LCH
P2 = {type = "float", name = "Transfer", min = 0, max = 1, default = 0}
I1 = {type = "text", left = "Hue"}
*/

kernel void hueTransfer(
	global float *I0,
	global float *I1,
	global float *P2,
	global float *O) {

  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float p = $P2[x, y, 0];
	float3 i0 = $I0[x, y];
	float3 i1 = $I1[x, y];

  $O[x, y, 0] = i0.x;
	$O[x, y, 1] = i0.y;
	$O[x, y, 2] = i0.z*(1.0f-p) + i1.z*p;
}
