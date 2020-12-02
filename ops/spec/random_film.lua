return {
	name = "Film Grain",
	procName = "random_film",
	input = {
		[0] = {cs = "Y"},
		[1] = {cs = "Y"},
		[2] = {cs = "Y"},
		[5] = {cs = "Y"},
		[6] = {cs = "Y"},
	},
	param = {
		[1] = {type = "float", name = "Light", min = 0, max = 1, default = 0.5},
		[2] = {type = "float", name = "Grain Size", min = 0, max = 1, default = 0.3},
		[3] = {type = "bool", name = "HQ", default = false},
		[4] = {type = "label", name = "Advanced"},
		[5] = {type = "float", name = "Variability", min = 0, max = 1, default = 0.1},
		[6] = {type = "float", name = "Diffusion", min = 0, max = 1, default = 0.5},
		[7] = {type = "int", name = "Range", min = 3, max = 15, default = 3, step = 2},
	},
	output = {
		[0] = {cs = "Y"}
	},
}
