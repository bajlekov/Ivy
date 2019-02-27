--[[
  Copyright (C) 2011-2018 G. Bajlekov

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
inline float rd(float ru, float A, float B, float C) {
  //return A*ru*ru*ru*ru + B*ru*ru*ru + C*ru*ru + (1-A-B-C)*ru;
	return 2 * 0.57f * sin( atan2( ru, 0.8f) );
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

kernel void cropCorrectFisheye(global float *p1, global float *p2, global float *offset)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
  const int z = get_global_id(2);

  float ox = offset[0];
  float oy = offset[1];
  float s = offset[2];

  float A = offset[3];
  float B = offset[4];
  float C = offset[5];

  float x_2 = $p1.x$/2.0;
  float y_2 = $p1.y$/2.0;
  float fn_1 = min(x_2, y_2);
  float fn = 1.0/fn_1;

  float cy = y*s+oy;
  float cx = x*s+ox;

  float cxn = (cx - x_2)*fn;
  float cyn = (cy - y_2)*fn;

  float r = sqrt(cxn*cxn + cyn*cyn);

  float sd = rd(r, A, B, C)/(r+1.0e-12);
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

  v00 = $p1[xm-1, ym-1, z];
  v01 = $p1[xm-1, ym  , z];
  v02 = $p1[xm-1, ym+1, z];
  v03 = $p1[xm-1, ym+2, z];
  v10 = $p1[xm  , ym-1, z];
  v11 = $p1[xm  , ym  , z];
  v12 = $p1[xm  , ym+1, z];
  v13 = $p1[xm  , ym+2, z];
  v20 = $p1[xm+1, ym-1, z];
  v21 = $p1[xm+1, ym  , z];
  v22 = $p1[xm+1, ym+1, z];
  v23 = $p1[xm+1, ym+2, z];
  v30 = $p1[xm+2, ym-1, z];
  v31 = $p1[xm+2, ym  , z];
  v32 = $p1[xm+2, ym+1, z];
  v33 = $p1[xm+2, ym+2, z];

  $p2[x, y, z] = filterCubic(
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

  v00 = $p1[xm  , ym  , z];
  v01 = $p1[xm  , ym+1, z];
  v10 = $p1[xm+1, ym  , z];
  v11 = $p1[xm+1, ym+1, z];

  $p2[x, y, z] = filterLinear(
    filterLinear(v00, v01, yf),
    filterLinear(v10, v11, yf),
    xf);
  */

  /*
  // nearest neighbor filtering
  $p2[x, y, z] = $p1[(int)(cx), (int)(cy), z];
  */
}
]]

local function execute()
  proc:getAllBuffers("p1", "p2", "offset")
  proc:executeKernel("cropCorrectFisheye", proc:size3D("p2"))
end

local function init(d, c, q)
  proc:init(d, c, q)
  proc:loadSourceString(source)
  return execute
end

return init
