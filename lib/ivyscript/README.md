# IvyScript

IvyScript is a domain specific language for image processing kernels. It is currently compiled to OpenCL or ISPC, but can be easily adapted to generate code for other C-like languages with kernel semantics such as CUDA, Metal, Vulkan/GLSL compute kernels.


The goal of IvyScript is to reduce the overhead of writing boilerplate code for image processing kernels. Image buffer access is greatly simplified with multi-dimensional indexing, in-built support for color space conversions, automatic out-of-bounds handling and broadcasting. Variable types are inferred and functions and kernels are templated, allowing for generic programming.

Here is a kernel that does point-wise addition of two images `A` and `B` and stores the result in `O`:
```
kernel add(A, B, O)
  const x = get_global_id(0)
  const y = get_global_id(1)
  const z = get_global_id(2)

  O[x, y, z] = A[x, y, z] + B[x, y, z]
end
```

## Syntax

IvyScript's syntax is heavily inspired by Lua. The following constructs are supported.

Kernel definitions:
```
kernel name(a, b)
    ...
end
```

Function definitions:
```
function name(a, b)
    ...
    [return c]
end
```

Conditional execution:
```
if condition then
    ...
[elseif condition then]
    ...
[else]
    ...
end
```

Loops within range:
```
for var = start, end [, step] do
    ...
    [continue / break]
end
```

Loop with end condition:
```
while condition do
    ...
    [continue / break]
end
```

Constants, variables, function calls:
```
const a = ...
var b = ...

a = a + b

funcname(a, b)
```

## Variable types

The type system of IvyScript is reduced to fit its purpose. It supports:

* Booleans: `var a = true`, `var a = bool(1)`
* Integers (32-bit) `var b = 3`, `var b = int(5.6)`
* Floats (32-bit) `var c = 3.14`, `var c = float(2)`
* Vectors (Float x 3) `var d = vec(1.0, 2.0, 3.0)`, `var d = vec(3)`

* Arrays
  * Contain one of the above types
  * Have up to 4 dimensions
  * Use either private or local memory
  * Arrays are initialized as `{ {1, 2, 3} {4, 5, 6} }` or as `array(3, 2)` a 3x2 array defaulting to Float values, `bool_array(3, 10, 10)` for a Boolean array, `local_int_array(3)` for a local Integer array.

* Buffers
  * Contain image data encoded as 32-bit floating point values
  * Have 1 or 3 channels of 2D data
  * Have an assigned color space
  * Data is located in global memory. Buffers are always created outside IvyScript and are passed to a kernel as parameters.

### Indexing and properties

Multi-dimensional indexing is performed in this way: `a = b[i, j, k]`. Arrays can be indexed to single elements (or to sub-arrays). Buffers can be 1D, 2D or 3D indexed. 3D indexing always returns a Float, while 2D indexing returns a Vector for 3-channel data and a Float for single channel data. 1D indexing performs linear access of the buffer memory and disregards the 2D data structure and color space encoding.

All indices are clamped to the available dimensions. In this way a buffer of 1x1 pixel can be effectively used as an infinitely large buffer of constant color, as sampled at any coordinate it will return its one pixel value. This also prevents out of bounds memory access.

2D indexed buffers support color space conversions via the `.XXX` property, e.g.:

* `var a = A[x, y].LAB` will convert the color value of A at (x, y) from its internal color space representation to the LAB color space, and assign it to Vec a.
* `var a = A[x, y].Y` will convert the color value of A at (x, y) from its internal color space representation to the Y color space, and assign it to Float a.
* `B[x, y].LAB = b` will cast b to Vec, assume vec(b) is a color in the LAB color space, convert it to B's internal color space representation and store it in B at (x, y).

The supported color spaces are:

* `SRGB`
* `LRGB`
* `XYZ`
* `LAB`
* `LCH`
* `Y` (1 channel)
* `L` (1 channel)

A color space conversion kernel that accepts a buffer `I` with any color space and stores CIELAB's `LCH` values in buffer `O` looks like this:
```
kernel LCH(I, O)
	const x = get_global_id(0)
	const y = get_global_id(1)
	O[x, y] = I[x, y].LCH
end
```

Buffer dimensions can be queried with the `.x`, `.y` and `.z` properties, for a 3-channel buffer: `F.z == 3`

In addition, while buffers solely support Float values, they can be cast on load/store to Integer with the `.int` property, e.g.: `C[x, y, z].int = D[x, y, z].int + 5`

Another buffer property is the `.idx` property. It returns the linear 1D index of a buffer element:
```
var w = E[x, y, z].idx
E[w] == E[x, y, z]
```

Elements of Vec values can be accessed using channel properties:
```
v == vec(v.x, v.y, v.z)
v == vec(v.l, v.a, v.b)
v == vec(v.r, v.g, v.b)
```

## Atomic access

Lastly, both arrays and buffers support atomic operations via atomic functions. These are required if multiple threads are writing to the same memory (global or local), such as when updating the counts in a histogram.

To perform an atomic operation, a pointer to an element in the array or buffer is required. Such a pointer can be obtained via the `.ptr` property, e.g.: `atomic_add(D[x, y, z].ptr, d)`

Alternatively, buffers support the `.intptr` property when atomic operations on integer values are required: `atomic_add(D[x, y, z].intptr, d)`

The `.ptr` and `.intptr` properties have no function in operations other than as argument to the atomic functions. The type of the pointer expression is a 1D array of size 0.

Atomic support is available for both Integer and Float values for the following operations:

* Add
* Sub
* Inc
* Dec
* Min
* Max


Here is an example of updating counts in a histogram buffer:
```
-- calculate r, g and b indices
var r = clamp(int(i.r*255), 0, 255)
var g = clamp(int(i.g*255), 0, 255)
var b = clamp(int(i.b*255), 0, 255)

-- increment histogram data buffer H
atomic_inc(H[r, 0, 0].intptr)
atomic_inc(H[g, 0, 1].intptr)
atomic_inc(H[b, 0, 2].intptr)
```

And this would be the code for updating a local array first to minimize simultaneous atomic access:
```
-- calculate r, g and b indices
var r = clamp(int(i.r*255), 0, 255)
var g = clamp(int(i.g*255), 0, 255)
var b = clamp(int(i.b*255), 0, 255)

-- create local array to hold the histogram counts
var lh = local_int_array(256, 3)

-- check if the number of local workers matches the histogram size
if int(get_local_size(0))==256 then
  
  -- get index of current worker, initialize its local data to zero and wait for all workers to complete
  const lx = int(get_local_id(0))
  lh[lx, 0] = 0
  lh[lx, 1] = 0
  lh[lx, 2] = 0
  barrier(CLK_LOCAL_MEM_FENCE)
  
  -- increment local data according to r, g, b indices and wait for all workers to complete
  atomic_inc(lh[r, 0].ptr)
  atomic_inc(lh[g, 1].ptr)
  atomic_inc(lh[b, 2].ptr)
  barrier(CLK_LOCAL_MEM_FENCE)
  
  -- add local histogram data to histogram data buffer H
  atomic_add(H[lx, 0, 0].intptr, lh[lx, 0])
  atomic_add(H[lx, 0, 1].intptr, lh[lx, 1])
  atomic_add(H[lx, 0, 2].intptr, lh[lx, 2])

end
```

## Standard library

Several convenience functions are exposed available:

* Most of the math functions provided by OpenCL are exposed.
* All OpenCL constants are automatically exposed.
* Explicit color space conversions can be performed on Vectors, e.g.: `LRGBtoSRGB(i)`.

Additionally, random number generators are implemented for uniform, normal and poisson distributions. They operate based on a seed and two indices `x` and `y` using 10 iterations of `philox2x32` for randomization. The uniform distribution is obtained via Marsaglia's polar method. The poisson distribution uses Hormann's transformed rejection method and uses one of the indices to generate random sequences internally.

```
runif(seed, x, y)
rnorm(seed, x, y)
rpois(seed, x, float lambda)
```

## Example

Here are some more kernel examples.

A gamma function that uses a pivot specified in the perceptual CIELAB's `L` color space.
```
kernel gamma(I, G, P, O)
  const x = get_global_id(0)
  const y = get_global_id(1)

  var i = max(I[x, y], 0.0)
  var p = max(LtoY(P[x, y]), 0.0001)

  var j = (i.y/p) ^ (log(G[x, y])/log(0.5)) * p
  i = i * j / i.y

  O[x, y] = i
end
```

Pyramid down-sampling iteration:
```
const k = {0.0625, 0.25, 0.375, 0.25, 0.0625}

kernel pyrDown(I, G)
  const x = get_global_id(0)
  const y = get_global_id(1)
  const z = get_global_id(2)

	var h = array(5, 5)
	for i = 0, 4 do
		for j = 0, 4 do
			h[i, j] = I[x*2+i-2, y*2+j-2, z]
    end
  end

	var v = array(5)
	for i = 0, 4 do
		v[i] = 0
	end
	for i = 0, 4 do
		for j = 0, 4 do
			v[i] = v[i] + h[i, j]*k[j]
		end
  end

	var g = 0.0
	for i = 0, 4 do
		g = g + v[i]*k[i]
	end

	G[x, y, z] = g
end
```

Bilateral filter:
```
kernel bilateral(I, D, S, O)
  const x = get_global_id(0)
  const y = get_global_id(1)

	var w = 0.0
	var o = vec(0.0)

	var i = I[x, y]
	var df = max(D[x, y, 0], eps)^2*7.0
	var sf = max(S[x, y, 0], eps)^2*0.1

	for ox = -15, 15 do
		for oy = -15, 15 do
			var j = I[x+ox, y+oy]

			var d = ox^2 + oy^2
			var s = (i.x-j.x)^2 + (i.y-j.y)^2 + (i.z-j.z)^2
			var f = exp(-d/df - s/sf)

			o = o + f*j
			w = w + f
		end
  end

	O[x, y] = o / w
end
```

Median filter:
```
const A = {1,4,7,0,3,6,1,4,7,0,5,4,3,1,2,4,4,6,4}
const B = {2,5,8,1,4,7,2,5,8,3,8,7,6,4,5,7,2,4,2}

function switch(pix, idx)
  if pix[A[idx]] < pix[B[idx]] then
    var t = pix[B[idx]]
    pix[B[idx]] = pix[A[idx]]
    pix[A[idx]] = t
  end
end

kernel median(I, O)
  const x = get_global_id(0)
  const y = get_global_id(1)
  const z = get_global_id(2)

  var pix = array(9)

  pix[0] = I[x - 1, y - 1, z]
  pix[1] = I[x + 0, y - 1, z]
  pix[2] = I[x + 1, y - 1, z]
  pix[3] = I[x - 1, y + 0, z]
  pix[4] = I[x + 0, y + 0, z]
  pix[5] = I[x + 1, y + 0, z]
  pix[6] = I[x - 1, y + 1, z]
  pix[7] = I[x + 0, y + 1, z]
  pix[8] = I[x + 1, y + 1, z]

  for idx = 0, 18 do
    switch(pix, idx)
  end

  O[x, y, z] = pix[4]
end
```

