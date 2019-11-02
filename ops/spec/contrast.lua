return {
	name = "Contrast",
	procName = "contrast",
	input = {
		[0] = {cs = "XYZ"},
		[1] = {cs = "Y"},
	},
	param = {
		[1] = {type = "float", name = "Contrast", min = 0, max = 2, default = 1},
	},
	output = {
		[0] = {cs = "XYZ", shape = 0}
	},
}
