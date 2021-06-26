/*
  Copyright (C) 2011-2021 G. Bajlekov

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

#define M_2PI 6.283185307179586f
RNGState _rng_state;

// uniformly distributed random numbers in the range 0-1
float runif(unsigned int32 key, unsigned int32 x, unsigned int32 y)
{
  return frandom(&_rng_state);
}

// using the Box-Muller transform to obtain normally distributed samples
// https://en.wikipedia.org/wiki/Box%E2%80%93Muller_transform
float _rnorm_alt(unsigned int32 key, unsigned int32 x, unsigned int32 y)
{
  float u1 = frandom(&_rng_state);
  float u2 = frandom(&_rng_state);

  float r = sqrt(-2.0f * log(u1));
  float t = M_2PI * u2;

  return r * sin(t);
}

// using the Marsaglia polar method to obtain normally distributed samples
// https://en.wikipedia.org/wiki/Marsaglia_polar_method
float rnorm(unsigned int32 key, unsigned int32 x, unsigned int32 y)
{
  unsigned int32 k = 0;

  float s, u, v;
  do
  {
    float u1 = frandom(&_rng_state);
    float u2 = frandom(&_rng_state);

    u = u1 * 2 - 1;
    v = u2 * 2 - 1;
    s = u * u + v * v;
    k += 1;
  } while (s >= 1 || s == 0);
  s = sqrt(-2.0 * log(s) / s);

  return u * s; // use alternating solutions u*s, v*s
}

float _poisson_small(float lambda)
{
  // Algorithm due to Donald Knuth, 1969.
  float p = 1.0f;
  float L = exp(-lambda);

  unsigned int32 k = 0;
  do
  {
    k++;
    p *= frandom(&_rng_state);
  } while (p > L);
  return (float)(k - 1);
}


// R: lgamma(0:255)
const float _lgamma_lookup[256] = {
    1.0/0.0,    0.0000000,    0.0000000,    0.6931472,    1.7917595,    3.1780538,
    4.7874917,    6.5792512,    8.5251614,   10.6046029,   12.8018275,   15.1044126,
   17.5023078,   19.9872145,   22.5521639,   25.1912212,   27.8992714,   30.6718601,
   33.5050735,   36.3954452,   39.3398842,   42.3356165,   45.3801389,   48.4711814,
   51.6066756,   54.7847294,   58.0036052,   61.2617018,   64.5575386,   67.8897431,
   71.2570390,   74.6582363,   78.0922236,   81.5579595,   85.0544670,   88.5808275,
   92.1361756,   95.7196945,   99.3306125,  102.9681986,  106.6317603,  110.3206397,
  114.0342118,  117.7718814,  121.5330815,  125.3172711,  129.1239336,  132.9525750,
  136.8027226,  140.6739236,  144.5657439,  148.4777670,  152.4095926,  156.3608363,
  160.3311282,  164.3201123,  168.3274454,  172.3527971,  176.3958484,  180.4562914,
  184.5338289,  188.6281734,  192.7390473,  196.8661817,  201.0093164,  205.1681995,
  209.3425868,  213.5322415,  217.7369341,  221.9564418,  226.1905483,  230.4390436,
  234.7017234,  238.9783896,  243.2688490,  247.5729141,  251.8904022,  256.2211356,
  260.5649410,  264.9216498,  269.2910977,  273.6731243,  278.0675734,  282.4742927,
  286.8931333,  291.3239501,  295.7666014,  300.2209486,  304.6868568,  309.1641936,
  313.6528299,  318.1526396,  322.6634991,  327.1852877,  331.7178872,  336.2611820,
  340.8150589,  345.3794071,  349.9541180,  354.5390855,  359.1342054,  363.7393756,
  368.3544961,  372.9794689,  377.6141979,  382.2585888,  386.9125491,  391.5759882,
  396.2488171,  400.9309483,  405.6222962,  410.3227765,  415.0323067,  419.7508056,
  424.4781934,  429.2143919,  433.9593240,  438.7129142,  443.4750881,  448.2457727,
  453.0248962,  457.8123880,  462.6081785,  467.4121996,  472.2243839,  477.0446655,
  481.8729792,  486.7092611,  491.5534482,  496.4054785,  501.2652909,  506.1328253,
  511.0080227,  515.8908246,  520.7811737,  525.6790135,  530.5842883,  535.4969432,
  540.4169241,  545.3441778,  550.2786517,  555.2202941,  560.1690540,  565.1248811,
  570.0877257,  575.0575390,  580.0342728,  585.0178794,  590.0083120,  595.0055242,
  600.0094706,  605.0201058,  610.0373857,  615.0612662,  620.0917041,  625.1286567,
  630.1720818,  635.2219379,  640.2781837,  645.3407787,  650.4096829,  655.4848567,
  660.5662611,  665.6538574,  670.7476076,  675.8474740,  680.9534195,  686.0654073,
  691.1834011,  696.3073651,  701.4372638,  706.5730622,  711.7147258,  716.8622203,
  722.0155119,  727.1745672,  732.3393531,  737.5098371,  742.6859869,  747.8677704,
  753.0551562,  758.2481131,  763.4466101,  768.6506168,  773.8601030,  779.0750387,
  784.2953945,  789.5211412,  794.7522498,  799.9886918,  805.2304388,  810.4774629,
  815.7297363,  820.9872317,  826.2499219,  831.5177800,  836.7907796,  842.0688942,
  847.3520980,  852.6403650,  857.9336698,  863.2319872,  868.5352921,  873.8435598,
  879.1567658,  884.4748858,  889.7978957,  895.1257719,  900.4584907,  905.7960288,
  911.1383630,  916.4854706,  921.8373287,  927.1939150,  932.5552071,  937.9211832,
  943.2918212,  948.6670996,  954.0469970,  959.4314920,  964.8205637,  970.2141913,
  975.6123540,  981.0150314,  986.4222031,  991.8338492,  997.2499496, 1002.6704846,
 1008.0954346, 1013.5247802, 1018.9585022, 1024.3965816, 1029.8389993, 1035.2857366,
 1040.7367751, 1046.1920962, 1051.6516817, 1057.1155135, 1062.5835737, 1068.0558443,
 1073.5323079, 1079.0129468, 1084.4977438, 1089.9866815, 1095.4797429, 1100.9769111,
 1106.4781694, 1111.9835009, 1117.4928892, 1123.0063180, 1128.5237709, 1134.0452318,
 1139.5706847, 1145.1001138, 1150.6335033, 1156.1708376
};

// Using Stirling's approximation to compute the log gamma function for integer values
// https://en.wikipedia.org/wiki/Stirling%27s_approximation
float _lgamma(float n)
{
  if (n<256) {
    return _lgamma_lookup[n];
  } else {
    return (n-0.5) * log(n) - n + 0.5 * log(M_2PI * n) + 1 / (12 * n) - 1 / (360 * n * n * n);
  }
}

/*
Adapted from https://numpy.org/
The transformed rejection method for generating Poisson random variables
W. Hormann, Mathematics and Economics 12, 39-45 (1993)
Described PTRS algorithm
*/
float _poisson_large(unsigned int32 key, unsigned int32 x, float lam)
{
  float k;
  float U, V, slam, loglam, a, b, invalpha, vr, us;

  slam = sqrt(lam);
  loglam = log(lam);
  b = 0.931 + 2.53 * slam;
  a = -0.059 + 0.02483 * b;
  invalpha = 1.1239 + 1.1328 / (b - 3.4);
  vr = 0.9277 - 3.6224 / (b - 2);

  for (int y = 0; y < 1024; y++)
  {
    U = frandom(&_rng_state) - 0.5;
    V = frandom(&_rng_state);
    us = 0.5 - abs(U);
    k = floor((2 * a / us + b) * U + lam + 0.43);
    if ((us >= 0.07) && (V <= vr))
    {
      return k;
    }
    if ((k < 0) || ((us < 0.013) && (V > us)))
    {
      continue;
    }
    if ((log(V) + log(invalpha) - log(a / (us * us) + b)) <=
        (-lam + k * loglam - _lgamma(k + 1)))
    {
      return k;
    }
  }
  return k;
}

float rpois(unsigned int32 key, unsigned int32 x, float lambda)
{
  return (lambda < 10.0f) ? _poisson_small(lambda)
                          : _poisson_large(key, x, lambda);
}