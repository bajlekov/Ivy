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
		[2] = {type = "float", name = "Distance", min = 0, max = 10, default = 3},
		[3] = {type = "float", name = "Similarity", min = 0, max = 1, default = 0.2},
		[4] = {type = "bool", name = "Smoothen", default = false},
	},
	output = {
		[0] = {cs = "XYZ"}
	},
}
