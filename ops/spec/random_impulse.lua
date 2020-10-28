return {
	name = "Impulse Noise",
	procName = "random_impulse",
	input = {
		[0] = {cs = "LRGB"},
		[1] = {cs = "LRGB"},
	},
	param = {
		[1] = {type = "float", name = "Probability", min = 0, max = 0.1, default = 0.01},
	},
	output = {
		[0] = {cs = "LRGB"}
	},
}
