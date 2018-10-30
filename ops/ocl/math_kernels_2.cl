/*
  Copyright (C) 2011-2018 G. Bajlekov

    ImageFloat is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ImageFloat is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

kernel void add(
  global float *in1,
  global float *in2,
  global float *out)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
  const int z = get_global_id(2);

  $out[x, y, z] = $in1[x, y, z] + $in2[x, y, z];
}

kernel void sub(
  global float *in1,
  global float *in2,
  global float *out)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
  const int z = get_global_id(2);

  $out[x, y, z] = $in1[x, y, z] - $in2[x, y, z];
}

kernel void mul(
  global float *in1,
  global float *in2,
  global float *out)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
  const int z = get_global_id(2);

  $out[x, y, z] = $in1[x, y, z] * $in2[x, y, z];
}

kernel void div(
  global float *in1,
  global float *in2,
  global float *out)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
  const int z = get_global_id(2);

  $out[x, y, z] = $in1[x, y, z] / $in2[x, y, z];
}

kernel void _pow(
  global float *in1,
  global float *in2,
  global float *out)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
  const int z = get_global_id(2);

  $out[x, y, z] = pow($in1[x, y, z], $in2[x, y, z]);
}

kernel void _max(
  global float *in1,
  global float *in2,
  global float *out)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
  const int z = get_global_id(2);

  $out[x, y, z] = fmax($in1[x, y, z], $in2[x, y, z]);
}

kernel void _min(
  global float *in1,
  global float *in2,
  global float *out)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
  const int z = get_global_id(2);

  $out[x, y, z] = fmin($in1[x, y, z], $in2[x, y, z]);
}

kernel void average(
  global float *in1,
  global float *in2,
  global float *out)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
  const int z = get_global_id(2);

  $out[x, y, z] = ($in1[x, y, z] + $in2[x, y, z])*0.5f;
}

kernel void difference(
  global float *in1,
  global float *in2,
  global float *out)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
  const int z = get_global_id(2);

  $out[x, y, z] = fabs($in1[x, y, z] - $in2[x, y, z]);
}
