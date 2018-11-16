--[[
  Copyright (C) 2011-2018 G. Bajlekov

    ImageFloat is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ImageFloat is distributed in the hope that it will be useful,
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
		[12] = {0.0, - 0.028892, 0.0},
	},
	["OLYMPUS M.17mm F1.8"] = {
		[17] = {0.01989, - 0.09761, 0.07461},
	},
	["OLYMPUS M.25mm F1.8"] = {
		[25] = {0.00454, - 0.0141, 0.00283},
	},
	["OLYMPUS M.45mm F1.8"] = {
		[45] = {0.00149954, - 0.0023693, 0.00382496},
	},
	["LUMIX G VARIO 12-32/F3.5-5.6"] = {
		[12] = {0.02222, - 0.06354, - 0.05077},
		[14] = {0.02389, - 0.07355, 0.00922},
		[20] = {0, - 0.0088, 0},
		[32] = {0, 0.00353, 0},
	},
	["LUMIX G VARIO 35-100/F4.0-5.6"] = {
		[35] = {0.00663258, -0.0185251, 0.0134508},
		[40] = {0.00258479, -0.00661156, 0.00697864},
		[45] = {0.000553098, 0.00439218, -0.00355882},
		[50] = {0.000346598, 0.00614855, -0.00173778},
		[62] = {-0.000115581, 0.00511291, 0.00988016},
		[78] = {-0.0104497, 0.039446, -0.0251468},
		[100] = {-0.0131383, 0.0562571, -0.0528326},
	},
	["DSC-RX100M3"] = {
		[ 8.8] = {0.02266, - 0.09581, 0.00190},
		[10.9] = {0.02376, - 0.09457, 0.03217},
		[13.0] = {0.02326, - 0.08674, 0.04569},
		[14.7] = {0.02340, - 0.08395, 0.04970},
		[16.6] = {0.02045, - 0.06253, 0.02684},
		[20.0] = {0.02295, - 0.06814, 0.05127},
		[25.7] = {0.02377, - 0.06078, 0.04156},
	},

	--Olympus Zuiko Digital ED 14-42mm f/3.5-5.6
	["OLYMPUS 14-42mm Lens"] = {
		[14] = {0.0100665, -0.0270472, 0.0022372},
		[18] = {-0.00368686, 0.00286171, -0.0102343},
		[25] = {-1.55769e-05, -2.09253e-05, -0.00318557},
		[35] = {-0.00265046, 0.00843281, -0.00647169},
		[42] = {-0.00342208, 0.0114471, -0.0105329},
	},

	--Olympus Zuiko Digital 35mm f/3.5 Macro
	["OLYMPUS 35mm Lens"] = {
		[35] = {-0.00226197, 0.00228625, -0.00756547},
	},

	--Olympus Zuiko Digital ED 40-150mm f/4.0-5.6
	["OLYMPUS 40-150mm Lens"] = {
		[40] = {-0.0069552, 0.0128954, -0.0201501},
		[50] = {-0.00328196, 0.00547778, -0.00507713},
		[73] = {0.00269235, -0.00470212, 0.00974549},
		[98] = {-0.00377975, 0.0155413, -0.00903773},
		[150] = {-0.000293389, 0.00701827, -0.00528205},
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

	if fl <= min then return data[min][1], data[min][2], data[min][3] end
	if fl >= max then return data[max][1], data[max][2], data[max][3] end

	assert(below > 0)
	assert(above < math.huge)

	local A1, B1, C1 = data[below][1], data[below][2], data[below][3]
	local A2, B2, C2 = data[above][1], data[above][2], data[above][3]

	local factor = (fl - below) / (above - below)

	return A1 + factor * (A2 - A1), B1 + factor * (B2 - B1), C1 + factor * (C2 - C1)
end

return function(lens, fl)
	fl = tonumber(fl)
	assert(type(lens) == "string")
	lens = lens:gsub("%c*$", "") -- remove embedded zeros

	if data[lens] then
		if data[lens][fl] then
			return data[lens][fl][1], data[lens][fl][2], data[lens][fl][3]
		else
			return interpolate(data[lens], fl)
		end
	else
		return 0, 0, 0
	end
end
