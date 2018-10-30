/*
name = "Blown Highs"
colorspace = LRGB
P1 = {type = "float", name = "Exposure", min = 0, max = 1, default = 0}
*/

kernel void blownHighlights(global float *I, global float *P1, global float *O) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

  float3 v = $I[x, y];

	v *= 1.0f + $P1[x, y, 0];

  float m1 = max(v.x, max(v.y, v.z));
  float m2 = min(v.x, min(v.y, v.z));

  if (v.x<1.0f && m1>1.0f) v.x += (m1-1.0f)/2.0f;
  if (v.y<1.0f && m1>1.0f) v.y += (m1-1.0f)/2.0f;
  if (v.z<1.0f && m1>1.0f) v.z += (m1-1.0f)/2.0f;

  $O[x, y] = v;
}
