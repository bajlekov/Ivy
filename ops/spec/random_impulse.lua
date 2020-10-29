return {
	name = "Impulse Noise",
	procName = "random_impulse",
	input = {
		[0] = {cs = "LRGB"},
		[1] = {cs = "LRGB"},
	},
	param = {
		[1] = {type = "float", name = "Probability", min = 0, max = 0.1, default = 0.01},
		[2] = {type = "bool", name = "White", default = true},
		[3] = {type = "bool", name = "Black", default = true},
	},
	output = {
		[0] = {cs = "LRGB"}
	},
}
