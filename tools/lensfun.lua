--[[
  Copyright (C) 2011-2019 G. Bajlekov

    Ivy is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Ivy is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]

--[[
    Lens profile data obtained from the lensfun project

		Website: http://lensfun.sourceforge.net/
		Sourceforge: http://sourceforge.net/projects/lensfun/

    The lens database is licensed under the Creative Commons Attribution-Share
    Alike 3.0 license. You can read it here:
    http://creativecommons.org/licenses/by-sa/
--]]

local data = {
	["OLYMPUS M.12mm F2.0"] = {
		distortion = {
			[12] = {0.0, -0.028892, 0.0},
		},
		tca = {
			[12] = {0.0000301, 0.0, 1.0003354, 0.0000561, 0.0, 0.9999414},
		},
	},

	["OLYMPUS M.17mm F1.8"] = {
		distortion = {
			[17] = {0.01989, -0.09761, 0.07461},
		},
		tca = {
			[17] = {-0.0000767, 0.0, 1.0002674, 0.0001410, 0.0, 0.9997845},
		},
	},

	["OLYMPUS M.25mm F1.8"] = {
		distortion = {
			[25] = {0.00454, -0.0141, 0.00283},
		},
		tca = {
			[25] = {0.0, 0.0, 1.0003, 0.0, 0.0, 1.0001}
		},
	},

	["OLYMPUS M.45mm F1.8"] = {
		distortion = {
			[45] = {0.00149954, -0.0023693, 0.00382496},
		},
		tca = {
			[45] = {-0.0000484, 0.0, 1.0001937, 0.0000056, 0.0, 0.9999340}
		},
	},

	["LUMIX G VARIO 12-32/F3.5-5.6"] = {
		distortion = {
			[12] = {0.02222, -0.06354, -0.05077},
			[14] = {0.02389, -0.07355, 0.00922},
			[20] = {0, -0.0088, 0},
			[32] = {0, 0.00353, 0},
		},
		tca = {
			[12] = {-0.0000213, 0.0, 1.0002074, -0.0000183, 0.0, 1.0002135},
			[14] = {0.0000115, 0.0, 1.0001642, 0.0000508, 0.0, 1.0001012},
			[20] = {-0.0000057, 0.0, 1.0001348, -0.0000052, 0.0, 1.0001246},
			[32] = {-0.0000680, 0.0, 1.0001404, -0.0000581, 0.0, 1.0001761},
		},
	},

	["LUMIX G VARIO 35-100/F4.0-5.6"] = {
		distortion = {
			[35] = {0.00663258, -0.0185251, 0.0134508},
			[40] = {0.00258479, -0.00661156, 0.00697864},
			[45] = {0.000553098, 0.00439218, -0.00355882},
			[50] = {0.000346598, 0.00614855, -0.00173778},
			[62] = {-0.000115581, 0.00511291, 0.00988016},
			[78] = {-0.0104497, 0.039446, -0.0251468},
			[100] = {-0.0131383, 0.0562571, -0.0528326},
		},
		tca = {
			[35] = {0.0, 0.0, 1.0001700, 0.0, 0.0, 1.0003000},
			[40] = {0.0, 0.0, 1.0000925, 0.0, 0.0, 1.0002249},
			[45] = {0.0, 0.0, 1.0000558, 0.0, 0.0, 1.0001441},
			[50] = {0.0, 0.0, 1.0000459, 0.0, 0.0, 1.0001676},
			[62] = {0.0, 0.0, 0.9999844, 0.0, 0.0, 1.0000683},
			[78] = {0.0, 0.0, 0.9999536, 0.0, 0.0, 0.9999292},
			[100] = {0.0, 0.0, 0.9999000, 0.0, 0.0, 0.9996000},
		},
	},

	["DSC-RX100M3"] = {
		distortion = {
			[ 8.8] = {0.02266, -0.09581, 0.00190},
			[10.9] = {0.02376, -0.09457, 0.03217},
			[13.0] = {0.02326, -0.08674, 0.04569},
			[14.7] = {0.02340, -0.08395, 0.04970},
			[16.6] = {0.02045, -0.06253, 0.02684},
			[20.0] = {0.02295, -0.06814, 0.05127},
			[25.7] = {0.02377, -0.06078, 0.04156},
		},
		tca = {
			[ 8.8] = {0.0001786, 0.0, 1.0000881, -0.0001087, 0.0, 1.0003934},
			[10.9] = {0.0000887, 0.0, 1.0001670, -0.0000723, 0.0, 1.0003152},
			[13.0] = {0.0000518, 0.0, 1.0002194, -0.0000203, 0.0, 1.0001770},
			[14.7] = {0.0000185, 0.0, 1.0002369, -0.0000000, 0.0, 1.0001315},
			[16.6] = {0.0000075, 0.0, 1.0002936, -0.0000085, 0.0, 1.0000657},
			[20.0] = {-0.0000081, 0.0, 1.0003041, 0.0000035, 0.0, 1.0000616},
			[25.7] = {-0.0000121, 0.0, 1.0002604, 0.0000035, 0.0, 1.0000797},
		},
	},

	--Olympus Zuiko Digital ED 14-42mm f/3.5-5.6
	["OLYMPUS 14-42mm Lens"] = {
		distortion = {
			[14] = {0.0100665, -0.0270472, 0.0022372},
			[18] = {-0.00368686, 0.00286171, -0.0102343},
			[25] = {-1.55769e-05, -2.09253e-05, -0.00318557},
			[35] = {-0.00265046, 0.00843281, -0.00647169},
			[42] = {-0.00342208, 0.0114471, -0.0105329},
		},
		tca = {
			[14] = {-0.0000061, 0.0, 1.0003376, -0.0000092, 0.0, 1.0000329},
			[18] = {-0.0001031, 0.0, 1.0003988, 0.0000126, 0.0, 0.9999971},
			[25] = {-0.0001150, 0.0, 1.0003942, 0.0000327, 0.0, 0.9998980},
			[35] = {-0.0000998, 0.0, 1.0003497, 0.0000562, 0.0, 0.9997683},
			[42] = {-0.0000307, 0.0, 1.0001997, 0.0000116, 0.0, 0.9997666},
		},
	},

	--Olympus Zuiko Digital 35mm f/3.5 Macro
	["OLYMPUS 35mm Lens"] = {
		distortion = {
			[35] = {-0.00226197, 0.00228625, -0.00756547},
		},
		tca = {
			[35] = {-0.0000953, 0.0, 1.0002105, -0.0000137, 0.0, 01.0000230},
		},
	},

	--Olympus Zuiko Digital ED 40-150mm f/4.0-5.6
	["OLYMPUS 40-150mm Lens"] = {
		distortion = {
			[40] = {-0.0069552, 0.0128954, -0.0201501},
			[50] = {-0.00328196, 0.00547778, -0.00507713},
			[73] = {0.00269235, -0.00470212, 0.00974549},
			[98] = {-0.00377975, 0.0155413, -0.00903773},
			[150] = {-0.000293389, 0.00701827, -0.00528205},
		},
		tca = {
			[40] = {-0.0000434, 0.0, 1.0004182, 0.0000176, 0.0, 0.9998313},
			[50] = {0.0000574, 0.0, 1.0002451, -0.0000307, 0.0, 0.9998156},
			[73] = {0.0000138, 0.0, 1.0001119, -0.0001086, 0.0, 0.9997898},
			[102] = {0.0000541, 0.0, 0.9998625, -0.0000497, 0.0, 0.9997776},
			[150] = {0.0000230, 0.0, 0.9997236, -0.0000526, 0.0, 0.9999016},
		},
	},

	["SIGMA 56mm F1.4 DC DN | C 018"] = {
		distortion = {
			[56] = {-0.008811, 0.043041, -0.046179}
		},
	},
}


local function interpolate(data, fl)
	local below, above = 0, math.huge
	local min, max = math.huge, 0
	for k, v in pairs(data) do
		if k < min then min = k end
		if k > max then max = k end

		if k < fl then
			if (fl - k) < (fl - below) then below = k end
		elseif k > fl then
			if (k - fl) < (above - fl) then above = k end
		end
	end

	if fl <= min then return data[min] end
	if fl >= max then return data[max] end

	assert(below > 0)
	assert(above < math.huge)

	local o = {}
	local factor = (fl - below) / (above - below)
	for k, v in ipairs(data[below]) do
		o[k] = data[below][k] + factor * (data[above][k] - data[below][k])
	end
	return o
end

return function(lens, fl)
	local A, B, C, BR, CR, VR, BB, CB, VB = 0, 0, 0, 0, 0, 1, 0, 0, 1

	if not lens then return A, B, C, BR, CR, VR, BB, CB, VB end

	fl = tonumber(fl)
	assert(type(lens) == "string")
	lens = lens:gsub("%c*$", "") -- remove embedded zeros

	if data[lens] then
		if data[lens].distortion then
			if data[lens].distortion[fl] then
				A, B, C = unpack(data[lens].distortion[fl])
			else
				A, B, C = unpack(interpolate(data[lens].distortion, fl))
			end
		end

		if data[lens].tca then
			if data[lens].tca[fl] then
				BR, CR, VR, BB, CB, VB = unpack(data[lens].tca[fl])
			else
				BR, CR, VR, BB, CB, VB = unpack(interpolate(data[lens].tca, fl))
			end
		end
	end

	return A, B, C, BR, CR, VR, BB, CB, VB
end
