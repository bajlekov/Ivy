/*
name = "SNN Mean"
colorspace = LAB
P1 = {type = "float", name = "Radius", min = 0, max = 20, default = 10}
P2 = {type = "float", name = "Threshold", min = 0, max = 1, default = 0.5}
*/

float colordiff(float3 pixA, float3 pixB) {
  float3 pix = pown(pixA - pixB, 2);
  return pix.x + pix.y + pix.z;
}


kernel void snn(
	global float *I,
	global float *P1,
	global float *P2,
	global float *O) {

	const int x = get_global_id(0);
	const int y = get_global_id(1);

	int radius = $P1[x, y, 0];
	int pairs = 2;

	float3 center_pix = $I[x, y];
	float3 accumulated = 0;

	float count = 0;

	for(int i = -radius; i<0; i++) {
		for(int j = -radius; j<0; j++) {
			float3 selected_pix = center_pix;
			float diff;
			float best_diff = $P2[x, y, 0];

			float3 tpix;

			tpix = $I[x+i, y+j];
			diff = colordiff(tpix, center_pix);
			if (diff < best_diff) {
				best_diff = diff;
				selected_pix = tpix;
			}

			tpix = $I[x-i, y-j];
			diff = colordiff(tpix, center_pix);
			if (diff < best_diff) {
				best_diff = diff;
				selected_pix = tpix;
			}

			tpix = $I[x+i, y-j];
			diff = colordiff(tpix, center_pix);
			if (diff < best_diff) {
				best_diff = diff;
				selected_pix = tpix;
			}

			tpix =$I[x-i, y+j];
			diff = colordiff(tpix, center_pix);
			if (diff < best_diff) {
				best_diff = diff;
				selected_pix = tpix;
			}

			float wt = sqrt(pown((float)radius + i + 1, 2) + pown((float)radius + j + 1, 2));
			accumulated += selected_pix * wt;
			count += wt;
		}
	}

	$O[x, y] = count==0 ? center_pix : accumulated/count;
	return;
}
