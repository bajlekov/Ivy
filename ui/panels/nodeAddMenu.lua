--[[
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
]]

local Overlay = require "ui.overlay"
local ops = require "ops"

local overlayPreview = Overlay:new("Preview:")
overlayPreview:addElem("addNode", 1, "Preview", {ops, "preview"})
overlayPreview:addElem("addNode", 2, "Histogram", {ops, "histogram"})
overlayPreview:addElem("addNode", 3, "Waveform", {ops, "waveform"})
overlayPreview:addElem("addNode", 4, "AB Plot", {ops, "ABplot"})
overlayPreview:addElem("addNode", 5, "Split L/R", {ops, "split_lr"})
overlayPreview:addElem("addNode", 6, "Split U/D", {ops, "split_ud"})

local overlayAdjust = Overlay:new("Basic:")

--[[

Structure:

Adjust
	- Curves
	- Live Adjust [NYI]
Enhance
	- Detail
Mask
	- Live Select
Blend
Math
	- Stats
Generate
CS
	- Split
	- Merge
	- Convert
	- Override
Custom
	- Multi-scale
		- Pyramids
		- Wavelets
		- Bilateral grid
Preview
--]]

overlayAdjust:addElem("addNode", 1, "Brightness", {ops, "brightness"})
overlayAdjust:addElem("addNode", 2, "Contrast", {ops, "contrast"})
overlayAdjust:addElem("addNode", 3, "Vibrance", {ops, "vibrance"})
overlayAdjust:addElem("addNode", 4, "Exposure", {ops, "exposure"})
overlayAdjust:addElem("addNode", 5, "Gamma", {ops, "gamma"})
overlayAdjust:addElem("addNode", 6, "Saturation", {ops, "saturation"})
overlayAdjust:addElem("addNode", 7, "Temperature", {ops, "temperature"})
overlayAdjust:addElem("addNode", 8, "Sample WB", {ops, "autoWB"})
local overlayCurves = Overlay:new("Curves:")
overlayAdjust:addElem("menu", 9, "Curves", overlayCurves)
overlayCurves:addElem("addNode", 1, "Levels", {ops, "levels"})
overlayCurves:addElem("addNode", 2, "Parametric", {ops, "parametric"})
overlayCurves:addElem("addNode", 3, "Curve L", {ops, "curveL__"})
overlayCurves:addElem("addNode", 4, "Curve Y", {ops, "curveY__"})
overlayCurves:addElem("addNode", 5, "Curve RGB", {ops, "curveRGB"})
local overlayCurvesAdvanced = Overlay:new("Advanced:")
overlayCurves:addElem("menu", 6, "Advanced", overlayCurvesAdvanced)
overlayCurvesAdvanced:addElem("addNode", 1, "Curve L(L)", {ops, "curveLL"})
overlayCurvesAdvanced:addElem("addNode", 2, "Curve L(C)", {ops, "curveCL"})
overlayCurvesAdvanced:addElem("addNode", 3, "Curve L(H)", {ops, "curveHL"})
overlayCurvesAdvanced:addElem("addNode", 4, "Curve C(L)", {ops, "curveLC"})
overlayCurvesAdvanced:addElem("addNode", 5, "Curve C(C)", {ops, "curveCC"})
overlayCurvesAdvanced:addElem("addNode", 6, "Curve C(H)", {ops, "curveHC"})
overlayCurvesAdvanced:addElem("addNode", 7, "Curve H(L)", {ops, "curveLH"})
overlayCurvesAdvanced:addElem("addNode", 8, "Curve H(C)", {ops, "curveCH"})
overlayCurvesAdvanced:addElem("addNode", 9, "Curve H(H)", {ops, "curveHH"})
overlayCurvesAdvanced:addElem("addNode", 10, "Generic Map", {ops, "curveMap"})
overlayCurvesAdvanced:addElem("addNode", 11, "Generic Modulate", {ops, "curveModulate"})
overlayCurvesAdvanced:addElem("addNode", 12, "Generic Offset", {ops, "curveOffset"})
local overlayLiveAdjust = Overlay:new("Live Adjust:")
overlayAdjust:addElem("menu", 10, "Live Adjust", overlayLiveAdjust)
overlayLiveAdjust:addElem("addNode", 1, "Adjust L(L)", {ops, "adjustLL"})
overlayLiveAdjust:addElem("addNode", 2, "Adjust L(C)", {ops, "adjustCL"})
overlayLiveAdjust:addElem("addNode", 3, "Adjust L(H)", {ops, "adjustHL"})
overlayLiveAdjust:addElem("addNode", 4, "Adjust C(L)", {ops, "adjustLC"})
overlayLiveAdjust:addElem("addNode", 5, "Adjust C(C)", {ops, "adjustCC"})
overlayLiveAdjust:addElem("addNode", 6, "Adjust C(H)", {ops, "adjustHC"})
overlayLiveAdjust:addElem("addNode", 7, "Adjust H(L)", {ops, "adjustLH"})
overlayLiveAdjust:addElem("addNode", 8, "Adjust H(C)", {ops, "adjustCH"})
overlayLiveAdjust:addElem("addNode", 9, "Adjust H(H)", {ops, "adjustHH"})


local overlayEnhance = Overlay:new("Enhance:")
overlayEnhance:addElem("addNode", 1, "Detail", {ops, "localLaplacian"})
overlayEnhance:addElem("addNode", 2, "Sharpen", {ops, "sharpen"})
overlayEnhance:addElem("addNode", 3, "Denoise", {ops, "nlmeans"})
overlayEnhance:addElem("addNode", 4, "Detail EQ", {ops, "detailEQ"})
overlayEnhance:addElem("addNode", 5, "Structure", {ops, "structure"})
overlayEnhance:addElem("addNode", 6, "Clarity", {ops, "clarity"})
overlayEnhance:addElem("addNode", 7, "Compress", {ops, "compress"})
overlayEnhance:addElem("addNode", 8, "Tonal Contrast", {ops, "tonalContrast"})
overlayEnhance:addElem("addNode", 9, "Bilateral", {ops, "bilateral"})


local overlayMask = Overlay:new("Mask:")
local overlaySelect = Overlay:new("Live Select:")
overlayMask:addElem("menu", 1, "Live Select", overlaySelect)
overlaySelect:addElem("addNode", 1, "Smart Select", {ops, "smartSelect"})
overlaySelect:addElem("addNode", 2, "Color Select", {ops, "colorSelect"})
overlaySelect:addElem("addNode", 3, "Hue Select", {ops, "hueSelect"})
overlaySelect:addElem("addNode", 4, "Chroma Select", {ops, "chromaSelect"})
overlaySelect:addElem("addNode", 5, "Lightness Select", {ops, "lightnessSelect"})
overlaySelect:addElem("addNode", 6, "Distance Select", {ops, "distanceSelect"})
overlayMask:addElem("addNode", 2, "Lightness Mask", {ops, "lightnessMask"})
overlayMask:addElem("addNode", 3, "Chroma Mask", {ops, "chromaMask"})
overlayMask:addElem("addNode", 4, "Hue Mask", {ops, "hueMask"})
overlayMask:addElem("addNode", 5, "Green-Red Mask", {ops, "greenRedMask"})
overlayMask:addElem("addNode", 6, "Blue-Yellow Mask", {ops, "blueYellowMask"})
overlayMask:addElem("addNode", 7, "Mix", {ops, "mix"})
overlayMask:addElem("addNode", 8, "Smart Mix", {ops, "smartMix"})

local clutColor = {"Precisa", "Vista", "Astia", "Provia", "Sensia", "Superia", "Velvia", "Ektachrome", "Kodachrome", "Portra"}
local clutBW = {"Neopan", "Delta", "Tri-X"}
local overlayColor = Overlay:new("Color:")
for k, v in ipairs(clutColor) do
	overlayColor:addElem("addNode", k, v, {ops, "clut", v})
end
local overlayBW = Overlay:new("Black & White")
for k, v in ipairs(clutBW) do
	overlayBW:addElem("addNode", k, v, {ops, "clut", v})
end
local overlayCLUT = Overlay:new("Looks:")
overlayCLUT:addElem("menu", 1, "Color", overlayColor)
overlayCLUT:addElem("menu", 2, "Black & White", overlayBW)

local overlayColor = Overlay:new("Color:")
overlayColor:addElem("addNode", 1, "Lift", {ops, "color_lift"})
overlayColor:addElem("addNode", 2, "Gamma", {ops, "color_gamma"})
overlayColor:addElem("addNode", 3, "Gain", {ops, "color_gain"})
overlayColor:addElem("addNode", 4, "Offset", {ops, "color_offset"})
overlayColor:addElem("addNode", 5, "Shadows", {ops, "color_shadows"})
overlayColor:addElem("addNode", 6, "Midtones", {ops, "color_midtones"})
overlayColor:addElem("addNode", 7, "Highlights", {ops, "color_highlights"})
overlayColor:addElem("menu", 8, "Looks", overlayCLUT)

local overlayMath = Overlay:new("Math:")
overlayMath:addElem("addNode", 2, "Value", {ops, "math", "value"})
for k, v in ipairs{"Add", "Subtract", "Multiply", "Divide", "Power", "Absolute", "Negative", "Invert", "Clamp", "Maximum", "Minimum", "Greater", "Less"} do
	overlayMath:addElem("addNode", k + 2, v, {ops, "math", v})
end
local overlayStats = Overlay:new("Stats:")
overlayMath:addElem("menu", 1, "Stats", overlayStats)
overlayStats:addElem("addNode", 1, "Maximum", {ops, "stat", "maximum"})
overlayStats:addElem("addNode", 2, "Minimum", {ops, "stat", "minimum"})
overlayStats:addElem("addNode", 3, "Mean", {ops, "stat", "mean"})
overlayStats:addElem("addNode", 4, "SSD", {ops, "stat", "SSD"})
overlayStats:addElem("addNode", 5, "SAD", {ops, "stat", "SAD"})



local overlayBlend = Overlay:new("Blend:")
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

local overlayGenerate = Overlay:new("Generate:")
overlayGenerate:addElem("addNode", 1, "X-Y", {ops, "xy"})
overlayGenerate:addElem("addNode", 2, "Radial", {ops, "radial"})
overlayGenerate:addElem("addNode", 3, "Linear", {ops, "linear"})
overlayGenerate:addElem("addNode", 4, "Mirrored", {ops, "mirrored"})

local overlayCS = Overlay:new("Color Space:")
local overlayCSsplit = Overlay:new("Split:")
local overlayCSmerge = Overlay:new("Merge:")
local overlayCSconvert = Overlay:new("Convert:")
local overlayCSoverride = Overlay:new("Override:")
overlayCS:addElem("menu", 1, "Split", overlayCSsplit)
overlayCS:addElem("menu", 2, "Merge", overlayCSmerge)
overlayCS:addElem("menu", 3, "Convert", overlayCSconvert)
overlayCS:addElem("menu", 4, "Override", overlayCSoverride)
for k, v in ipairs{"SRGB", "LRGB", "XYZ", "LAB", "LCH"} do
	overlayCSsplit:addElem("addNode", k, v, {ops, "decompose"..v})
	overlayCSmerge:addElem("addNode", k, v, {ops, "compose"..v})
end
for k, v in ipairs{"SRGB", "LRGB", "XYZ", "LAB", "LCH", "Y", "L"} do
	overlayCSconvert:addElem("addNode", k, v, {ops, "cs", v})
end
overlayCSoverride:addElem("addNode", 1, "Y as L", {ops, "castYtoL"})
overlayCSoverride:addElem("addNode", 2, "L as Y", {ops, "castLtoY"})

local overlayMultiScale = Overlay:new("Multi-Scale:")
overlayMultiScale:addElem("addNode", 1, "Blur", {ops, "blur"})
overlayMultiScale:addElem("addNode", 2, "PyrDown", {ops, "pyrDown"})
overlayMultiScale:addElem("addNode", 3, "PyrUp", {ops, "pyrUp"})

local overlayCustom = Overlay:new("Custom:")
overlayCustom:addElem("label", 1, "Experimental")
overlayCustom:addElem("menu", 2, "Multi-Scale", overlayMultiScale)
overlayCustom:addElem("addNode", 3, "Mix RGB", {ops, "mixRGB"})
overlayCustom:addElem("addNode", 4, "Load Image", {ops, "image"})
overlayCustom:addElem("addNode", 5, "Paint Mask", {ops, "paintMask"})
overlayCustom:addElem("addNode", 6, "Paint Smart", {ops, "paintMaskSmart"})
overlayCustom:addElem("addNode", 7, "Script RGB", {ops, "scriptRGB"})
overlayCustom:addElem("addNode", 8, "Script LAB", {ops, "scriptLAB"})
overlayCustom:addElem("addNode", 9, "Script LCH", {ops, "scriptLCH"})
overlayCustom:addElem("addNode", 10, "Hist EQ", {ops, "histEQ"})
overlayCustom:addElem("label", 11, "User-defined")


local overlay = Overlay:new("Add node:")
overlay:addElem("menu", 1, "Adjust", overlayAdjust)
overlay:addElem("menu", 2, "Enhance", overlayEnhance)
overlay:addElem("menu", 3, "Color", overlayColor)
overlay:addElem("menu", 4, "Mask", overlayMask)
overlay:addElem("menu", 5, "Blend", overlayBlend)
overlay:addElem("menu", 6, "Math", overlayMath)
overlay:addElem("menu", 7, "Generate", overlayGenerate)
overlay:addElem("menu", 8, "Color Space", overlayCS)
overlay:addElem("menu", 9, "Custom", overlayCustom)
overlay:addElem("menu", 10, "Preview", overlayPreview)

overlay:default()

return overlay
