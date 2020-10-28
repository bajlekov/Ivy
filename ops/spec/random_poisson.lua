return {
	name = "Shot Noise",
	procName = "random_poisson",
	input = {
		[0] = {cs = "LRGB"},
		[1] = {cs = "LRGB"},
	},
	param = {
		[1] = {type = "float", name = "Variance", min = 0, max = 0.5, default = 0.05},
	},
	output = {
		[0] = {cs = "LRGB"}
	},
}
