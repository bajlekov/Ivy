--[[
  Copyright (C) 2011-2020 G. Bajlekov

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

local event = {}

function event.move(node)
	for i = 0, node.elem.n do
		if node.portIn[i] then
			if node.portIn[i].link then
				node.portIn[i].link:updateCurve()
			end
		end
		if node.portOut[i] then
			if node.portOut[i].link then
				node.portOut[i].link:updateCurve()
			end
		end
	end
end

function event.linkConnect(nodeIn, nodeOut)

end

function event.linkDisconnect(nodeIn, nodeOut)

end

return event
