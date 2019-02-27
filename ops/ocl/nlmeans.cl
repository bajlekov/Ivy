/*
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
*/

// define support
#define SX 7
#define SY 7

#define GO 7
#define GG G7

constant float G7[15] = {0.034044, 0.044388, 0.055560, 0.066762, 0.077014, 0.085288, 0.090673, 0.092542, 0.090673, 0.085288, 0.077014, 0.066762, 0.055560, 0.044388, 0.034044};
constant float G12[25] = {0.020123, 0.023608, 0.027315, 0.031167, 0.035073, 0.038923, 0.042601, 0.045982, 0.048948, 0.051386, 0.053202, 0.054322, 0.054700, 0.054322, 0.053202, 0.051386, 0.048948, 0.045982, 0.042601, 0.038923, 0.035073, 0.031167, 0.027315, 0.023608, 0.020123};

kernel void init(global float *out, global float *t3, global float *t4) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

  $t3[x, y] = (float3)0.0f;
  $t4[x, y] = (float3)0.0f;
}

kernel void dist(global float *in, global float *t1, const int ox, const int oy) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

  float3 o = pown($in[x, y] - $in[x+ox, y+oy], 2);
  $t1[x, y, 0] = (o.x + o.y + o.z);
}

kernel void horizontal(global float *t1, global float *t2) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

  float sum = 0.0f;
  for (int i = -SX; i<=SX; i++)
    sum += $t1[x+i, y, 0]*GG[i+GO];

  $t2[x, y, 0] = sum;
}

kernel void vertical(global float *t2, global float *t1) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

  float sum = 0.0f;
  for (int i = -SY; i<=SY; i++)
    sum += $t2[x, y+i, 0]*GG[i+GO];

  $t1[x, y, 0] = sum;
}

kernel void accumulate(global float *in, global float *t1, global float *t3, global float *t4, global float *p1, global float *p2, const int ox, const int oy) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

  float lf = max(pown($p1[x, y, 0], 2)*0.01f, 0.0000001f);
  float cf = max(pown($p2[x, y, 0], 2)*0.01f, 0.0000001f);
  float3 ff = (float3)(lf, cf, cf);

  float3 pf = exp(-$t1[x, y, 0]/ff);
  float3 pi = $in[x+ox, y+oy];

  float3 nf = exp(-$t1[x-ox, y-oy, 0]/ff);
  float3 ni = $in[x-ox, y-oy];

  float3 o = $t3[x, y] + pi*pf + ni*nf;
  float3 f = $t4[x, y] + pf + nf;

  $t3[x, y] = o;
  $t4[x, y] = f;
}

kernel void norm(global float *in, global float *t3, global float *t4, global float *p3, global float *out) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

  float f = $p3[x, y, 0];
  float3 i = $in[x, y];
  float3 o = (i + $t3[x, y]) / (1.0f + $t4[x, y]);
  o = i*(1-f) + o*f;
  $out[x, y] = o;
}
