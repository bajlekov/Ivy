--[[
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
]]

local Overlay = require "ui.overlay"
local ops = require "ops"

local overlayEssential = Overlay:new("Essential")
overlayEssential:addElem("addNode", 1, "Adjust", {ops, "adjust_basic"})
overlayEssential:addElem("addNode", 2, "White Balance", {ops, "sampleWB"})
overlayEssential:addElem("addNode", 3, "Sharpen", {ops, "sharpen"})
overlayEssential:addElem("addNode", 4, "Denoise", {ops, "nlmeans"})
overlayEssential:addElem("addNode", 5, "Enhance", {ops, "localLaplacian"})

local overlayLight = Overlay:new("Light")
overlayLight:addElem("addNode", 1, "Brightness", {ops, "brightness"})
overlayLight:addElem("addNode", 2, "Contrast", {ops, "contrast"})
overlayLight:addElem("addNode", 3, "Exposure", {ops, "exposure"})
overlayLight:addElem("addNode", 4, "Gamma", {ops, "gamma"})
overlayLight:addElem("addNode", 5, "Curve", {ops, "curveY"})
overlayLight:addElem("addNode", 6, "Parametric", {ops, "parametric"})
overlayLight:addElem("addNode", 7, "Levels", {ops, "levels"})


	local overlayWhiteBalance = Overlay:new("White Balance")
	overlayWhiteBalance:addElem("addNode", 1, "Temperature", {ops, "temperature"})
	overlayWhiteBalance:addElem("addNode", 2, "WB Sample", {ops, "sampleWB"})

	local overlayGrading = Overlay:new("Color:")
	overlayGrading:addElem("addNode", 1, "Lift", {ops, "color_lift"})
	overlayGrading:addElem("addNode", 2, "Gamma", {ops, "color_gamma"})
	overlayGrading:addElem("addNode", 3, "Gain", {ops, "color_gain"})
	overlayGrading:addElem("addNode", 4, "Offset", {ops, "color_offset"})
	overlayGrading:addElem("addNode", 5, "Shadows", {ops, "color_shadows"})
	overlayGrading:addElem("addNode", 6, "Midtones", {ops, "color_midtones"})
	overlayGrading:addElem("addNode", 7, "Highlights", {ops, "color_highlights"})

	local overlayLooks = Overlay:new("Looks")
	overlayLooks:addElem("addNode", 1, "Color LUT", {ops, "lutColor"})
	overlayLooks:addElem("addNode", 2, "B/W LUT", {ops, "lutBW"})


		local overlayAdjustCurves = Overlay:new("Curves")
		overlayAdjustCurves:addElem("addNode", 1, "Curve L(L)", {ops, "curveLL"})
		overlayAdjustCurves:addElem("addNode", 2, "Curve L(C)", {ops, "curveCL"})
		overlayAdjustCurves:addElem("addNode", 3, "Curve L(H)", {ops, "curveHL"})
		overlayAdjustCurves:addElem("addNode", 4, "Curve C(L)", {ops, "curveLC"})
		overlayAdjustCurves:addElem("addNode", 5, "Curve C(C)", {ops, "curveCC"})
		overlayAdjustCurves:addElem("addNode", 6, "Curve C(H)", {ops, "curveHC"})
		overlayAdjustCurves:addElem("addNode", 7, "Curve H(L)", {ops, "curveLH"})
		overlayAdjustCurves:addElem("addNode", 8, "Curve H(C)", {ops, "curveCH"})
		overlayAdjustCurves:addElem("addNode", 9, "Curve H(H)", {ops, "curveHH"})

		local overlayAdjustLive = Overlay:new("Live Adjust")
		overlayAdjustLive:addElem("addNode", 1, "Adjust L(L)", {ops, "adjustLL"})
		overlayAdjustLive:addElem("addNode", 2, "Adjust L(C)", {ops, "adjustCL"})
		overlayAdjustLive:addElem("addNode", 3, "Adjust L(H)", {ops, "adjustHL"})
		overlayAdjustLive:addElem("addNode", 4, "Adjust C(L)", {ops, "adjustLC"})
		overlayAdjustLive:addElem("addNode", 5, "Adjust C(C)", {ops, "adjustCC"})
		overlayAdjustLive:addElem("addNode", 6, "Adjust C(H)", {ops, "adjustHC"})
		overlayAdjustLive:addElem("addNode", 7, "Adjust H(L)", {ops, "adjustLH"})
		overlayAdjustLive:addElem("addNode", 8, "Adjust H(C)", {ops, "adjustCH"})
		overlayAdjustLive:addElem("addNode", 9, "Adjust H(H)", {ops, "adjustHH"})

	local overlayAdjust = Overlay:new("Adjust")
	overlayAdjust:addElem("menu", 1, "Curves", overlayAdjustCurves)
	overlayAdjust:addElem("menu", 2, "Live Adjust", overlayAdjustLive)


		local overlaySplit = Overlay:new("Split")
		local overlayMerge = Overlay:new("Merge")
		local overlayOverride = Overlay:new("Override")

		for k, v in ipairs{"SRGB", "LRGB", "XYZ", "LAB", "LCH"} do
			overlaySplit:addElem("addNode", k, v, {ops, "split"..v})
			overlayMerge:addElem("addNode", k, v, {ops, "merge"..v})
		end
		overlayOverride:addElem("addNode", 1, "Y as L", {ops, "castYtoL"})
		overlayOverride:addElem("addNode", 2, "L as Y", {ops, "castLtoY"})

	local overlayComponents = Overlay:new("Components")
	overlayComponents:addElem("menu", 1, "Split", overlaySplit)
	overlayComponents:addElem("menu", 2, "Merge", overlayMerge)
	overlayComponents:addElem("menu", 3, "Override", overlayOverride)

local overlayColor = Overlay:new("Color")
overlayColor:addElem("addNode", 1, "Vibrance", {ops, "vibrance"})
overlayColor:addElem("addNode", 2, "Saturation", {ops, "saturation"})
overlayColor:addElem("menu", 3, "White Balance", overlayWhiteBalance)
overlayColor:addElem("menu", 4, "Grading", overlayGrading)
overlayColor:addElem("menu", 5, "Looks", overlayLooks)
overlayColor:addElem("menu", 6, "Adjust", overlayAdjust)
overlayColor:addElem("addNode", 7, "RGB Curve", {ops, "curveRGB"})
overlayColor:addElem("addNode", 8, "RGB Mixer", {ops, "mixRGB"})
overlayColor:addElem("addNode", 9, "BW Mixer", {ops, "mixBW"})
overlayColor:addElem("addNode", 10, "Color Transfer", {ops, "colorTransfer"})
overlayColor:addElem("menu", 11, "Components", overlayComponents)

	local overlayEnhance = Overlay:new("Enhance")
	overlayEnhance:addElem("addNode", 1, "Local Laplacian", {ops, "localLaplacian"})
	overlayEnhance:addElem("addNode", 2, "Domain Transform", {ops, "domainTransform"})
	overlayEnhance:addElem("addNode", 3, "Tonal Contrast", {ops, "tonalContrast"})
	

	local overlaySharpen = Overlay:new("Sharpen")
	overlaySharpen:addElem("addNode", 1, "Unsharp Mask", {ops, "sharpen"})
	overlaySharpen:addElem("addNode", 2, "Deconvolution", {ops, "RLdeconvolution"})
	--overlaySharpen:addElem("addNode", 2, "Edge", {ops, "sharpen_edge"})

	local overlayDenoise = Overlay:new("Denoise")
	overlayDenoise:addElem("addNode", 1, "Nonlocal Means", {ops, "nlmeans"})
	overlayDenoise:addElem("addNode", 2, "Wiener Filter", {ops, "wiener"})
	overlayDenoise:addElem("addNode", 3, "Bilateral Filter", {ops, "bilateral"})
	overlayDenoise:addElem("addNode", 4, "Median Filter", {ops, "median"})

	local overlayFrequency = Overlay:new("Frequency")
	overlayFrequency:addElem("addNode", 1, "Low-Pass", {ops, "lowpass"})
	overlayFrequency:addElem("addNode", 2, "High-Pass", {ops, "highpass"})
	overlayFrequency:addElem("addNode", 3, "Pyramid Down", {ops, "pyrDown"})
	overlayFrequency:addElem("addNode", 4, "Pyramid Up", {ops, "pyrUp"})

local overlayDetail = Overlay:new("Detail")
overlayDetail:addElem("menu", 1, "Enhance", overlayEnhance)
overlayDetail:addElem("menu", 2, "Sharpen", overlaySharpen)
overlayDetail:addElem("menu", 3, "Denoise", overlayDenoise)
overlayDetail:addElem("menu", 4, "Frequency", overlayFrequency)
overlayDetail:addElem("addNode", 5, "Bokeh", {ops, "bokeh"})


	local overlayClone = Overlay:new("Clone")
	overlayClone:addElem("addNode", 1, "Clone", {ops, "clone"})
	overlayClone:addElem("addNode", 2, "Smart Clone", {ops, "cloneSmart"})
	overlayClone:addElem("addNode", 3, "Texture Clone", {ops, "cloneTexture"})

	local overlayLiveSelect = Overlay:new("Live Select")
	overlayLiveSelect:addElem("addNode", 1, "Smart Select", {ops, "smartSelect"})
	overlayLiveSelect:addElem("addNode", 2, "Color Select", {ops, "colorSelect"})
	overlayLiveSelect:addElem("addNode", 3, "Hue Select", {ops, "hueSelect"})
	overlayLiveSelect:addElem("addNode", 4, "Chroma Select", {ops, "chromaSelect"})
	overlayLiveSelect:addElem("addNode", 5, "Lightness Select", {ops, "lightnessSelect"})
	overlayLiveSelect:addElem("addNode", 6, "Distance Select", {ops, "distanceSelect"})

	local overlayMaskCurve = Overlay:new("Mask Curve")
	overlayMaskCurve:addElem("addNode", 1, "Lightness Mask", {ops, "lightnessMask"})
	overlayMaskCurve:addElem("addNode", 2, "Chroma Mask", {ops, "chromaMask"})
	overlayMaskCurve:addElem("addNode", 3, "Hue Mask", {ops, "hueMask"})
	overlayMaskCurve:addElem("addNode", 4, "Green-Red Mask", {ops, "greenRedMask"})
	overlayMaskCurve:addElem("addNode", 5, "Blue-Yellow Mask", {ops, "blueYellowMask"})

	local overlayBlend = Overlay:new("Blend")
	overlayBlend:addElem("addNode", 1, "Negate", {ops, "blend", "negate"})
	overlayBlend:addElem("addNode", 2, "Exclude", {ops, "blend", "exclude"})
	overlayBlend:addElem("addNode", 3, "Screen", {ops, "blend", "screen"})
	overlayBlend:addElem("addNode", 4, "Overlay", {ops, "blend", "overlay"})
	overlayBlend:addElem("addNode", 5, "Hard Light", {ops, "blend", "hardlight"})
	overlayBlend:addElem("addNode", 6, "Soft Light", {ops, "blend", "softlight"})
	overlayBlend:addElem("addNode", 7, "Dodge", {ops, "blend", "dodge"})
	overlayBlend:addElem("addNode", 8, "Soft Dodge", {ops, "blend", "softdodge"})
	overlayBlend:addElem("addNode", 9, "Burn", {ops, "blend", "burn"})
	overlayBlend:addElem("addNode", 10, "Soft Burn", {ops, "blend", "softburn"})
	overlayBlend:addElem("addNode", 11, "Linear Light", {ops, "blend", "linearlight"})
	overlayBlend:addElem("addNode", 12, "Vivid Light", {ops, "blend", "vividlight"})
	overlayBlend:addElem("addNode", 13, "Pin Light", {ops, "blend", "pinlight"})

	--[[
	local overlayMorphology = Overlay:new("Morphology")
	overlayMorphology:addElem("addNode", 1, "Erode", {ops, "erode"})
	overlayMorphology:addElem("addNode", 2, "Dilate", {ops, "dilate"})
	overlayMorphology:addElem("addNode", 3, "Open", {ops, "open"})
	overlayMorphology:addElem("addNode", 4, "Close", {ops, "close"})
	--]]

local overlayMask = Overlay:new("Mask")
overlayMask:addElem("addNode", 1, "Paint", {ops, "paintMaskSmart"})
overlayMask:addElem("menu", 2, "Clone", overlayClone)
overlayMask:addElem("menu", 3, "Live Select", overlayLiveSelect)
overlayMask:addElem("menu", 4, "Mask Curve", overlayMaskCurve)
overlayMask:addElem("addNode", 5, "Mix", {ops, "mix"})
overlayMask:addElem("addNode", 6, "Smart Mix", {ops, "smartMix"})
overlayMask:addElem("menu", 7, "Blend", overlayBlend)
--overlayMask:addElem("menu", 8, "Morphology", overlayMorphology)


	local overlayMathOps = Overlay:new("Operator")
	for k, v in ipairs{"Add", "Subtract", "Multiply", "Divide", "Power", "Absolute", "Negative", "Invert", "Clamp", "Clean", "Maximum", "Minimum", "Greater", "Less"} do
		overlayMathOps:addElem("addNode", k, v, {ops, "math", v})
	end

	local overlayMathStats = Overlay:new("Statistics")
	overlayMathStats:addElem("addNode", 1, "Maximum", {ops, "stat", "maximum"})
	overlayMathStats:addElem("addNode", 2, "Minimum", {ops, "stat", "minimum"})
	overlayMathStats:addElem("addNode", 3, "Mean", {ops, "stat", "mean"})
	overlayMathStats:addElem("addNode", 4, "SSD", {ops, "stat", "SSD"})
	overlayMathStats:addElem("addNode", 5, "SAD", {ops, "stat", "SAD"})

	--[[
	local overlayMathRange = Overlay:new("Range")
	overlayMathRange:addElem("addNode", 1, "[0, 1] => [-1, 1]", {ops, "range_to_symm"})
	overlayMathRange:addElem("addNode", 2, "[-1, 1] => [0, 1]", {ops, "range_from_symm"})
	overlayMathRange:addElem("addNode", 3, "[0, 1] => [L, H]", {ops, "range_to_lh"})
	overlayMathRange:addElem("addNode", 4, "[L, H] => [0, 1]", {ops, "range_from_lh"})
	overlayMathRange:addElem("addNode", 5, "Auto-Range", {ops, "range_auto"})
	--]]

	local overlayMathCurve = Overlay:new("Curve")
	overlayMathCurve:addElem("addNode", 1, "Map", {ops, "curveMap"})
	overlayMathCurve:addElem("addNode", 2, "Offset", {ops, "curveOffset"})
	overlayMathCurve:addElem("addNode", 3, "Modulate", {ops, "curveModulate"})

	local overlayMathNoise = Overlay:new("Noise")
	overlayMathNoise:addElem("addNode", 1, "Uniform", {ops, "random_uniform"})
	overlayMathNoise:addElem("addNode", 2, "Normal", {ops, "random_normal"})
	overlayMathNoise:addElem("addNode", 3, "Binomial", {ops, "random_binomial"})
	overlayMathNoise:addElem("addNode", 4, "Poisson", {ops, "random_poisson"})
	overlayMathNoise:addElem("addNode", 5, "Impulse", {ops, "random_impulse"})
	overlayMathNoise:addElem("addNode", 6, "Film Grain", {ops, "random_film"})

local overlayMath = Overlay:new("Math")
overlayMath:addElem("menu", 1, "Operator", overlayMathOps)
overlayMath:addElem("menu", 2, "Statistics", overlayMathStats)
overlayMath:addElem("menu", 3, "Curve", overlayMathCurve)
--overlayMath:addElem("menu", 4, "Range", overlayMathRange)
overlayMath:addElem("menu", 4, "Noise", overlayMathNoise)
overlayMath:addElem("addNode", 5, "Value", {ops, "math", "value"})

local overlayScript = Overlay:new("Script")
overlayScript:addElem("addNode", 1, "Script Y", {ops, "scriptY"})
overlayScript:addElem("addNode", 2, "Script RGB", {ops, "scriptRGB"})
overlayScript:addElem("addNode", 3, "Script LAB", {ops, "scriptLAB"})
overlayScript:addElem("addNode", 4, "Script LCH", {ops, "scriptLCH"})

local overlayCustom = Overlay:new("Custom")
overlayCustom:addElem("menu", 1, "Script", overlayScript)
overlayCustom:addElem("label", 2, "User-defined:")

-- load custom specifications
local f = io.open("ops/custom/custom.txt", "r")
if f then
	local idx = 3
	for line in f:lines() do
		local file = line:match("^%W*(.-)%W*$")
		local name = file:gsub("%.lua$", "")

		-- register in menu
		local spec = require("ops.custom.spec."..name)
		overlayCustom:addElem("addNode", idx, spec.name, {ops, spec.procName})

		idx = idx + 1
	end
end

local overlayPreview = Overlay:new("Preview")
overlayPreview:addElem("addNode", 1, "Preview", {ops, "preview"})
overlayPreview:addElem("addNode", 2, "Histogram", {ops, "histogram"})
overlayPreview:addElem("addNode", 3, "Waveform", {ops, "waveform"})
overlayPreview:addElem("addNode", 4, "AB Plot", {ops, "ABplot"})
overlayPreview:addElem("addNode", 5, "Split L/R", {ops, "split_lr"})
overlayPreview:addElem("addNode", 6, "Split U/D", {ops, "split_ud"})

local overlay = Overlay:new("Add node")
overlay:addElem("menu", 1, "Essential", overlayEssential)
overlay:addElem("menu", 2, "Light", overlayLight)
overlay:addElem("menu", 3, "Color", overlayColor)
overlay:addElem("menu", 4, "Detail", overlayDetail)
overlay:addElem("menu", 5, "Mask", overlayMask)
overlay:addElem("menu", 6, "Math", overlayMath)
overlay:addElem("menu", 7, "Custom", overlayCustom)
overlay:addElem("menu", 8, "Preview", overlayPreview)
overlay:addElem("addNode", 9, "Load Image", {ops, "image"})

overlay:default()

return overlay
