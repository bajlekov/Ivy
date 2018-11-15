return {
	name = "Split U/D",
	procName = "split_ud",
	input = {
		[1] = {cs = "LRGB", source = "white"},
		[2] = {cs = "LRGB"},
	},
	param = {
		{type = "text", left = "White / Up", right = ""},
		{type = "text", left = "Black / Down", right = ""},
		{type = "float", name = "Position", min = 0, max = 1, default = 0.5},
		{type = "bool", name = "Invert", default = false},
	},
	output = {
		[0] = {cs = "LRGB", size = "input"}
	},
}
