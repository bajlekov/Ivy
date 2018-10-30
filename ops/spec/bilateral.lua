return {
	name = "Bilateral",
	procName = "bilateral",
	input = {
		[0] = {cs = "LAB"},
		[1] = {cs = "Y"},
		[2] = {cs = "Y"},
	},
	param = {
		[1] = {type = "float", name = "Distance", min = 0, max = 1, default = 0},
		[2] = {type = "float", name = "Similarity", min = 0, max = 1, default = 0},
	},
	output = {
		[0] = {cs = "LAB"}
	},
}
