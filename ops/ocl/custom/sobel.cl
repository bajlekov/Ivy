/*
name = "Sobel"
colorspace = LRGB
*/

kernel void sobel(
	global float *I,
	global float *O) {

  const int x = get_global_id(0);
  const int y = get_global_id(1);

	float3 pix_fl = $I[x-1, y-1];
	float3 pix_fm = $I[x  , y-1];
	float3 pix_fr = $I[x+1, y-1];
	float3 pix_ml = $I[x-1, y  ];
	float3 pix_mm = $I[x  , y  ];
	float3 pix_mr = $I[x+1, y  ];
	float3 pix_bl = $I[x-1, y+1];
	float3 pix_bm = $I[x  , y+1];
	float3 pix_br = $I[x+1, y+1];

	float3 hor_grad = -1.0f*pix_fl + 1.0f*pix_fr - 2.0f*pix_ml + 2.0f*pix_mr - 1.0f*pix_bl + 1.0f*pix_br;
	float3 ver_grad = 1.0f*pix_fl + 2.0f*pix_fm + 1.0f*pix_fr - 1.0f*pix_bl - 2.0f*pix_bm - 1.0f*pix_br;
	float3 gradient = sqrt(hor_grad * hor_grad + ver_grad * ver_grad) / 5.656854249492381; /* sqrt(32.0) = 5.656854249492381 */

	$O[x, y] = gradient;
}
