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

// counter-based random number generator philox for efficient parallel
// generation of random numbers

typedef struct {
  uint a;
  uint b;
} _philox_ctr;

// start adapted philox2x32_R10
// adapted from https://www.thesalmons.org/john/random123/
/*
Copyright 2010-2012, D. E. Shaw Research. All rights reserved.
Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met: Redistributions of
source code must retain the above copyright notice, this list of conditions, and
the following disclaimer. Redistributions in binary form must reproduce the
above copyright notice, this list of conditions, and the following disclaimer in
the documentation and/or other materials provided with the distribution. Neither
the name of D. E. Shaw Research nor the names of its contributors may be used to
endorse or promote products derived from this software without specific prior
written permission. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
OF SUCH DAMAGE.
*/

uint _philox_mulhilo(uint a, uint b, uint *hip) {
  ulong product = ((ulong)a) * ((ulong)b);
  *hip = product >> 32;
  return (uint)product;
}

#define _M2 ((uint)0xd256d193)
#define _W32 ((uint)0x9E3779B9)

inline _philox_ctr _philox_round(_philox_ctr ctr, uint key) {
  uint hi;
  uint lo = _philox_mulhilo(_M2, ctr.a, &hi);
  _philox_ctr out = {hi ^ key ^ ctr.b, lo};
  return out;
}

inline uint _philox_bumpkey(uint key) {
  key += _W32;
  return key;
}

_philox_ctr _philox(_philox_ctr ctr, uint key) {
  ctr = _philox_round(ctr, key);
  key = _philox_bumpkey(key);
  ctr = _philox_round(ctr, key);
  key = _philox_bumpkey(key);
  ctr = _philox_round(ctr, key);
  key = _philox_bumpkey(key);
  ctr = _philox_round(ctr, key);
  key = _philox_bumpkey(key);
  ctr = _philox_round(ctr, key);
  key = _philox_bumpkey(key);
  ctr = _philox_round(ctr, key);
  key = _philox_bumpkey(key);
  ctr = _philox_round(ctr, key);
  key = _philox_bumpkey(key);
  ctr = _philox_round(ctr, key);
  key = _philox_bumpkey(key);
  ctr = _philox_round(ctr, key);
  key = _philox_bumpkey(key);
  ctr = _philox_round(ctr, key);
  return ctr;
}
// end adapted philox2x32_R10


// uniformly distributed random numbers in the range 0-1
float runif(uint key, uint x, uint y) {
  _philox_ctr ctr = {x, y};
  _philox_ctr res = _philox(ctr, key);
  return (float)res.a / 4294967296;
}

// using the Box-Muller transform to obtain normally distributed samples
// https://en.wikipedia.org/wiki/Box%E2%80%93Muller_transform
float _rnorm_alt(uint key, uint x, uint y) {
  _philox_ctr ctr = {x, y};
  _philox_ctr res = _philox(ctr, key);

  float u1 = (float)res.a / 4294967296;
  float u2 = (float)res.b / 4294967296;

  float r = sqrt(-2.0f * log(u1));
  float t = M_2PI * u2;

  return r * sin(t);
}

// using the Marsaglia polar method to obtain normally distributed samples
// https://en.wikipedia.org/wiki/Marsaglia_polar_method
float rnorm(uint key, uint x, uint y) {
  uint k = 0;

  float s, u, v;
  do {
    _philox_ctr ctr = {x, y};
    _philox_ctr res = _philox(ctr, key + k);

    float u1 = (float)res.a / 4294967296;
    float u2 = (float)res.b / 4294967296;

    u = u1 * 2 - 1;
    v = u2 * 2 - 1;
    s = u * u + v * v;
    k += 1;
  } while (s >= 1 || s == 0);
  s = sqrt(-2.0 * log(s) / s);

  return u * s; // use alternating solutions u*s, v*s
}

float _poisson_small(uint key, uint x, float lambda) {
  // Algorithm due to Donald Knuth, 1969.
  float p = 1.0f;
  float L = exp(-lambda);

  uint k = 0;
  do {
    k++;
    _philox_ctr ctr = {x, k};
    _philox_ctr res =
        _philox(ctr, key); // use alternative solutions res.a, res.b
    p *= (float)res.a / 4294967296;
  } while (p > L);
  return (float)(k - 1);
}

/*
Adapted from https://numpy.org/
The transformed rejection method for generating Poisson random variables
W. Hormann, Mathematics and Economics 12, 39-45 (1993)
Described PTRS algorithm
*/
float _poisson_large(uint key, uint x, float lam) {
  float k;
  float U, V, slam, loglam, a, b, invalpha, vr, us;

  slam = sqrt(lam);
  loglam = log(lam);
  b = 0.931 + 2.53 * slam;
  a = -0.059 + 0.02483 * b;
  invalpha = 1.1239 + 1.1328 / (b - 3.4);
  vr = 0.9277 - 3.6224 / (b - 2);

  for (int y = 0; y < 1024; y++) {
    _philox_ctr ctr = {x, y};
    _philox_ctr res = _philox(ctr, key);

    U = (float)res.a / 4294967296 - 0.5;
    V = (float)res.b / 4294967296;
    us = 0.5 - fabs(U);
    k = floor((2 * a / us + b) * U + lam + 0.43);
    if ((us >= 0.07) && (V <= vr)) {
      return k;
    }
    if ((k < 0) || ((us < 0.013) && (V > us))) {
      continue;
    }
    if ((log(V) + log(invalpha) - log(a / (us * us) + b)) <=
        (-lam + k * loglam - lgamma(k + 1))) {
      return k;
    }
  }
  return k;
}

float rpois(uint key, uint x, float lambda) {
  return (lambda < 10.0f) ? _poisson_small(key, x, lambda)
                          : _poisson_large(key, x, lambda);
}