return {
	name = "Film Grain",
	procName = "random_film",
	input = {
		[0] = {cs = "Y"},
		[1] = {cs = "Y"},
		[2] = {cs = "Y"},
		[3] = {cs = "Y"},
	},
	param = {
		[1] = {type = "float", name = "Light", min = 0, max = 1, default = 0.5},
		[2] = {type = "float", name = "Grain Size", min = 0, max = 1, default = 0.3},
		[3] = {type = "float", name = "Variability", min = 0, max = 1, default = 0.1},
		[4] = {type = "bool", name = "HQ", default = false},
	},
	output = {
		[0] = {cs = "Y"}
	},
}
