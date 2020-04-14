return {
	name = "Watershed",
	procName = "watershed",
	input = {
		[0] = {cs = "LAB"},
		[1] = {cs = "Y"},
	},
	param = {
		[1] = {type = "text", left = "Mask"},
	},
	output = {
		[0] = {cs = "XYZ"}
	},
}
