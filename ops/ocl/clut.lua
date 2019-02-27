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
#include "cs.cl"

#define Q 144
#define D 1727
#define F 12
// D = Q^(3/2) - 1
// F = 144^(1/2)

int2 getCoord(int r, int g, int b) {
	r = clamp(r, 0, Q-1);
	g = clamp(g, 0, Q-1);
	b = clamp(b, 0, Q-1);
	return (int2)(r + fmod(g, (float)F)*Q, D-(b*F + g/F));
}

kernel void clut(global float *p1, global float *p2, global float *p3, global float *p4)
{
  const int x = get_global_id(0);
  const int y = get_global_id(1);

  float3 vl = $p1[x, y];
  float3 v = LRGB_SRGB(vl);
  float3 s = clamp(floor(v*(Q-1)), 0.0f, (Q-1));
  float3 d = ((v*(Q-1)) - s);
  int3 i = (int3)(s.x, s.y, s.z);

  int2 xy;
  xy = getCoord(i.x  , i.y  , i.z  );
  float3 s1 = $p2[xy.x, xy.y];

  xy = getCoord(i.x+1, i.y  , i.z  );
  float3 s2 = $p2[xy.x, xy.y];

  xy = getCoord(i.x+1, i.y+1, i.z  );
  float3 s3 = $p2[xy.x, xy.y];

  xy = getCoord(i.x  , i.y+1, i.z  );
  float3 s4 = $p2[xy.x, xy.y];

  xy = getCoord(i.x  , i.y  , i.z+1);
  float3 s5 = $p2[xy.x, xy.y];

  xy = getCoord(i.x+1, i.y  , i.z+1);
  float3 s6 = $p2[xy.x, xy.y];

  xy = getCoord(i.x+1, i.y+1, i.z+1);
  float3 s7 = $p2[xy.x, xy.y];

  xy = getCoord(i.x  , i.y+1, i.z+1);
  float3 s8 = $p2[xy.x, xy.y];

  float3 s15 = s1 + d.z*(s5-s1);
  float3 s26 = s2 + d.z*(s6-s2);
  float3 s37 = s3 + d.z*(s7-s3);
  float3 s48 = s4 + d.z*(s8-s4);

  float3 s1526 = s15 + d.x*(s26-s15);
  float3 s4837 = s48 + d.x*(s37-s48);

  float3 o = clamp(s1526 + d.y*(s4837-s1526), 0.0f, 1.0f);
  o = vl + (o-vl)*$p4[x, y];

  $p3[x, y] = o;
}
]]

local function execute()
  proc:getAllBuffers("p1", "p2", "p3", "p4")
  proc:executeKernel("clut", proc:size2D("p3"))
end

local function init(d, c, q)
  proc:init(d, c, q)
  proc:loadSourceString(source)
  return execute
end

return init
