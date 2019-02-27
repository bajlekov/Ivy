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

kernel void _abs(
  global float *in,
  global float *out)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
  const int z = get_global_id(2);

  $out[x, y, z] = fabs($in[x, y, z]);
}

kernel void neg(
  global float *in,
  global float *out)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
  const int z = get_global_id(2);

  $out[x, y, z] = -$in[x, y, z];
}

kernel void inv(
  global float *in,
  global float *out)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
  const int z = get_global_id(2);

  $out[x, y, z] = 1.0f-$in[x, y, z];
}

kernel void _clamp(
  global float *in,
  global float *out)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
  const int z = get_global_id(2);

  $out[x, y, z] = clamp($in[x, y, z], 0.0f, 1.0f);
}

kernel void _copy(
  global float *in,
  global float *out)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);
  const int z = get_global_id(2);

  $out[x, y, z] = $in[x, y, z];
}
