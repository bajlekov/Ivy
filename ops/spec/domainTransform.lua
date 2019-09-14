return {
	name = "DT filter",
	procName = "domainTransform",
	input = {
		[0] = {cs = "LAB"},
		[1] = {cs = "Y"},
		[2] = {cs = "Y"},
	},
	param = {
		[1] = {type = "float", name = "Distance", min = 0, max = 100, default = 30},
		[2] = {type = "float", name = "Similarity", min = 0, max = 1, default = 0.2},
	},
	output = {
		[0] = {cs = "LAB"}
	},
}
