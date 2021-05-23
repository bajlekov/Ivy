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

local function size(t)
	local c = 0
	for _, _ in pairs(t) do
		c = c + 1
	end
	return c
end

local traced

function debug.outline(xmin, ymin, xmax, ymax)
	love.graphics.setColor({1, 0, 0, 1})
	love.graphics.rectangle("line", xmin + 0.5, ymin + 0.5, xmax - xmin - 1, ymax - ymin - 1)
	love.graphics.present()
	love.timer.sleep(0.5)
end

function debug.see(f, indent, idx)
	if type(idx) ~= "string" then idx = tostring(idx) end
	if indent == nil then
		print("====================")
		indent = ""
		idx = ".."
		traced = {}
	end
	--if #indent > 20 then return end
	if type(f) ~= "table" then
		if type(f) == "function" then
			print(indent.."["..idx.."]", "function", debug.getinfo(f).short_src.." @ "..debug.getinfo(f).linedefined )
		else
			print(indent.."["..idx.."]", type(f)..":", f)
		end
		return
	end

	if traced[f] then
		print(indent.."["..idx.."]", "duplicate "..tostring(f), "["..size(f).."]")
		return
	elseif size(f) == 0 then
		print(indent.."["..idx.."]", "empty "..tostring(f), "["..size(f).."]")
	else
		print(indent.."["..idx.."]", tostring(f), "["..size(f).."]")
	end

	traced[f] = true

	for k, v in pairs(f) do
		debug.see(v, indent.."  ", k)
	end
end

function debug.list(l)
	l = l or 2
	print("====================")
	print("Local values ["..l.."]:")
	print("--------------------")
	local i = 1
	while true do
		local name, value = debug.getlocal(l, i)
		if not name then break end
		print(("%i: %s\t%s"):format(i, name, value))
		i = i + 1
	end
	print("====================")
	print("Upvalues ["..l.."]:")
	print("--------------------")
	local i = 1
	local func = debug.getinfo(l).func
	while true do
		local name, value = debug.getupvalue(func, i)
		if not name then break end
		print(("%i: %s\t%s"):format(i, name, value))
		i = i + 1
	end
	print("====================")
end

local timer = require "love.timer"

do
	local t1, t2 = 0, 0
	local m1, m2 = 0, 0

	function debug.tic()
		t1 = timer.getTime()
		m1 = collectgarbage("count")
	end

	function debug.toc(label)
		t2 = timer.getTime()
		m2 = collectgarbage("count")
		print(label..":\t{time: "..string.format("%.3fms", (t2 - t1) * 1000).." / memory: "..string.format("%.3fKB", m2 - m1).."}" )
		t1 = t2
		m1 = m2
	end
end
