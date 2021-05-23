--[[
  Copyright (C) 2011-2021 G. Bajlekov

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

local proc = require "lib.opencl.process.ivy".new()

local source = [[
const G7 = {0.009033, 0.018476, 0.033851, 0.055555, 0.08167, 0.107545, 0.126854, 0.134032, 0.126854, 0.107545, 0.08167, 0.055555, 0.033851, 0.018476, 0.009033}

kernel paintSmart(O, I, P)
	const x = get_global_id(0)
	const y = get_global_id(1)

	var px = P[0] -- brush 
	var py = P[1] -- brush
	var ps = P[4] -- brush size

	var ix = px - ps + x -- image x
	var iy = py - ps + y -- image y

	if ix<0 or ix>=O.x or iy<0 or iy>=O.y then return end -- clamp to image

	var mask = 0.0
	var sw = P[6]*P[7]*0.5
	var sm = P[6] - sw
	var sx = P[9]
	var sy = P[10]

		-- negative values disable smart paint
	if P[6]<0.0 then
		mask = 1.0
	else
		if P[8]<0.5 then
			var i = I[ix, iy]
			var s = I[sx, sy]
			var d = sqrt( (i.x-s.x)^2 + (i.y-s.y)^2 + (i.z-s.z)^2 )
			mask = range(sm, sw, d)
		else
			-- collect 15x15 area around sample
			for j = -7, 7 do
				for k = -7, 7 do
					var i = I[ix+j, iy+k]
					var s = I[sx+j, sy+k]
			var d = sqrt((i.x-s.x)^2 + (i.y-s.y)^2 + (i.z-s.z)^2)
			d = range(sm, sw, d)*G7[j+7]*G7[k+7]
					mask = mask + d
				end
			end
		end
	end

	var d = sqrt( (x-ps)^2 + (y-ps)^2 ) -- distance from center
	var w = P[5]*ps*0.5
	var brush = range(ps - w, w + 1.0, d)

	var f = mask*brush*P[3]
	var o = O[ix, iy]
	o = o + f*(P[2] - o)

	O[ix, iy] = clamp(o, 0.0, 1.0)
end
]]

--[[
	P[0] - x position
	P[1] - y position
	P[2] - brush value
	P[3] - brush flow
	p[4] - brush size
	p[5] - brush fall-off
	p[6] - smart range
	p[7] - smart range fall-off
	p[8] - smart patch
	p[9] - sample x
	p[10] - sample y
--]]

local function execute()
	local O, I, P = proc:getAllBuffers(3)
	local ps = math.ceil(P:get(0, 0, 4)) -- brush size
	proc:executeKernel("paintSmart", {ps*2+1, ps*2+1}, {O, I, P})
end

local function init(d, c, q)
	proc:init(d, c, q)
	proc:loadSourceString(source)
	return execute
end

return init
