/*
name = "Vector"
colorspace = Y
I1 = {type = "text", left = "X", right = "Magnitude"}
I2 = {type = "text", left = "Y", right = "Angle"}
*/

#define M_1_2PI 0.15915494309189535f

kernel void vector(
	global float *I1,
	global float *I2,
	global float *O1,
	global float *O2) {

  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float i1 = $I1[x, y];
	float i2 = $I2[x, y];

	$O1[x, y] = sqrt(pown(i1, 2) + pown(i2, 2));
	$O2[x, y] = atan2(i2, i1)*M_1_2PI;
}
