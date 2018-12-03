/*
name = "Soft Skin"
colorspace = LAB
P1 = {type = "float", name = "Softness", min = 0, max = 1, default = 0}
*/

kernel void softSkin(
	global float *I,
	global float *P1,
	global float *O) {

  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float3 i = $I[x, y];
	float p = $P1[x, y, 0];

	float r = $I[x, y]LRGB.x;
	float l = YtoL(r);

	i.x = l*p + i.x*(1-p);

	$O[x, y] = i;
}
