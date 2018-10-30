/*
name = "Edge Aware Decompose"
colorspace = LAB
P1 = {type = "float", name = "Sharpness", min = 0, max = 20, default = 10}
P2 = {type = "float", name = "Scale", min = 0, max = 20, default = 1}
O3 = {type = "text", right = "Coarse"}
O4 = {type = "text", right = "Detail"}
*/

constant float filter[5][5] = {
  {0.00390625, 0.015625, 0.0234375, 0.015625, 0.00390625},
  {0.015625  , 0.0625  , 0.09375  , 0.0625  , 0.015625  },
  {0.0234375 , 0.09375 , 0.140625 , 0.09375 , 0.0234375 },
  {0.015625  , 0.0625  , 0.09375  , 0.0625  , 0.015625  },
  {0.00390625, 0.015625, 0.0234375, 0.015625, 0.00390625}
};

float weight(const float3 c1, const float3 c2, const float sharpen) {
  return exp(-(pown(c1.x - c2.x, 2) + pown(c1.y - c2.y, 2) + pown(c1.z - c2.z, 2)) * sharpen);
}

kernel void edgeAware(
	global float *I,
	global float *P1,
	global float *P2,
	global float *O3,
	global float *O4) {

  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float3 sum = (float3) 0.0f;
	float3 wgt = (float3) 0.0f;

	float3 i = $I[x, y];
	int s = $P2[x, y, 0];

	for (int xx = 0; xx<5; xx++)
		for (int yy = 0; yy<5; yy++) {
			float3 j = $I[x + (xx - 2)*s, y + (yy - 2)*s];
			float w = filter[xx][yy] * weight(i, j, $P1[x, y, 0]);

			sum += w * j;
			wgt += w;
		}

	sum = sum / wgt;

	$O3[x, y] = sum;
	$O4[x, y] = i - sum;
}
