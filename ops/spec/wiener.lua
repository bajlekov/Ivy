return {
	name = "Wiener Filter",
	procName = "wiener",
	input = {
		[0] = {cs = "LRGB"},
		[1] = {cs = "LRGB"},
	},
	param = {
		[1] = {type = "float", name = "Strength", min = 0, max = 1, default = 0.1},
	},
	output = {
		[0] = {cs = "LRGB"}
	},
}
