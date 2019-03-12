Color Spaces
============

Ivy processes image data which stores color information in a 2-dimensional spatial grid. Color, as characterized by human visual perception, can be mapped to a 3-dimensional space defined by the 3 distinct response spectra of the cone cell photoreceptors in the human eye. These are defined as S (420nm–440nm), M (530nm-540nm), and L (560nm-580nm) corresponding to the peak wavelength they are sensitive to. However, the mapping of color to this LMS space is not always intuitive. Therefor several other color spaces have been defined which more closely match physical or perceptual concepts of light. Transformation between common color spaces are lossless, as they map the same 3-dimensional space.

.. note::
	For capturing and displaying purposes, the color space components are limited to a defined range (gamut). Within Ivy, this restriction is only applied when strictly necessary. The processing pipeline preserves out of gamut colors until export to file or display.

.. note::
	These color spaces do not capture spectrum of visible light in full detail. There is a loss of information when capturing light as a tristimulus color, whether with common imaging devices or in human vision. When looking at most commercially available imaging and display technology, imaging devices map the visible light spectrum to color such that the reproduced light spectrum will be perceived approximately the same as the original spectrum. The loss of spectral information is inherent to this process.

-------

.. _XYZ:

CIE XYZ
-------

The XYZ color space is closely related to human visual perception, where the Y component describes the perceived luminance, the Z component approximates the blue response of the S cones, and the X component is chosen such that all chromaticities of a given luminance Y are represented by positive XZ values.

:Internal name: XYZ
:Range: :math:`X, Y, Z \in [0, 1]`

----

.. _SRGB:

sRGB
----

The sRGB color space is primarily used in color displays, mapping to the red, green, and blue sub-pixels. Each of these RGB components is non-linearly transformed, originally to account for the gamma response of CRT displays. Nowadays, this transformation is preserved, as it allows for more efficient storage of human-discernible light levels than a linear mapping. In that sense it is also a (rough) approximation of the non-linear human light intensity perception. The sRGB color space is mapped to a range of :math:`[0, 1]` instead of the common :math:`[0, 255]`.

:Internal name: SRGB
:Range: :math:`R, G, B \in [0, 1]`

----------

.. _LRGB:

Linear RGB
-----------

Internally, a linear light equivalent of the SRGB_ color space is used. It is useful when dealing with the physical aspects of light, such as additive color mixing. The chromaticity of the RGB components is equivalent to that of the sRGB color space.

:Internal name: LRGB
:Range: :math:`R, G, B \in [0, 1]`

------

.. _LAB:

CIE Lab
-------

The LAB color space is designed to approximate human vision. It is perceptually uniform, and the L component matches the human perception of lightness. The A and B components represent the magenta-green axis and the yellow-blue axis respectively. While the definition of L has a range of :math:`[0, 100]` and AB a range of :math:`[-128, 128]`, these are normalized to a range of :math:`[0, 1]` and :math:`[-1, 1]` respectively.

:Internal name: LAB
:Range: :math:`L \in [0, 1]; A, B \in [-1, 1]`

.. note::
	While the LAB color space is based on human visual perception, there are many color appearance phenomena which are not taken into account. As such, it does not fully match human perception in visually complex scenes. It represents a reasonable trade-off between accuracy and complexity.

-------

.. _LCH:

CIE LCh
-------

Based on the previously described LAB_ color space, the LCH color space is a radial mapping of the AB coordinates into chroma C the length of the AB vector, and hue H the direction of the AB vector. The L component is the same as in LAB_. The H component range is internally changed from :math:`[0, 2 \cdot \pi]` to :math:`[0, 1]` for easier manipulation.

:Internal name: LCH
:Range: :math:`L, C, H \in [0, 1]`

--------

Y and L
-------

In addition to the trichromatic color values, Ivy internally uses two monochromatic data representations when there is no color information. This is useful for mask or modulation data. The Y and L representations are derived from the Y and L components of XYZ_ and LAB_ respectively. They offer a choice between linear light intensity or perceptual lightness scales.

.. _`Y`:

:Internal name: Y
:Range: :math:`Y \in [0, 1]`

-----

.. _`L`:

:Internal name: L
:Range: :math:`L \in [0, 1]`
