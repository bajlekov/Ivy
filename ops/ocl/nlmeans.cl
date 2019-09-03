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

// http://dev.theomader.com/gaussian-kernel-calculator/
// sigma = size / 5
constant float G2[5] = {0.06136, 0.24477, 0.38774, 0.24477, 0.06136};
constant float G7[15] = {0.009033, 0.018476, 0.033851, 0.055555, 0.08167, 0.107545, 0.126854, 0.134032, 0.126854, 0.107545, 0.08167, 0.055555, 0.033851, 0.018476, 0.009033};
constant float G12[25] = {0.004571, 0.00723, 0.010989, 0.016048, 0.022521, 0.03037, 0.039354, 0.049003, 0.058632, 0.067411, 0.074476, 0.079066, 0.080657, 0.079066, 0.074476, 0.067411, 0.058632, 0.049003, 0.039354, 0.03037, 0.022521, 0.016048, 0.010989, 0.00723, 0.004571};
constant float G17[35] = {0.003036, 0.004249, 0.005827, 0.00783, 0.010309, 0.013299, 0.01681, 0.020819, 0.025265, 0.030042, 0.035002, 0.039958, 0.044696, 0.048988, 0.052608, 0.055357, 0.057075, 0.057659, 0.057075, 0.055357, 0.052608, 0.048988, 0.044696, 0.039958, 0.035002, 0.030042, 0.025265, 0.020819, 0.01681, 0.013299, 0.010309, 0.00783, 0.005827, 0.004249, 0.003036};
constant float G22[45] = {0.002268, 0.002957, 0.003808, 0.004843, 0.006084, 0.007549, 0.009253, 0.011202, 0.013396, 0.015823, 0.01846, 0.021273, 0.024214, 0.027224, 0.030233, 0.033162, 0.03593, 0.038452, 0.040646, 0.042439, 0.043768, 0.044585, 0.044861, 0.044585, 0.043768, 0.042439, 0.040646, 0.038452, 0.03593, 0.033162, 0.030233, 0.027224, 0.024214, 0.021273, 0.01846, 0.015823, 0.013396, 0.011202, 0.009253, 0.007549, 0.006084, 0.004843, 0.003808, 0.002957, 0.002268};

kernel void init(global float *out, global float *t3, global float *t4, global float *wmax) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

  $t3[x, y] = (float3)0.0f;
  $t4[x, y] = (float3)0.0f;
  $wmax[x, y] = (float3)0.0000001f;
}

kernel void dist(global float *in, global float *t1, global float* p1, global float*p2, global float*p5, const int ox, const int oy) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

  float3 i1 = $in[x, y];
  float3 i2 = $in[x+ox, y+oy];

  // photon well depth for proper scaling of the poisson noise
  float depth = 25000.0f;

  // anscombe transform from poisson noise to unit standard deviation noise
  i1 = 2.0f*sqrt(i1*depth + 3.0f/8.0f + pown(p5[0]*25.0f, 2));
  i2 = 2.0f*sqrt(i2*depth + 3.0f/8.0f + pown(p5[0]*25.0f, 2));

  float3 o = pown(i1 - i2, 2);
  $t1[x, y, 0] = (o.x + o.y + o.z);
}

kernel void horizontal(global float *t1, global float *t2, global float *k) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

  float sum = 0.0f;
  for (int i = -SX; i<=SX; i++)
    sum += $t1[x+i, y, 0]*k[i+7];

  $t2[x, y, 0] = sum;
}

kernel void vertical(global float *t2, global float *t1, global float *k) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

  float sum = 0.0f;
  for (int i = -SY; i<=SY; i++)
    sum += $t2[x, y+i, 0]*k[i+7];

  $t1[x, y, 0] = sum;
}

kernel void accumulate(global float *in, global float *t1, global float *t3, global float *t4, global float *wmax, global float* p1, global float*p2, const int ox, const int oy) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

  float3 sigma = pown(1.0f - (float3)($p2[x, y, 0], $p1[x, y, 0], $p2[x, y, 0]), 5);

  float3 pf = exp(-$t1[x, y, 0]*sigma);
  float3 nf = exp(-$t1[x-ox, y-oy, 0]*sigma);

  float3 pi = $in[x+ox, y+oy];
  pi.xz = pi.xz/fmax(pi.y, 0.000001f);
  float3 ni = $in[x-ox, y-oy];
  ni.xz = ni.xz/fmax(ni.y, 0.000001f);

  float3 o = $t3[x, y] + pi*pf + ni*nf;
  float3 f = $t4[x, y] + pf + nf;

  float3 w = $wmax[x, y];
  $wmax[x, y] = fmax(w, fmax(pf, nf));

  $t3[x, y] = o;
  $t4[x, y] = f;
}

kernel void norm(global float *in, global float *t3, global float *t4, global float *wmax, global float *p3, global float *out) {
  const int x = get_global_id(0);
  const int y = get_global_id(1);

  float3 i = $in[x, y];
  float3 _i = i;
  i.xz = i.xz/fmax(i.y, 0.000001f);

  float3 w = $wmax[x, y];
  float3 o = (w*i + $t3[x, y]) / (w + $t4[x, y]);
  float f = $p3[x, y, 0];
  o.xz = o.xz*o.y;
  o = _i*(1-f) + o*f;

  $out[x, y] = o;
}
