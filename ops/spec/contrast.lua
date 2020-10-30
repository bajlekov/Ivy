return {
	name = "Contrast",
	procName = "contrast",
	input = {
		[0] = {cs = "XYZ"},
		[1] = {cs = "Y"},
		[2] = {cs = "Y"},
	},
	param = {
		[1] = {type = "float", name = "Contrast", min = 0, max = 2, default = 1},
		[2] = {type = "float", name = "Pivot", min = 0, max = 1, default = 0.5},
	},
	output = {
		[0] = {cs = "XYZ", shape = 0}
	},
}
