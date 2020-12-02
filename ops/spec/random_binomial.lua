return {
	name = "Binomial Noise",
	procName = "random_binomial",
	input = {
		[0] = {cs = "LRGB"},
		[1] = {cs = "LRGB"},
	},
	param = {
		[1] = {type = "float", name = "Variance", min = 0, max = 0.2, default = 0.05},
		[2] = {type = "bool", name = "Perceptual", default = true},
	},
	output = {
		[0] = {cs = "LRGB"}
	},
}
