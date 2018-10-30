return {
	name = "Contrast",
	procName = "contrast",
	input = {
		[0] = {cs = "LAB"},
		[1] = {cs = "Y"},
	},
	param = {
		[1] = {type = "float", name = "Contrast", min = -1, max = 1, default = 0},
		[2] = {type = "bool", name = "Saturation", default = true},
	},
	output = {
		[0] = {cs = "LAB", shape = "image"}
	},
}
