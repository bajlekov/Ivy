--[[
  Copyright (C) 2011-2019 G. Bajlekov

    Ivy is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Ivy is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

local proc = require "lib.opencl.process".new()

local source = [[
inline float rd(float ru,
								float A,
								float B,
								float C,
								float BR,
								float CR,
								float VR
							) {
  ru = ru*(A*ru*ru*ru + B*ru*ru + C*ru + (1-A-B-C));
	return ru*(BR*ru*ru + CR*ru + VR);
}

inline float filterLinear(float y0, float y1, float x) {
  return y1*x + y0*(1-x);
}

inline float filterCubic(float y0, float y1, float y2, float y3, float x) {
  float a = 0.5*(-y0 + 3*y1 -3*y2 +y3);
  float b = y0 -2.5*y1 + 2*y2 - 0.5*y3;
  float c = 0.5*(-y0 + y2);
  float d = y1;

  return a*x*x*x + b*x*x + c*x + d;
}

kernel void cropCorrect(global float *I, global float *O, global float *offset, global float *flags)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
  const int z = get_global_id(2);

  float ox = round(offset[0]);
  float oy = round(offset[1]);
  float s = offset[2];

	float A, B, C;
	float gs = 1.0f;
	if (flags[0]>0.5f) {
  	A = offset[3];
  	B = offset[4];
  	C = offset[5];
		gs = offset[12];
	} else {
		A = 0.0f;
  	B = 0.0f;
  	C = 0.0f;
	}

	float BR, CR, VR;
	if (flags[1]>0.5f) {
		if (z==0) {
			BR = offset[6];
			CR = offset[7];
			VR = offset[8];
		} else if (z==2) {
			BR = offset[9];
			CR = offset[10];
			VR = offset[11];
		} else {
			BR = 0.0f;
			CR = 0.0f;
			VR = 1.0f;
		}
	} else {
		BR = 0.0f;
		CR = 0.0f;
		VR = 1.0f;
	}

  float x_2 = $I.x$ * 0.5f;
  float y_2 = $I.y$ * 0.5f;
  float fn_1 = min(x_2, y_2);
  float fn = 1.0/fn_1;

  float cy = y*s+oy;
  float cx = x*s+ox;

  float cxn = (cx - x_2)*fn;
  float cyn = (cy - y_2)*fn;

  float r = sqrt(cxn*cxn + cyn*cyn);

  float sd = rd(r, A, B, C, BR, CR, VR)/(r + 1.0e-15)*gs;
  cx = sd*cxn*fn_1 + x_2;
  cy = sd*cyn*fn_1 + y_2;

  // bicubic filtering
  int xm = floor(cx);
  float xf = cx - xm;
  int ym = floor(cy);
  float yf = cy - ym;

  float v00, v01, v02, v03;
  float v10, v11, v12, v13;
  float v20, v21, v22, v23;
  float v30, v31, v32, v33;

  v00 = $I[xm-1, ym-1, z];
  v01 = $I[xm-1, ym  , z];
  v02 = $I[xm-1, ym+1, z];
  v03 = $I[xm-1, ym+2, z];
  v10 = $I[xm  , ym-1, z];
  v11 = $I[xm  , ym  , z];
  v12 = $I[xm  , ym+1, z];
  v13 = $I[xm  , ym+2, z];
  v20 = $I[xm+1, ym-1, z];
  v21 = $I[xm+1, ym  , z];
  v22 = $I[xm+1, ym+1, z];
  v23 = $I[xm+1, ym+2, z];
  v30 = $I[xm+2, ym-1, z];
  v31 = $I[xm+2, ym  , z];
  v32 = $I[xm+2, ym+1, z];
  v33 = $I[xm+2, ym+2, z];

  $O[x, y, z] = filterCubic(
    filterCubic(v00, v01, v02, v03, yf),
    filterCubic(v10, v11, v12, v13, yf),
    filterCubic(v20, v21, v22, v23, yf),
    filterCubic(v30, v31, v32, v33, yf),
    xf);

  /*
  // bilinear filtering
  int xm = floor(cx);
  float xf = cx - xm;
  int ym = floor(cy);
  float yf = cy - ym;

  float v00, v01, v10, v11;

  v00 = $I[xm  , ym  , z];
  v01 = $I[xm  , ym+1, z];
  v10 = $I[xm+1, ym  , z];
  v11 = $I[xm+1, ym+1, z];

  $O[x, y, z] = filterLinear(
    filterLinear(v00, v01, yf),
    filterLinear(v10, v11, yf),
    xf);
  */

  /*
  // nearest neighbor filtering
  $O[x, y, z] = $I[(int)(cx), (int)(cy), z];
  */
}
]]

local function execute()
	proc:getAllBuffers("I", "O", "offset", "flags")
	proc:executeKernel("cropCorrect", proc:size3D("O"))
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
