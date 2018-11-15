return {
	name = "Split L/R",
	procName = "split_lr",
	input = {
		[1] = {cs = "LRGB", source = "white"},
		[2] = {cs = "LRGB"},
	},
	param = {
		{type = "text", left = "White / Left", right = ""},
		{type = "text", left = "Black / Right", right = ""},
		{type = "float", name = "Position", min = 0, max = 1, default = 0.5},
		{type = "bool", name = "Invert", default = false},
	},
	output = {
		[0] = {cs = "LRGB", size = "input"}
	},
}
