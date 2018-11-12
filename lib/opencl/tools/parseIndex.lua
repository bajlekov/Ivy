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

-- use $buf[x, y, z] notation in openCL to enable broadcasting behavior and handling of different strides
local function parseIndex(source, buffers)

	-- strip comments
	source = source:gsub("/%*(.-)%*/", "/* comment */")
	source = source:gsub("//(.-)\n", "// comment \r\n") -- TODO: check if this works on linux



	local function parse3(b, x, y, z)
		assert(buffers[b], "No buffer '"..b.."' found in provided buffers list.")
		local sx = buffers[b].x == 1 and 0 or buffers[b].sx
		local sy = buffers[b].y == 1 and 0 or buffers[b].sy
		local sz = buffers[b].z == 1 and 0 or buffers[b].sz
		local str = ("(%s[((%s)*%i)+((%s)*%i)+((%s)*%i)])"):format(b, x, sx, y, sy, z, sz)
		return str
	end

	-- FIXME: assignment to an out of bounds element gets turned into assignment to the edge of the original
	local function parse3extend(b, x, y, z) -- extend boundaries on out of bounds indexing
		assert(buffers[b], "No buffer '"..b.."' found in provided buffers list.")
		local sx = buffers[b].x == 1 and 0 or buffers[b].sx
		local sy = buffers[b].y == 1 and 0 or buffers[b].sy
		local sz = buffers[b].z == 1 and 0 or buffers[b].sz

		local bx = ("clamp((int)(%s), (int)0, (int)%i)"):format(x, buffers[b].x - 1)
		local by = ("clamp((int)(%s), (int)0, (int)%i)"):format(y, buffers[b].y - 1)
		local bz = ("clamp((int)(%s), (int)0, (int)%i)"):format(z, buffers[b].z - 1)

		local str = ("(%s[((%s)*%i)+((%s)*%i)+((%s)*%i)])"):format(b, bx, sx, by, sy, bz, sz)
		return str
	end

	-- FIXME: can only be used as a RHS expression for indexing, not as a LHS expression for assignment
	local function parse3zero(b, x, y, z) -- return 0 on out of bounds indexing
		assert(buffers[b], "No buffer '"..b.."' found in provided buffers list.")
		local sx = buffers[b].x == 1 and 0 or buffers[b].sx
		local sy = buffers[b].y == 1 and 0 or buffers[b].sy
		local sz = buffers[b].z == 1 and 0 or buffers[b].sz

		return ("(((%s)<0|(%s)<0|(%s)<0|(%s)>=%i|(%s)>=%i|(%s)>=%i)? 0 : %s[((%s)*%i)+((%s)*%i)+((%s)*%i)])"):format(x, y, z, x, buffers[b].x, y, buffers[b].y, z, buffers[b].z, b, x, sx, y, sy, z, sz)
	end

	local function parse2extend_load(b, x, y) -- see notes for parse3extend
		assert(buffers[b], "No buffer '"..b.."' found in provided buffers list.")
		local sx = buffers[b].x == 1 and 0 or buffers[b].sx
		local sy = buffers[b].y == 1 and 0 or buffers[b].sy
		local sz = buffers[b].z == 1 and 0 or buffers[b].sz

		local bx = ("clamp((int)(%s), (int)0, (int)%i)"):format(x, buffers[b].x - 1)
		local by = ("clamp((int)(%s), (int)0, (int)%i)"):format(y, buffers[b].y - 1)

		if buffers[b].z==3 then
			return ("( (float3)(%s[((%s)*%i)+((%s)*%i)], %s[((%s)*%i)+((%s)*%i)+1*%i], %s[((%s)*%i)+((%s)*%i)+2*%i]) )"):format(b, bx, sx, by, sy, b, bx, sx, by, sy, sz, b, bx, sx, by, sy, sz)
		elseif buffers[b].z==1 then
			return ("( %s[((%s)*%i)+((%s)*%i)] )"):format(b, bx, sx, by, sy)
		else
			error("Buffer '"..b.."' has an unsupported number of channels: "..b.z)
		end
	end

	local includeCS = false
	local function parse2extend_load_cs(b, x, y, csOut) -- see notes for parse3extend
		assert(buffers[b], "No buffer '"..b.."' found in provided buffers list.")
		local csIn = buffers[b].cs

		local sx = buffers[b].x == 1 and 0 or buffers[b].sx
		local sy = buffers[b].y == 1 and 0 or buffers[b].sy
		local sz = buffers[b].z == 1 and 0 or buffers[b].sz

		local bx = ("clamp((int)(%s), (int)0, (int)%i)"):format(x, buffers[b].x - 1)
		local by = ("clamp((int)(%s), (int)0, (int)%i)"):format(y, buffers[b].y - 1)

		includeCS = true
		local csFunction = csIn.."to"..csOut

		if csIn == "Y" or csIn == "L" then -- only the first
			return ("( %s(%s[((%s)*%i)+((%s)*%i)]) )"):format(csFunction, b, bx, sx, by, sy)
		end

		return ("( %s((float3)(%s[((%s)*%i)+((%s)*%i)], %s[((%s)*%i)+((%s)*%i)+1*%i], %s[((%s)*%i)+((%s)*%i)+2*%i])) )"):format(csFunction, b, bx, sx, by, sy, b, bx, sx, by, sy, sz, b, bx, sx, by, sy, sz)
	end

	-- TODO: properly recognise LHS and RHS statements and handle accordingly (based on "=", ";"...as an expression in "if" structures?)
	local function parse2extend_store(b, x, y, s) -- see notes for parse3extend
		assert(buffers[b], "No buffer '"..b.."' found in provided buffers list.")
		local sx = buffers[b].x == 1 and 0 or buffers[b].sx
		local sy = buffers[b].y == 1 and 0 or buffers[b].sy
		local sz = buffers[b].z == 1 and 0 or buffers[b].sz

		local bx = ("clamp((int)(%s), (int)0, (int)%i)"):format(x, buffers[b].x - 1)
		local by = ("clamp((int)(%s), (int)0, (int)%i)"):format(y, buffers[b].y - 1)

		if buffers[b].z==3 then
			local str = ("float3 __temp_float3__ = (float3)(%s); "):format(s)
			str = str..("%s[((%s)*%i)+((%s)*%i)]      = __temp_float3__.x; "):format(b, bx, sx, by, sy)
			str = str..("%s[((%s)*%i)+((%s)*%i)+1*%i] = __temp_float3__.y; "):format(b, bx, sx, by, sy, sz)
			str = str..("%s[((%s)*%i)+((%s)*%i)+2*%i] = __temp_float3__.z; "):format(b, bx, sx, by, sy, sz)
			return str
		elseif buffers[b].z==1 then
			return ("%s[((%s)*%i)+((%s)*%i)] = (%s); "):format(b, bx, sx, by, sy, s)
		else
			error("Buffer '"..b.."' has an unsupported number of channels: "..b.z)
		end
	end

	local function parse1prop(b, p)
		return ("("..buffers[b][p]..")")
	end

	local function parse1free(e)
		local f = assert(loadstring("return "..e))
		local env = {math = math, string = string, table = table}
		for k, v in pairs(buffers) do
			env[k] = v
		end
		setfenv(f, env)
		return tostring(f())
	end

	-- for now out of bounds handling is strictly extend

	-- FIXME: no brackets or commas inside the index expression
	source = source:gsub("%$([^{}%[%]%.%$%s]*)%.([^{}%[%]%.%$%s]*)%$", parse1prop)
	source = source:gsub("%${([^{}%$]*)}%$", parse1free)

	source = source:gsub("%$([^%[]*)%[([^%],]*),([^%],]*),([^%],]*)%]", parse3extend)
	source = source:gsub("%$([^%[]*)%[([^%],]*),([^%],]*)%]%s*=%s*([^;]*);", parse2extend_store)
	source = source:gsub("%$([^%[]*)%[([^%],]*),([^%],]*)%](%u+)", parse2extend_load_cs)
	source = source:gsub("%$([^%[]*)%[([^%],]*),([^%],]*)%]", parse2extend_load)

	if includeCS then
		return "#include \"cs.cl\"\n\n"..source
	else
		return source
	end
end

return parseIndex
