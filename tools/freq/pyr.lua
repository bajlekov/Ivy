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

local ffi = require "ffi"

local pyramid = {}

local threadNum
local threadMax
local sync

function pyramid.init(n, m, s)
	threadNum = n
	threadMax = m
	sync = s
end

local function round(x)
	return math.floor(x+0.5)
end

local a = 0.4
local k = ffi.new("double[5]", 1/4-a/2, 1/4, a, 1/4, 1/4-a/2)

function pyramid.down(h, t, l)
	local step = h.y/2/threadMax
	local y0 = round(step*threadNum)*2
	local y1 = round(step*(threadNum+1))*2

	local f = 1/(k[2] + k[3] + k[4]) -- special case for x[0]
	for z = 0, h.z-1 do
		for y = y0, y1-1 do
			local x = 0
			local v = 0
			v = v + h:get(x+0, y, z)*k[2]
			v = v + h:get(x+1, y, z)*k[3]
			v = v + h:get(x+2, y, z)*k[4]
			t:set(x, y, z, v*f)
		end
	end

	if h.x%2==0 then -- special case for x[max]
		local f = 1/(k[0] + k[1] + k[2] + k[3])
		for z = 0, h.z-1 do
			for y = y0, y1-1 do
				local x = h.x-2 -- set x[max-1]
				local v = 0
				v = v + h:get(x-2, y, z)*k[0]
				v = v + h:get(x-1, y, z)*k[1]
				v = v + h:get(x+0, y, z)*k[2]
				v = v + h:get(x+1, y, z)*k[3]
				t:set(x, y, z, v*f)
			end
		end
	else
		local f = 1/(k[0] + k[1] + k[2])
		for z = 0, h.z-1 do
			for y = y0, y1-1 do
				local x = h.x-1 -- set x[max]
				local v = 0
				v = v + h:get(x-2, y, z)*k[0]
				v = v + h:get(x-1, y, z)*k[1]
				v = v + h:get(x+0, y, z)*k[2]
				t:set(x, y, z, v*f)
			end
		end
	end

	for z = 0, h.z-1 do
		for y = y0, y1-1 do
			for x = 2, h.x-3, 2 do
				local v = 0
				v = v + h:get(x-2, y, z)*k[0]
				v = v + h:get(x-1, y, z)*k[1]
				v = v + h:get(x+0, y, z)*k[2]
				v = v + h:get(x+1, y, z)*k[3]
				v = v + h:get(x+2, y, z)*k[4]
				t:set(x, y, z, v)
			end
		end
	end
	sync()

	if threadNum==0 then
		local f = 1/(k[2] + k[3] + k[4]) -- special case for y[0]
		for z = 0, h.z-1 do
			local y = y0
			for x = 0, h.x-1, 2 do
				local v = 0
				v = v + t:get(x, y+0, z)*k[2]
				v = v + t:get(x, y+1, z)*k[3]
				v = v + t:get(x, y+2, z)*k[4]
				l:set(x/2, y/2, z, v*f)
			end
		end
		y0 = 2
	end

	if threadNum==threadMax-1 then
		if h.y%2==0 then -- special case for y[max]
			local f = 1/(k[0] + k[1] + k[2] + k[3])
			for z = 0, h.z-1 do
				local y = h.y-2  -- set y[max-1]
				for x = 0, h.x-1, 2 do
					local v = 0
					v = v + t:get(x, y-2, z)*k[0]
					v = v + t:get(x, y-1, z)*k[1]
					v = v + t:get(x, y+0, z)*k[2]
					v = v + t:get(x, y+1, z)*k[3]
					l:set(x/2, y/2, z, v*f)
				end
			end
		else
			local f = 1/(k[0] + k[1] + k[2])
			for z = 0, h.z-1 do
				local y = h.y-1  -- set y[max]
				for x = 0, h.x-1, 2 do
					local v = 0
					v = v + t:get(x, y-2, z)*k[0]
					v = v + t:get(x, y-1, z)*k[1]
					v = v + t:get(x, y+0, z)*k[2]
					l:set(x/2, y/2, z, v*f)
				end
			end
		end
		y1 = h.y-2
	end

	for z = 0, h.z-1 do
		for y = y0, y1-1, 2 do
			for x = 0, h.x-1, 2 do
				local v = 0
				v = v + t:get(x, y-2, z)*k[0]
				v = v + t:get(x, y-1, z)*k[1]
				v = v + t:get(x, y+0, z)*k[2]
				v = v + t:get(x, y+1, z)*k[3]
				v = v + t:get(x, y+2, z)*k[4]
				l:set(x/2, y/2, z, v)
			end
		end
	end
	sync()
end

function pyramid.up(l, t, h, f1, f2, i)
	f1 = f1 or 0 --original value of h multiplication factor
	f2 = f2 or 1 --upscaled value of l multiplication factor
	i = i or h 	 -- override original value buffer
	local step = h.y/2/threadMax
	local y0 = round(step*threadNum)*2
	local y1 = round(step*(threadNum+1))*2

	local f = 1/(k[2] + k[4])
	for z = 0, h.z-1 do
		for y = y0, y1-1, 2 do
			local x = 0
			local v1, v2, v3
			do
				local x = x/2
				local y = y/2
				v2 = l:get(x+0, y, z)
				v3 = l:get(x+1, y, z)
			end
			local v = 0
			v = v + v2*k[2]
			v = v + v3*k[4]
			t:set(x, y, z, v*f)
			local v = 0
			v = v + v2*k[1]
			v = v + v3*k[3]
			t:set(x+1, y, z, v*2)
		end
	end

	-- special case for x[max]
	if h.x%2==0 then
		local f = 1/(k[2] + k[4])
		for z = 0, h.z-1 do
			for y = y0, y1-1, 2 do
				local x = h.x-2
				local v1, v2, v3
				do
					local x = x/2
					local y = y/2
					v2 = l:get(x+0, y, z)
					v3 = l:get(x+1, y, z)
				end
				local v = 0
				v = v + v2*k[2]
				v = v + v3*k[4]
				t:set(x, y, z, v*f)
				local v = 0
				v = v + v2*k[1]
				v = v + v3*k[3]
				t:set(x+1, y, z, v*2)
			end
		end
	else
		local f = 1/(k[2] + k[4])
		for z = 0, h.z-1 do
			for y = y0, y1-1, 2 do
				local x = h.x-1
				local v1, v2, v3
				do
					local x = x/2
					local y = y/2
					v2 = l:get(x+0, y, z)
					v3 = l:get(x+1, y, z)
				end
				local v = 0
				v = v + v2*k[2]
				v = v + v3*k[4]
				t:set(x, y, z, v*f)
			end
		end
	end

	for z = 0, h.z-1 do
		for y = y0, y1-1, 2 do
			for x = 2, h.x-3, 2 do
				local v1, v2, v3
				do
					local x = x/2
					local y = y/2
					v1 = l:get(x-1, y, z)
					v2 = l:get(x+0, y, z)
					v3 = l:get(x+1, y, z)
				end
				local v = 0
				v = v + v1*k[0]
				v = v + v2*k[2]
				v = v + v3*k[4]
				t:set(x, y, z, v*2)
				local v = 0
				v = v + v2*k[1]
				v = v + v3*k[3]
				t:set(x+1, y, z, v*2)
			end
		end
	end
	sync()

	if threadNum==0 then
		local f = 1/(k[2] + k[4])
		for z = 0, h.z-1 do
			local y = 0
			for x = 0, h.x-1 do
				local v1, v2, v3
				v2 = t:get(x, y+0, z)
				v3 = t:get(x, y+2, z)
				local v = 0
				v = v + v2*k[2]
				v = v + v3*k[4]
				h:set(x, y, z, f1*i:get(x, y, z) + f2*v*f)
				--h:set(x, y, z, v*f) -- TODO: optimize simple pyrUp
				local v = 0
				v = v + v2*k[1]
				v = v + v3*k[3]
				h:set(x, y+1, z, f1*i:get(x, y+1, z) + f2*v*2)
				--h:set(x, y+1, z, v*2) -- TODO: optimize simple pyrUp
			end
		end
		y0 = 2
	end

	if threadNum==threadMax-1 then
		local f = 1/(k[0] + k[2])
		if h.y%2==0 then -- special case for y[max]
			for z = 0, h.z-1 do
				local y = h.y-2  -- set y[max-1]
				for x = 0, h.x-1 do
					local v1, v2, v3
					v1 = t:get(x, y-2, z)
					v2 = t:get(x, y+0, z)
					local v = 0
					v = v + v1*k[0]
					v = v + v2*k[2]
					h:set(x, y, z, f1*i:get(x, y, z) + f2*v*f)
					--h:set(x, y, z, v*2) -- TODO: optimize simple pyrUp
					h:set(x, y+1, z, f1*i:get(x, y+1, z) + f2*v2)
					--h:set(x, y+1, z, v2*2) -- TODO: optimize simple pyrUp
				end
			end
		else
			for z = 0, h.z-1 do
				local y = h.y-1  -- set y[max]
				for x = 0, h.x-1 do
					local v1, v2, v3
					v1 = t:get(x, y-2, z)
					v2 = t:get(x, y+0, z)
					local v = 0
					v = v + v1*k[0]
					v = v + v2*k[2]
					h:set(x, y, z, f1*i:get(x, y, z) + f2*v*f)
					--h:set(x, y, z, v*2) -- TODO: optimize simple pyrUp
				end
			end
		end
		y1 = h.y-2
	end

	for z = 0, h.z-1 do
		for y = y0, y1-1, 2 do
			for x = 0, h.x-1 do
				local v1, v2, v3
				v1 = t:get(x, y-2, z)
				v2 = t:get(x, y+0, z)
				v3 = t:get(x, y+2, z)
				local v = 0
				v = v + v1*k[0]
				v = v + v2*k[2]
				v = v + v3*k[4]
				h:set(x, y, z, f1*i:get(x, y, z) + f2*v*2)
				--h:set(x, y, z, v*2) -- TODO: optimize simple pyrUp
				local v = 0
				v = v + v2*k[1]
				v = v + v3*k[3]
				h:set(x, y+1, z, f1*i:get(x, y+1, z) + f2*v*2)
				--h:set(x, y+1, z, v*2) -- TODO: optimize simple pyrUp
			end
		end
	end
	sync()
end


function pyramid.down1(h, t, l)
	local step = h.y/2/threadMax
	local y0 = round(step*threadNum)*2
	local y1 = round(step*(threadNum+1))*2

	local f = 1/(k[2] + k[3] + k[4]) -- special case for x[0]
	for z = 0, 0 do
		for y = y0, y1-1 do
			local x = 0
			local v = 0
			v = v + h:get(x+0, y, z)*k[2]
			v = v + h:get(x+1, y, z)*k[3]
			v = v + h:get(x+2, y, z)*k[4]
			t:set(x, y, z, v*f)
		end
	end

	if h.x%2==0 then -- special case for x[max]
		local f = 1/(k[0] + k[1] + k[2] + k[3])
		for z = 0, 0 do
			for y = y0, y1-1 do
				local x = h.x-2 -- set x[max-1]
				local v = 0
				v = v + h:get(x-2, y, z)*k[0]
				v = v + h:get(x-1, y, z)*k[1]
				v = v + h:get(x+0, y, z)*k[2]
				v = v + h:get(x+1, y, z)*k[3]
				t:set(x, y, z, v*f)
			end
		end
	else
		local f = 1/(k[0] + k[1] + k[2])
		for z = 0, 0 do
			for y = y0, y1-1 do
				local x = h.x-1 -- set x[max]
				local v = 0
				v = v + h:get(x-2, y, z)*k[0]
				v = v + h:get(x-1, y, z)*k[1]
				v = v + h:get(x+0, y, z)*k[2]
				t:set(x, y, z, v*f)
			end
		end
	end

	for z = 0, 0 do
		for y = y0, y1-1 do
			for x = 2, h.x-3, 2 do
				local v = 0
				v = v + h:get(x-2, y, z)*k[0]
				v = v + h:get(x-1, y, z)*k[1]
				v = v + h:get(x+0, y, z)*k[2]
				v = v + h:get(x+1, y, z)*k[3]
				v = v + h:get(x+2, y, z)*k[4]
				t:set(x, y, z, v)
			end
		end
	end
	sync()

	if threadNum==0 then
		local f = 1/(k[2] + k[3] + k[4]) -- special case for y[0]
		for z = 0, 0 do
			local y = y0
			for x = 0, h.x-1, 2 do
				local v = 0
				v = v + t:get(x, y+0, z)*k[2]
				v = v + t:get(x, y+1, z)*k[3]
				v = v + t:get(x, y+2, z)*k[4]
				l:set(x/2, y/2, z, v*f)
			end
		end
		y0 = 2
	end

	if threadNum==threadMax-1 then
		if h.y%2==0 then -- special case for y[max]
			local f = 1/(k[0] + k[1] + k[2] + k[3])
			for z = 0, 0 do
				local y = h.y-2  -- set y[max-1]
				for x = 0, h.x-1, 2 do
					local v = 0
					v = v + t:get(x, y-2, z)*k[0]
					v = v + t:get(x, y-1, z)*k[1]
					v = v + t:get(x, y+0, z)*k[2]
					v = v + t:get(x, y+1, z)*k[3]
					l:set(x/2, y/2, z, v*f)
				end
			end
		else
			local f = 1/(k[0] + k[1] + k[2])
			for z = 0, 0 do
				local y = h.y-1  -- set y[max]
				for x = 0, h.x-1, 2 do
					local v = 0
					v = v + t:get(x, y-2, z)*k[0]
					v = v + t:get(x, y-1, z)*k[1]
					v = v + t:get(x, y+0, z)*k[2]
					l:set(x/2, y/2, z, v*f)
				end
			end
		end
		y1 = h.y-2
	end

	for z = 0, 0 do
		for y = y0, y1-1, 2 do
			for x = 0, h.x-1, 2 do
				local v = 0
				v = v + t:get(x, y-2, z)*k[0]
				v = v + t:get(x, y-1, z)*k[1]
				v = v + t:get(x, y+0, z)*k[2]
				v = v + t:get(x, y+1, z)*k[3]
				v = v + t:get(x, y+2, z)*k[4]
				l:set(x/2, y/2, z, v)
			end
		end
	end
	sync()
end

function pyramid.up1(l, t, h, f1, f2, i)
	f1 = f1 or 0 --original value of h multiplication factor
	f2 = f2 or 1 --upscaled value of l multiplication factor
	i = i or h 	 -- override original value buffer
	local step = h.y/2/threadMax
	local y0 = round(step*threadNum)*2
	local y1 = round(step*(threadNum+1))*2

	local f = 1/(k[2] + k[4])
	for z = 0, 0 do
		for y = y0, y1-1, 2 do
			local x = 0
			local v1, v2, v3
			do
				local x = x/2
				local y = y/2
				v2 = l:get(x+0, y, z)
				v3 = l:get(x+1, y, z)
			end
			local v = 0
			v = v + v2*k[2]
			v = v + v3*k[4]
			t:set(x, y, z, v*f)
			local v = 0
			v = v + v2*k[1]
			v = v + v3*k[3]
			t:set(x+1, y, z, v*2)
		end
	end

	-- special case for x[max]
	if h.x%2==0 then
		local f = 1/(k[2] + k[4])
		for z = 0, 0 do
			for y = y0, y1-1, 2 do
				local x = h.x-2
				local v1, v2, v3
				do
					local x = x/2
					local y = y/2
					v2 = l:get(x+0, y, z)
					v3 = l:get(x+1, y, z)
				end
				local v = 0
				v = v + v2*k[2]
				v = v + v3*k[4]
				t:set(x, y, z, v*f)
				local v = 0
				v = v + v2*k[1]
				v = v + v3*k[3]
				t:set(x+1, y, z, v*2)
			end
		end
	else
		local f = 1/(k[2] + k[4])
		for z = 0, 0 do
			for y = y0, y1-1, 2 do
				local x = h.x-1
				local v1, v2, v3
				do
					local x = x/2
					local y = y/2
					v2 = l:get(x+0, y, z)
					v3 = l:get(x+1, y, z)
				end
				local v = 0
				v = v + v2*k[2]
				v = v + v3*k[4]
				t:set(x, y, z, v*f)
			end
		end
	end

	for z = 0, 0 do
		for y = y0, y1-1, 2 do
			for x = 2, h.x-3, 2 do
				local v1, v2, v3
				do
					local x = x/2
					local y = y/2
					v1 = l:get(x-1, y, z)
					v2 = l:get(x+0, y, z)
					v3 = l:get(x+1, y, z)
				end
				local v = 0
				v = v + v1*k[0]
				v = v + v2*k[2]
				v = v + v3*k[4]
				t:set(x, y, z, v*2)
				local v = 0
				v = v + v2*k[1]
				v = v + v3*k[3]
				t:set(x+1, y, z, v*2)
			end
		end
	end
	sync()

	if threadNum==0 then
		local f = 1/(k[2] + k[4])
		for z = 0, 0 do
			local y = 0
			for x = 0, h.x-1 do
				local v1, v2, v3
				v2 = t:get(x, y+0, z)
				v3 = t:get(x, y+2, z)
				local v = 0
				v = v + v2*k[2]
				v = v + v3*k[4]
				h:set(x, y, z, f1*i:get(x, y, z) + f2*v*f)
				--h:set(x, y, z, v*f) -- TODO: optimize simple pyrUp
				local v = 0
				v = v + v2*k[1]
				v = v + v3*k[3]
				h:set(x, y+1, z, f1*i:get(x, y+1, z) + f2*v*2)
				--h:set(x, y+1, z, v*2) -- TODO: optimize simple pyrUp
			end
		end
		y0 = 2
	end

	if threadNum==threadMax-1 then
		local f = 1/(k[0] + k[2])
		if h.y%2==0 then -- special case for y[max]
			for z = 0, 0 do
				local y = h.y-2  -- set y[max-1]
				for x = 0, h.x-1 do
					local v1, v2, v3
					v1 = t:get(x, y-2, z)
					v2 = t:get(x, y+0, z)
					local v = 0
					v = v + v1*k[0]
					v = v + v2*k[2]
					h:set(x, y, z, f1*i:get(x, y, z) + f2*v*f)
					--h:set(x, y, z, v*2) -- TODO: optimize simple pyrUp
					h:set(x, y+1, z, f1*i:get(x, y+1, z) + f2*v2)
					--h:set(x, y+1, z, v2*2) -- TODO: optimize simple pyrUp
				end
			end
		else
			for z = 0, 0 do
				local y = h.y-1  -- set y[max]
				for x = 0, h.x-1 do
					local v1, v2, v3
					v1 = t:get(x, y-2, z)
					v2 = t:get(x, y+0, z)
					local v = 0
					v = v + v1*k[0]
					v = v + v2*k[2]
					h:set(x, y, z, f1*i:get(x, y, z) + f2*v*f)
					--h:set(x, y, z, v*2) -- TODO: optimize simple pyrUp
				end
			end
		end
		y1 = h.y-2
	end

	for z = 0, 0 do
		for y = y0, y1-1, 2 do
			for x = 0, h.x-1 do
				local v1, v2, v3
				v1 = t:get(x, y-2, z)
				v2 = t:get(x, y+0, z)
				v3 = t:get(x, y+2, z)
				local v = 0
				v = v + v1*k[0]
				v = v + v2*k[2]
				v = v + v3*k[4]
				h:set(x, y, z, f1*i:get(x, y, z) + f2*v*2)
				--h:set(x, y, z, v*2) -- TODO: optimize simple pyrUp
				local v = 0
				v = v + v2*k[1]
				v = v + v3*k[3]
				h:set(x, y+1, z, f1*i:get(x, y+1, z) + f2*v*2)
				--h:set(x, y+1, z, v*2) -- TODO: optimize simple pyrUp
			end
		end
	end
	sync()
end

pyramid.laplacian = {}

function pyramid.laplacian.down(i, t, g, l)
	-- input, temp, gaussian, laplacian
	pyramid.down(i, t, g)
	pyramid.up(g, t, l, 1, -1, i)
end

function pyramid.laplacian.up(g, l, t, o, lf, gf)
	-- gaussian, laplacian, temp, output
	lf = lf or 1
	gf = gf or 1
	pyramid.up(g, t, o, lf, gf, l)
end

return pyramid
