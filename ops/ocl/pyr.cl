/*
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
*/

constant float k[5] = {0.0625, 0.25, 0.375, 0.25, 0.0625};

constant float kk[5][5] = {
  {0.00390625, 0.015625, 0.0234375, 0.015625, 0.00390625},
  {0.015625  , 0.0625  , 0.09375  , 0.0625  , 0.015625  },
  {0.0234375 , 0.09375 , 0.140625 , 0.09375 , 0.0234375 },
  {0.015625  , 0.0625  , 0.09375  , 0.0625  , 0.015625  },
  {0.00390625, 0.015625, 0.0234375, 0.015625, 0.00390625}
};

#if $$ I and G and 1 or 0 $$
  // downsampled G from I
  kernel void pyrDown(global float *I, global float *G)
  {
    const int x = get_global_id(0);
    const int y = get_global_id(1);
    const int z = get_global_id(2);

  	float h[5][5];
  	for (int i = 0; i<5; i++)
  		for (int j = 0; j<5; j++)
  			h[i][j] = $I[x*2+i-2, y*2+j-2, z];

  	float v[5];
  	for (int i = 0; i<5; i++)
  		v[i] = 0;
  	for (int i = 0; i<5; i++)
  		#pragma unroll 5
  		for (int j = 0; j<5; j++) {
  			v[i] += h[i][j]*k[j];
  		}

  	float g = 0;
  	for (int i = 0; i<5; i++) {
  		g += v[i]*k[i];
  	}

  	$G[x, y, z] = g;
  }
#endif

#if $$ G and O and 1 or 0 $$
  // upsampled O from G without L
  kernel void pyrUp(global float *G, global float *O)
  {
    const int x = get_global_id(0);
    const int y = get_global_id(1);
    const int z = get_global_id(2);

    float g11 = $G[x-1, y-1, z];
    float g12 = $G[x-1, y  , z];
    float g13 = $G[x-1, y+1, z];
    float g21 = $G[x  , y-1, z];
    float g22 = $G[x  , y  , z];
    float g23 = $G[x  , y+1, z];
    float g31 = $G[x+1, y-1, z];
    float g32 = $G[x+1, y  , z];
    float g33 = $G[x+1, y+1, z];

    $O[x*2    , y*2    , z] = ( g11*kk[0][0] + g12*kk[0][2] + g13*kk[0][4] +
                                g21*kk[2][0] + g22*kk[2][2] + g23*kk[2][4] +
                                g31*kk[4][0] + g32*kk[4][2] + g33*kk[4][4] ) *
                                4.0f;

    if (((y*2 + 1)<$O.y$) && ((x*2 + 1)<$O.x$))
      $O[x*2 + 1, y*2 + 1, z] = ( g22*kk[1][1] + g23*kk[1][3] +
                                  g32*kk[3][1] + g33*kk[3][3] ) *
                                  4.0f;

    if ((x*2 + 1)<$O.x$)
      $O[x*2 + 1, y*2    , z] = ( g21*kk[1][0] + g22*kk[1][2] + g23*kk[1][4] +
                                  g31*kk[3][0] + g32*kk[3][2] + g33*kk[3][4] ) *
                                  4.0f;

    if ((y*2 + 1)<$O.y$)
      $O[x*2    , y*2 + 1, z] = ( g12*kk[0][1] + g13*kk[0][3] +
                                  g22*kk[2][1] + g23*kk[2][3] +
                                  g32*kk[4][1] + g33*kk[4][3] ) *
                                  4.0f;
  }
#endif

#if $$ L and G and O and f and 1 or 0 $$
  // upsampled O from L and G with mixing factor f
  kernel void pyrUpG(global float *L, global float *G, global float *O, global float *f)
  {
    const int x = get_global_id(0);
    const int y = get_global_id(1);
    const int z = get_global_id(2);

    float g11 = $G[x-1, y-1, z];
    float g12 = $G[x-1, y  , z];
    float g13 = $G[x-1, y+1, z];
    float g21 = $G[x  , y-1, z];
    float g22 = $G[x  , y  , z];
    float g23 = $G[x  , y+1, z];
    float g31 = $G[x+1, y-1, z];
    float g32 = $G[x+1, y  , z];
    float g33 = $G[x+1, y+1, z];

    $O[x*2    , y*2    , z] = ( g11*kk[0][0] + g12*kk[0][2] + g13*kk[0][4] +
                                g21*kk[2][0] + g22*kk[2][2] + g23*kk[2][4] +
                                g31*kk[4][0] + g32*kk[4][2] + g33*kk[4][4] ) *
                                4.0f - $L[x*2, y*2, z] * $f[x*2, y*2, z];

  	if (((y*2 + 1)<$O.y$) && ((x*2 + 1)<$O.x$))
  		$O[x*2 + 1, y*2 + 1, z] = ( g22*kk[1][1] + g23*kk[1][3] +
  		                            g32*kk[3][1] + g33*kk[3][3] ) *
  		                            4.0f - $L[x*2 + 1, y*2 + 1, z] * $f[x*2 + 1, y*2 + 1, z];

    if ((x*2 + 1)<$O.x$)
  	  $O[x*2 + 1, y*2    , z] = ( g21*kk[1][0] + g22*kk[1][2] + g23*kk[1][4] +
  	                              g31*kk[3][0] + g32*kk[3][2] + g33*kk[3][4] ) *
  	                              4.0f - $L[x*2 + 1, y*2, z] * $f[x*2 + 1, y*2, z];

    if ((y*2 + 1)<$O.y$)
  	  $O[x*2    , y*2 + 1, z] = ( g12*kk[0][1] + g13*kk[0][3] +
  	                              g22*kk[2][1] + g23*kk[2][3] +
  	                              g32*kk[4][1] + g33*kk[4][3] ) *
  	                              4.0f - $L[x*2, y*2 + 1, z] * $f[x*2, y*2 + 1, z];
  }
#endif

#if $$ I and L and G and 1 or 0 $$
  // generate L from I and downsampled G
  kernel void pyrUpL(global float *I, global float *L, global float *G)
  {
    const int x = get_global_id(0);
    const int y = get_global_id(1);
    const int z = get_global_id(2);

    float g11 = $G[x-1, y-1, z];
    float g12 = $G[x-1, y  , z];
    float g13 = $G[x-1, y+1, z];
    float g21 = $G[x  , y-1, z];
    float g22 = $G[x  , y  , z];
    float g23 = $G[x  , y+1, z];
    float g31 = $G[x+1, y-1, z];
    float g32 = $G[x+1, y  , z];
    float g33 = $G[x+1, y+1, z];

    $L[x*2    , y*2    , z] = ( g11*kk[0][0] + g12*kk[0][2] + g13*kk[0][4] +
                                g21*kk[2][0] + g22*kk[2][2] + g23*kk[2][4] +
                                g31*kk[4][0] + g32*kk[4][2] + g33*kk[4][4] ) *
                                4.0f - $I[x*2    , y*2    , z];

    if (((y*2 + 1)<$L.y$) && ((x*2 + 1)<$L.x$))
      $L[x*2 + 1, y*2 + 1, z] = ( g22*kk[1][1] + g23*kk[1][3] +
                                  g32*kk[3][1] + g33*kk[3][3] ) *
                                  4.0f - $I[x*2 + 1, y*2 + 1, z];
    if ((x*2 + 1)<$L.x$)
      $L[x*2 + 1, y*2    , z] = ( g21*kk[1][0] + g22*kk[1][2] + g23*kk[1][4] +
                                  g31*kk[3][0] + g32*kk[3][2] + g33*kk[3][4] ) *
                                  4.0f - $I[x*2 + 1, y*2    , z];
    if ((y*2 + 1)<$L.y$)
      $L[x*2    , y*2 + 1, z] = ( g12*kk[0][1] + g13*kk[0][3] +
                                  g22*kk[2][1] + g23*kk[2][3] +
                                  g32*kk[4][1] + g33*kk[4][3] ) *
                                  4.0f - $I[x*2    , y*2 + 1, z];
  }
#endif
