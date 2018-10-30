local proc = require "lib.opencl.process".new()

local source = [[
kernel void curveL__(global float *I, global float *C, global float *A, global float *O)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);

  float i = clamp($I[x, y, 0], 0.0f, 1.0f);

  int lowIdx = clamp(floor(i*255), 0.0f, 255.0f);
	int highIdx = clamp(ceil(i*255), 0.0f, 255.0f);

	float lowVal = C[lowIdx];
	float highVal = C[highIdx];

	float factor = lowIdx==highIdx ? 1.0f : (i*255.0f-lowIdx)/(highIdx-lowIdx);
	float o = lowVal*(1.0f - factor) + highVal*factor;

  $O[x, y, 0] = o;

	#if ${O.cs == "LAB" and 1 or 0}$
		float f = A[0]>0.5f ? o/i : 1.0f;
		$O[x, y, 1] = $I[x, y, 1]*f;
		$O[x, y, 2] = $I[x, y, 2]*f;
	#endif

	#if ${O.cs == "LCH" and 1 or 0}$
		float f = A[0]>0.5f ? o/i : 1.0f;
		$O[x, y, 1] = $I[x, y, 1]*f;
		$O[x, y, 2] = $I[x, y, 2];
	#endif
}
]]

local function execute()
	proc:getAllBuffers("I", "C", "A", "O")
	proc:executeKernel("curveL__", proc:size2D("O"))
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
