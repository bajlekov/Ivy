return {
	name = "DT filter",
	procName = "domainTransform",
	input = {
		[0] = {cs = "XYZ"},
		[1] = {cs = "LAB"},
		[2] = {cs = "Y"},
		[3] = {cs = "Y"},
	},
	param = {
		[1] = {type = "text", left = "Guide Image"},
		[2] = {type = "float", name = "Distance", min = 0, max = 100, default = 30},
		[3] = {type = "float", name = "Similarity", min = 0, max = 1, default = 0.2},
	},
	output = {
		[0] = {cs = "XYZ"}
	},
}
