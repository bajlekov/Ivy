# Ivy

![Ivy](https://raw.githubusercontent.com/bajlekov/Ivy/main/doc/source/preview.png)

Ivy is an image processing program aimed at general photography. At its core is a flexible processing pipeline, allowing easy operator arrangement and parameter tuning. The processing is fully configurable and easily extensible through Ivy Script, a domain specific language for image computation kernels. All image operations are GPU-accelerated.

## Design

Ivy's image processing pipeline is defined as a directed acyclic graph, which is constructed using a custom node-based graphical user interface. Every node represents an operation on an image, and multiple nodes can be combined in an intricate process. The defined process is executed continuously on every change, and provides an interactive preview of the resulting output image. While the primary function is photo editing, the flexibility this process representation allows its use in far more complex image processing tasks.

Each node has a number of connections to other nodes, either inputs for image data the node consumes, or outputs for image data that the node produces. Nodes also have parameters which can be tweaked using UI elements on the node itself. However the majority of those parameters also have data inputs, overriding the UI element and allowing those parameters to be driven by spatially varying data.

While this approach is less common in the photography ecosystem, it is ubiquitous in video editing and 3D rendering. In comparison to layer based image editing with a history stack, the node-based paradigm offers non-destructive editing and changes in any step of the process as the full image is continuously recomputed with the new parameters. In comparison to non-destructive editors with a fixed pipeline, a node-based approach provides much more flexibility in the definition of the process. IAdditionally, the non-linear data flow allows splitting and merging paths of the process to facilitate local and conditional operations (pretty much anything short of iterative or recursive processes should be possible). Lastly, in comparison to programming API's for image processing, this approach provides a much more intuitive visual representation of the data flow and direct visual feedback on changes.

There definitely are trade-offs and it's advisable to pick the right tool for the job. Yet, this approach largely provides an intuitive experience and freedom to explore image processing while reducing cognitive overhead.

## Operators

Ivy covers most of the expected photo editing operations, including:
* Light and color adjustments, 3D LUT support
* Detail enhancement, noise suppression, and spot cloning
* Parametric and painted masks, adjustment curves and layer blending
* Math operations, statistics and noise generation with various distributions
* Flexible color space manipulation, channel splitting and merging
* In-line scriptable nodes for complex expressions
* Histograms, waveforms, radial plots and intermediate previews

Some notable operators:
* Local laplacian contrast enhancement
* Domain transform edge-preserving smoothing
* Non-local means denoising
* Similarity-guided mask painting
* Luminance curves with detail preservation
* Physical film grain simulation

## Extensibility

In addition, both image processing kernels and node definitions are fully customizable and extendable. They are both just-in-time compiled and can be edited at run-time if desired. For example, the definition of the gamma operator below:

An image processing kernel that defines the operation to be performed:
```
kernel gamma(I, P, O)
	const x = get_global_id(0)
	const y = get_global_id(1)

	var i = I[x, y]
	var p = P[x, y]

	O[x, y] = max(i, 0.0) ^ (log(p)/log(0.5))
end
```

The node executor, defining how to execute the kernel:
```
function execute(proc)
	local I, P, O = proc:getAllBuffers(3)
	proc:executeKernel("gamma", size2D(O), {I, P, O})
end
```

And finally the node interface definition with inputs, outputs and parameters:
```
{
	name = "Gamma",
	procName = "gamma",
	input = {
		[0] = {cs = "XYZ"},
		[1] = {cs = "Y"},
		[2] = {cs = "Y"},
	},
	param = {
		[1] = {type = "float", name = "Gamma", min = 0, max = 1, default = 0.5},
		[2] = {type = "float", name = "Pivot", min = 0, max = 1, default = 1},
	},
	output = {
		[0] = {cs = "XYZ", shape = 0}
	},
}
```

## Documentation

*This is largely a work in progress, mostly incomplete and possibly outdated.*

<https://ivy-image-processor.readthedocs.io/en/latest/>
