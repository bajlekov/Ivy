.. _Adjust:

Adjust modules
==============

These modules offer the basic tools for global adjustments of the image being processed. All operations are pixel-wise.

.. contents:: List of Modules
	:depth: 2
	:local:

Brightness
++++++++++

.. image:: nodes/brightness/node.png

:Brightness: Modifies image brightness
:Preserve Hue: Preserves input image hue in LCH space
:Group: Adjust_
:Color Space: :ref:`LRGB<LRGB>`

This module changes the brightness of the image by adjusting the slope at :math:`0.0` with the ``Brightness`` parameter, and preserves the white point by compressing the curve toward :math:`1.0` :eq:`brightness-function`. The ``Preserve Hue`` parameter applies the hue of the input image to that of the output image in LCH space :eq:`brightness-hue-function`.

.. Warning::
	The module is intended to preserve the brightened image's black point and white point. However, color channels might be pushed out of gamut when ``Preserve Hue`` is enabled.

.. list-table::
	:widths: 10 50 50
	:header-rows: 1
	:stub-columns: 1
	:align: center

	*	* Brightness
		* Preserve Hue: On
		* Preserve Hue: Off
	*	* -1.0
		* .. image:: nodes/brightness/-1_V.png
		* .. image:: nodes/brightness/-1_X.png
	*	* +0.0
		* .. image:: nodes/brightness/0.png
		* .. image:: nodes/brightness/0.png
	*	* +1.0
		* .. image:: nodes/brightness/+1_V.png
		* .. image:: nodes/brightness/+1_X.png

.. image:: nodes/brightness/plot.png
	:align: center

.. math::
	:label: brightness-function

	\begin{align}
		B & =  Brightness + 1 \\
		Output_{RGB} & = (1-B) \cdot Input_{RGB}^2 + B \cdot Input_{RGB}
	\end{align}

.. math::
	:label: brightness-hue-function

	Output_H = Input_H

--------

Contrast
++++++++

.. image:: nodes/contrast/node.png

:Contrast: Modifies image mid-tone contrast
:Saturation: Preserves image saturation instead of chroma
:Group: Adjust_
:Color Space: :ref:`LAB<LAB>`

This module changes the contrast of the image by adjusting the LAB lightness slope at :math:`0.5` with the ``Contrast`` parameter, and preserves the black point and white point by compressing the extremes :eq:`contrast-function`. The ``Saturation`` parameter enables scaling of the chroma channel to preserve constant saturation instead of constant chroma when the lightness channel is modified :eq:`contrast-function`.

This module does not account for changes in saturation perception due to a change in scene luminance contrast, as this is very much scene-dependent. A perceived decrease in saturation when increasing contrast and vice versa is observable. This can be corrected appropriately with the Vibrance_ or Saturation_ module.

.. warning::
	The luminance black point and white point are preserved. Color channels may be pushed out of gamut.

.. note::
	Setting the ``Contrast`` parameter to :math:`0.0` creates a contrast curve with a slope of :math:`0.0` in the mid-tones. This results in a very flat output image.

.. list-table::
	:widths: 10 50 50
	:header-rows: 1
	:stub-columns: 1
	:align: center

	*	* Contrast
		* Saturation: On
		* Saturation: Off
	*	* -1.0
		* .. image:: nodes/contrast/test1/-1_V.png
		* .. image:: nodes/contrast/test1/-1_X.png
	*	* +0.0
		* .. image:: nodes/contrast/test1/0.png
		* .. image:: nodes/contrast/test1/0.png
	*	* +1.0
		* .. image:: nodes/contrast/test1/+1_V.png
		* .. image:: nodes/contrast/test1/+1_X.png

.. list-table::
	:widths: 10 50 50
	:header-rows: 1
	:stub-columns: 1
	:align: center

	*	* Contrast
		* Saturation: On
		* Saturation: Off
	*	* -1.0
		* .. image:: nodes/contrast/test2/-1_V.png
		* .. image:: nodes/contrast/test2/-1_X.png
	*	* +0.0
		* .. image:: nodes/contrast/test2/0.png
		* .. image:: nodes/contrast/test2/0.png
	*	* +1.0
		* .. image:: nodes/contrast/test2/+1_V.png
		* .. image:: nodes/contrast/test2/+1_X.png

.. image:: nodes/contrast/plot.png
	:align: center

.. math::
	:label: contrast-function

	\begin{align}
		C &= Contrast + 1 \\
		I &= 2 \cdot Input_L - 1 \\
		O &= \left\{
			\begin{array}{rl}
				(C-1) \cdot I^2 + I \cdot C & I < 0 \\
				(1-C) \cdot I^2 + I \cdot C & I > 0
			\end{array}
		\right. \\
		Output_L &= \frac{O + 1}{2} \\
	\end{align}

.. math::
	:label: contrast-saturation-function

	Output_{AB} = Input_{AB} \cdot (Output_L - Input_L)

--------

Vibrance
++++++++

.. image:: nodes/vibrance/node.png

:Vibrance: Increases color saturation, mainly in less saturated areas
:Group: Adjust_
:Color Space: :ref:`LCH<LCH>`

This module changes the color saturation such that less saturated colors are boosted. It adjusts the LCH chroma channel slope at :math:`0.0` with the ``Vibrance`` parameter, and preserves the saturation point by compressing the curve toward :math:`1.0` :eq:`vibrance-function`. The ``Vibrance`` effect is modulated with the image's lightness channel, such that the effect decreases linearly for darker colors. In addition, the output image lightness is decreased proportional to the increase in chroma :math:`\times 0.2` to further enhance color perception.

.. warning::
	While chroma in the LCH space is limited to :math:`1.0`, the resulting colors at this limit are still outside the sRGB gamut. This module does not necessarily prevent oversaturation.

.. list-table::
	:widths: 10 50 50
	:header-rows: 1
	:stub-columns: 1
	:align: center

	*	* Value
		* Vibrance
		* Saturation_ :math:`\times 0.5`
	*	* -1.0
		* .. image:: nodes/vibrance/-1.png
		* .. image:: nodes/saturation/-0.5.png
	*	* +0.0
		* .. image:: nodes/vibrance/0.png
		* .. image:: nodes/saturation/0.png
	*	* +1.0
		* .. image:: nodes/vibrance/+1.png
		* .. image:: nodes/saturation/+0.5.png

.. math::
	:label: vibrance-function

	\begin{align}
		V &= Vibrance \cdot Input_L + 1 \\
		Output_C &= (1-V) \cdot Input_C^2 + V \cdot Input_C \\
		Output_L &= Input_L \cdot (1 - 0.2 \cdot (Output_C - Input_C))
	\end{align}

.. note::
	The chroma curve for the Vibrance_ module is equivalent to the Brightness_ module curve. However, the strength of the ``Vibrance`` parameter is in addition modulated by the input image lightness, making the curve dependent on both lightness and chroma.

----------

Saturation
++++++++++

.. image:: nodes/saturation/node.png

:Saturation: Increases color saturation linearly
:Group: Adjust_
:Color Space: :ref:`LCH<LCH>`

This module changes the LCH chroma linearly with the ``Saturation`` parameter as multiplication factor :eq:`saturation-function`. It allows for full desaturation of the input image, as well as unbounded oversaturation.

.. list-table::
	:widths: 10 50
	:header-rows: 1
	:stub-columns: 1
	:align: center

	*	* Value
		* Saturation
	*	* -1.0
		* .. image:: nodes/saturation/-1.png
	*	* -0.5
		* .. image:: nodes/saturation/-0.5.png
	*	* +0.0
		* .. image:: nodes/saturation/0.png
	*	* +0.5
		* .. image:: nodes/saturation/+0.5.png
	*	* +1.0
		* .. image:: nodes/saturation/+1.png

.. math::
	:label: saturation-function

	Output_C = Input_C \cdot Saturation

-----------

Temperature
+++++++++++

.. image:: nodes/temperature/node.png

:Temperature: Source correlated color temperature (K)
:Tint: Green tint
:Group: Adjust_
:Color Space: :ref:`XYZ<XYZ>`

This module corrects color cast due to the difference in scene illuminants compared to the white point of the viewing environment. The ``Temperature`` parameter indicates the correlated color temperature of the illuminant of the scene. The source color temperature is converted to a source white reference :math:`RefSource_{LMS}` :eq:`temperature-cct-daylight`. The ``Tint`` parameter additionally scales the source white reference Y to correct a green cast. The destination white reference :math:`RefDest_{LMS}` is computed for :math:`T = 6500\,K` illuminant to match the D65 standard illuminant of sRGB. Chromatic adaptation is performed using the Von Kries transform in LMS space :eq:`temperature-chromatic-adaptation`. A Bradford matrix :eq:`temperature-bradford-matrix` is used for the conversion from XYZ to LMS.

.. note::
	The conversion from correlated color temperature to chromaticity is performed using the daylight locus as reference instead of the black body locus. This should be more appropriate for naturally occurring light.

.. list-table::
	:widths: 10 50 50 50
	:header-rows: 1
	:stub-columns: 1
	:align: center

	*	* Temperature
		* Tint: 0.9
		* Tint: 1.0
		* Tint: 1.1
	*	* 3800 K
		* .. image:: nodes/temperature/3800_0.9.png
		* .. image:: nodes/temperature/3800_1.png
		* .. image:: nodes/temperature/3800_1.1.png
	*	* 4700K
		* .. image:: nodes/temperature/4700_0.9.png
		* .. image:: nodes/temperature/4700_1.png
		* .. image:: nodes/temperature/4700_1.1.png
	*	* 5600K
		* .. image:: nodes/temperature/5600_0.9.png
		* .. image:: nodes/temperature/5600_1.png
		* .. image:: nodes/temperature/5600_1.1.png
	*	* 6500K
		* .. image:: nodes/temperature/6500_0.9.png
		* .. image:: nodes/temperature/6500_1.png
		* .. image:: nodes/temperature/6500_1.1.png
	*	* 8300K
		* .. image:: nodes/temperature/8300_0.9.png
		* .. image:: nodes/temperature/8300_1.png
		* .. image:: nodes/temperature/8300_1.1.png
	*	* 11000K
		* .. image:: nodes/temperature/11000_0.9.png
		* .. image:: nodes/temperature/11000_1.png
		* .. image:: nodes/temperature/11000_1.1.png
	*	* 15500K
		* .. image:: nodes/temperature/15500_0.9.png
		* .. image:: nodes/temperature/15500_1.png
		* .. image:: nodes/temperature/15500_1.1.png

.. math::
	:label: temperature-bradford-matrix

	M_{Bradford} = \left[
	\begin{array}{rrr}
	0.8951 & 0.2664 & 0.1614 \\
	-0.7502 & 1.7135 & 0.0367 \\
	0.0389 & 0.0685 & 1.0296
	\end{array}
	\right]

.. math::
	:label: temperature-cct-daylight

	\begin{align}
	T &=  Temperature \\
	x &=  \left\{\begin{array}{rl}
		\frac{0.27475E9}{T^3} - \frac{0.98598E6}{T^2} + \frac{1.17444E3}{T} + 0.145986 & T < 4000 \\
		\frac{-4.6070E9}{T^3} + \frac{2.9678E6}{T^2}  + \frac{0.09911E3}{T} + 0.244063 & 4000 < T < 7000 \\
		\frac{-2.0064E9}{T^3} + \frac{1.9018E6}{T^2}  + \frac{0.24748E3}{T} + 0.237040 & 7000 < T
	\end{array}\right. \\
	y &=  -3 \cdot x^2 + 2.87 \cdot x - 0.275 \\
	\left[ \begin{array}{c} L \\ M \\ S \end{array} \right] &=
	M \cdot \left[ \begin{array}{c} X \\ Y \\ Z \end{array} \right] =
	M \cdot \left[ \begin{array}{c} \frac{x}{y} \\ Tint \\ \frac{1-x-y}{y} \end{array} \right]
	\end{align}

.. math::
	:label: temperature-chromatic-adaptation

	Output_{XYZ} = M^{-1} \cdot
	\left[ \begin{array}{ccc}
		\frac{RefDest_L}{RefSource_L} & 0 & 0 \\
		0 & \frac{RefDest_M}{RefSource_M} & 0 \\
		0 & 0 & \frac{RefDest_S}{RefSource_S}
	\end{array} \right]
	\cdot M \cdot Input_{XYZ}

-------------

.. _`Adjust > Curves`:

Curve Modules
=============

The curve modules allow fine control of image adjustments. They define a mapping between one parameter and another specified as a user-defined function. The output of the mapping function can either set an absolute value, or offset or modulate the original value.

.. contents:: List of Modules
	:depth: 2
	:local:

----------------

Parametric Curve
++++++++++++++++

.. image:: nodes/parametric/node.png

:Shadows: Adjustment of the shadows
:Darks: Adjustment of the dark tones
:Lights: Adjustment of the light tones
:Highlights: Adjustment of the highlights
:Group: `Adjust > Curves`_
:Color Space: :ref:`LAB<LAB>`

This module adjusts the lightness L in four tonal regions. The overall adjustment is a brightness offset factor :math:`F_{Tone}` for each region :eq:`parametric-brightness-function`, where :math:`V_{Tone}` is one of the ``Shadows``, ``Darks``, ``Lights``, or ``Highlights`` parameters. These curves are scaled and linearly modulated depending on the tonal range. They are combined in :eq:`parametric-full-function`, where  :math:`F_{Shadows}` and :math:`F_{Highlights}` are modulated with the headroom remaining after :math:`F_{Darks} + F_{Lights}` is applied. The saturation is preserved in the AB components :eq:`parametric-saturation-function`.

.. list-table::
	:widths: 10 50 50
	:header-rows: 1
	:stub-columns: 1
	:align: center

	*	* Tone
		* -1.0
		* +1.0
	*	* Shadows
		* .. image:: nodes/parametric/S-1.png
		* .. image:: nodes/parametric/S+1.png
	*	* Darks
		* .. image:: nodes/parametric/D-1.png
		* .. image:: nodes/parametric/D+1.png
	*	* Lights
		* .. image:: nodes/parametric/L-1.png
		* .. image:: nodes/parametric/L+1.png
	*	* Highlights
		* .. image:: nodes/parametric/H-1.png
		* .. image:: nodes/parametric/H+1.png

.. math::
	:label: parametric-brightness-function

	\begin{align}
	I &= Input_L \\
	F_{Shadows} &=
		\left\{\begin{array}{rl}
			V_{Shadows} \cdot I \cdot (2 \cdot I - 1)^2 & I<0.5 \\
			0 & I>0.5
		\end{array}\right. \\
	F_{Darks} &= V_{Darks} \cdot (I - 1)^2 \cdot I \\
	F_{Lights} &= -V_{Lights} \cdot (I - 1) \cdot I^2 \\
	F_{Highlights} &=
		\left\{\begin{array}{rl}
		0 & I<0.5 \\
		- V_{Highlights} \cdot (I-1) \cdot (2 \cdot I - 1)^2 & I>0.5
		\end{array}\right.
	\end{align}

.. image:: nodes/parametric/plot.png
	:align: center

.. math::
	:label: parametric-full-function

	\begin{align}
		O &= Input_L + F_{Darks} + F_{Lights} \\
		Output_L &= O + F_{Shadows} \cdot \frac{O}{Input_L} + F_{Highlights} \cdot \frac{1-O}{1-Input_L}
	\end{align}

.. math::
	:label: parametric-saturation-function

	Output_{AB} = Input_{AB} \cdot (Output_L - Input_L)

-------

Curve L
+++++++

.. image:: nodes/curves/curve_L.png

:Preserve Saturation: Maintain constant saturation
:Group: `Adjust > Curves`_
:Color Space: :ref:`LAB<LAB>`

This module sets the output lightness L as function of the input lightness. The implementation is similar to that of the Contrast_ module :eq:`l-curve-function`, but with a user-defined curve :math:`f`.  The ``Saturation`` parameter enables scaling of the chroma channel to preserve constant saturation instead of constant chroma when the lightness channel is modified :eq:`l-curve-saturation-function`.

.. math::
	:label: l-curve-function

	Output_L = f(Input_L)

.. math::
	:label: l-curve-saturation-function

	Output_{AB} = Input_{AB} \cdot (Output_L - Input_L)

-------

Curve Y
+++++++

.. image:: nodes/curves/curve_Y.png

:Preserve Hue: Preserves input image hue in LCH space
:Group: `Adjust > Curves`_
:Color Space: :ref:`XYZ<XYZ>`

This module sets the output luminance Y as function of the input luminance. The implementation is similar to that of the Brightness_ module :eq:`y-curve-function`, but with a user-defined curve :math:`f`. The ``Preserve Hue`` parameter applies the hue of the input image to that of the output image in LCH space :eq:`y-curve-hue-function`.

.. math::
	:label: y-curve-function

	Output_Y = f(Input_Y)

.. math::
	:label: y-curve-hue-function

	Output_H = Input_H

---------------

.. _`Adjust > Curves > Advanced`:

Advanced Curve modules
++++++++++++++++++++++

:Group: `Adjust > Curves > Advanced`_
:Color Space: :ref:`LCH<LCH>`

These curves map one component of the LCH color space against another in the following way, where :math:`f` is the curve function:

:Curve L-L: :math:`Output_L = f(Input_L)`
:Curve L-C: :math:`Output_C = Input_C \cdot f(Input_L)`
:Curve L-H: :math:`Output_H = Input_H + f(Input_L)`

-------

:Curve C-L: :math:`Output_L = Input_L \cdot f(Input_C)`
:Curve C-C: :math:`Output_C = f(Input_C)`
:Curve C-H: :math:`Output_H = Input_H + f(Input_C)`

-------

:Curve H-L: :math:`Output_L = Input_L \cdot ((f(Input_H)-1) \cdot Input_C + 1)`
:Curve H-C: :math:`Output_C = Input_C \cdot f(Input_H)`
:Curve H-H: :math:`Output_H = Input_H + f(Input_H)`

.. note::
	The H-L curve effect is modulated with chroma, such that low chroma input with noisy hue does not result in noisy lightness in the output.

------------------

Mask Curve Modules
++++++++++++++++++

:Group: `Adjust > Curves > Advanced`_
:Color Space: :ref:`LCH<LCH>` > :ref:`Y<Y>`

These curves create a single-channel mask output based on curve :math:`f` applied to the input channel:

:Select L: :math:`Output_Y = f(Input_L)`
:Select C: :math:`Output_Y = f(Input_C)`
:Select H: :math:`Output_Y = f(Input_H)`
