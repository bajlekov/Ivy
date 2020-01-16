return {
	name = "Random",
	procName = "random",
	input = {
		[0] = {cs = "LRGB"},
	},
	param = {
		[1] = {type = "float", name = "Strength", min = 0, max = 0.5, default = 0.1},
	},
	output = {
		[0] = {cs = "LRGB"}
	},
}
