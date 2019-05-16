float range(float v, float t, float s) { // value, threshold, sharpness
	float ts = t*s;
	float a = t - ts;
	float b = t + ts;
	float x = clamp((fabs(v) - a)/(2*ts), 0.0f, 1.0f);
  return 2.0f*pown(x, 3) - 3.0f*pown(x, 2) + 1.0f;
}

float range_circular(float v, float t, float s) {
  return range(fabs(v-1.0f), t, s) + range(fabs(v), t, s) + range(fabs(v+1.0f), t, s);
}
