return {
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
