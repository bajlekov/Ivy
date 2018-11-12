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

local style = require("ui.style")

local draw = {}


local function drawCurve(pts, x, y)
	local v = pts[1]
	love.graphics.line(x + 2, y + (1 - v.y) * 146 + 2, x + v.x * 146 + 2, y + (1 - v.y) * 146 + 2)
	for k = 1, #pts - 1 do
		local v = pts[k]
		love.graphics.line(x + v.x * 146 + 2, y + (1 - v.y) * 146 + 2, x + pts[k + 1].x * 146 + 2, y + (1 - pts[k + 1].y) * 146 + 2)
	end
	local v = pts[#pts]
	love.graphics.line(x + 146 + 2, y + (1 - v.y) * 146 + 2, x + v.x * 146 + 2, y + (1 - v.y) * 146 + 2)
end

function draw.curve(graph, x, y, w, h)
	love.graphics.setColor(style.gray3)

	love.graphics.rectangle("fill", x, y, w, h, 3, 3)

	if graph.background then
		love.graphics.setColor(0.8, 0.8, 0.8, 1)
		love.graphics.draw(graph.background, x+2, y+2, 0, 146/512, 146/512)
	end

	love.graphics.setLineWidth(0.7)
	love.graphics.setColor(style.gray5)
	love.graphics.rectangle("line", x + 2.5, y + 2.5, w - 5, h - 5)

	love.graphics.line(x + 2.5 + math.round((w - 5) * 0.25), y + h - 5, x + 2.5 + math.round((w - 5) * 0.25), y + 5)
	love.graphics.line(x + 2.5 + math.round((w - 5) * 0.50), y + h - 5, x + 2.5 + math.round((w - 5) * 0.50), y + 5)
	love.graphics.line(x + 2.5 + math.round((w - 5) * 0.75), y + h - 5, x + 2.5 + math.round((w - 5) * 0.75), y + 5)

	love.graphics.line(x + 5, y + 2.5 + math.round((h - 5) * 0.25), x + w - 5, y + 2.5 + math.round((h - 5) * 0.25))
	love.graphics.line(x + 5, y + 2.5 + math.round((h - 5) * 0.50), x + w - 5, y + 2.5 + math.round((h - 5) * 0.50))
	love.graphics.line(x + 5, y + 2.5 + math.round((h - 5) * 0.75), x + w - 5, y + 2.5 + math.round((h - 5) * 0.75))

	for k, v in ipairs(graph.pts) do
		love.graphics.setColor({0, 0, 0, 0.3})
		love.graphics.circle("fill", x + v.x * 146 + 2, y + (1 - v.y) * 146 + 2, 4)
	end

	if graph.parent.data.curve.z == 1 then
		love.graphics.setColor({0, 0, 0, 0.3})
		love.graphics.setLineWidth(4)
		drawCurve(graph.pts, x, y)
		love.graphics.setColor(style.gray9)
		love.graphics.setLineWidth(2)
		drawCurve(graph.pts, x, y)
	else
		love.graphics.setLineWidth(4)
		love.graphics.setColor(0, 0, 0, 0.3)
		drawCurve(graph.ptsG, x, y)
		drawCurve(graph.ptsB, x, y)
		drawCurve(graph.ptsR, x, y)
		love.graphics.setLineWidth(2)
		if graph.channel == 1 then
			love.graphics.setColor(style.green)
			drawCurve(graph.ptsG, x, y)
			love.graphics.setColor(style.blue)
			drawCurve(graph.ptsB, x, y)
			love.graphics.setColor(style.red)
			drawCurve(graph.ptsR, x, y)
		elseif graph.channel == 2 then
			love.graphics.setColor(style.blue)
			drawCurve(graph.ptsB, x, y)
			love.graphics.setColor(style.red)
			drawCurve(graph.ptsR, x, y)
			love.graphics.setColor(style.green)
			drawCurve(graph.ptsG, x, y)
		elseif graph.channel == 3 then
			love.graphics.setColor(style.red)
			drawCurve(graph.ptsR, x, y)
			love.graphics.setColor(style.green)
			drawCurve(graph.ptsG, x, y)
			love.graphics.setColor(style.blue)
			drawCurve(graph.ptsB, x, y)
		end
	end

	for k, v in ipairs(graph.pts) do
		love.graphics.setColor(style.gray9)
		love.graphics.circle("fill", x + v.x * 146 + 2, y + (1 - v.y) * 146 + 2, 3)
	end
end


function draw.equalizer(graph, x, y, w, h)
	love.graphics.setColor(style.gray3)

	love.graphics.rectangle("fill", x, y, w, h, 3, 3)

	if graph.background then
		love.graphics.setColor(0.8, 0.8, 0.8, 1)
		love.graphics.draw(graph.background, x+2, y+2, 0, 146/512, 146/512)
	end

	love.graphics.setLineWidth(0.7)
	love.graphics.setColor(style.gray5)
	love.graphics.rectangle("line", x + 2.5, y + 2.5, w - 5, h - 5)

	for i = 1, 7 do
		love.graphics.line(x + 2.5 + math.round((w - 5) * i/8), y + h - 5, x + 2.5 + math.round((w - 5) * i/8), y + 5)
	end
	love.graphics.line(x + 5, y + 2.5 + math.round((h - 5) * 0.50), x + w - 5, y + 2.5 + math.round((h - 5) * 0.50))

	for ch = 1, #graph.pts do
		if ch~=graph.channel then

			love.graphics.setColor({0, 0, 0, 0.3})
			love.graphics.setLineWidth(4)
			love.graphics.line(x + 2, y + (1 - graph.pts[ch][1]) * 146 + 2, x + 0.5/8 * 146 + 2, y + (1 - graph.pts[ch][1]) * 146 + 2)
			for i = 1, 7 do
				love.graphics.line(x + (i-0.5)/8 * 146 + 2, y + (1 - graph.pts[ch][i]) * 146 + 2, x + (i+1-0.5)/8 * 146 + 2, y + (1 - graph.pts[ch][i+1]) * 146 + 2)
			end
			love.graphics.line(x + 146 + 2, y + (1 - graph.pts[ch][8]) * 146 + 2, x + 7.5/8 * 146 + 2, y + (1 - graph.pts[ch][8]) * 146 + 2)
			for i = 1, 8 do
				love.graphics.circle("fill", x + (i-0.5)/8 * 146 + 2, y + (1 - graph.pts[ch][i]) * 146 + 2, 4)
			end

			love.graphics.setColor(style.gray5)
			love.graphics.setLineWidth(2)
			love.graphics.line(x + 2, y + (1 - graph.pts[ch][1]) * 146 + 2, x + 0.5/8 * 146 + 2, y + (1 - graph.pts[ch][1]) * 146 + 2)
			for i = 1, 7 do
				love.graphics.line(x + (i-0.5)/8 * 146 + 2, y + (1 - graph.pts[ch][i]) * 146 + 2, x + (i+1-0.5)/8 * 146 + 2, y + (1 - graph.pts[ch][i+1]) * 146 + 2)
			end
			love.graphics.line(x + 146 + 2, y + (1 - graph.pts[ch][8]) * 146 + 2, x + 7.5/8 * 146 + 2, y + (1 - graph.pts[ch][8]) * 146 + 2)
			for i = 1, 8 do
				love.graphics.circle("fill", x + (i-0.5)/8 * 146 + 2, y + (1 - graph.pts[ch][i]) * 146 + 2, 3)
			end

		end
	end

	local ch = graph.channel

	love.graphics.setColor({0, 0, 0, 0.3})
	love.graphics.setLineWidth(4)
	love.graphics.line(x + 2, y + (1 - graph.pts[ch][1]) * 146 + 2, x + 0.5/8 * 146 + 2, y + (1 - graph.pts[ch][1]) * 146 + 2)
	for i = 1, 7 do
		love.graphics.line(x + (i-0.5)/8 * 146 + 2, y + (1 - graph.pts[ch][i]) * 146 + 2, x + (i+1-0.5)/8 * 146 + 2, y + (1 - graph.pts[ch][i+1]) * 146 + 2)
	end
	love.graphics.line(x + 146 + 2, y + (1 - graph.pts[ch][8]) * 146 + 2, x + 7.5/8 * 146 + 2, y + (1 - graph.pts[ch][8]) * 146 + 2)
	for i = 1, 8 do
		love.graphics.circle("fill", x + (i-0.5)/8 * 146 + 2, y + (1 - graph.pts[ch][i]) * 146 + 2, 3)
	end

	love.graphics.setColor(style.gray9)
	love.graphics.setLineWidth(2)
	love.graphics.line(x + 2, y + (1 - graph.pts[ch][1]) * 146 + 2, x + 0.5/8 * 146 + 2, y + (1 - graph.pts[ch][1]) * 146 + 2)
	for i = 1, 7 do
		love.graphics.line(x + (i-0.5)/8 * 146 + 2, y + (1 - graph.pts[ch][i]) * 146 + 2, x + (i+1-0.5)/8 * 146 + 2, y + (1 - graph.pts[ch][i+1]) * 146 + 2)
	end
	love.graphics.line(x + 146 + 2, y + (1 - graph.pts[ch][8]) * 146 + 2, x + 7.5/8 * 146 + 2, y + (1 - graph.pts[ch][8]) * 146 + 2)
	for i = 1, 8 do
		love.graphics.circle("fill", x + (i-0.5)/8 * 146 + 2, y + (1 - graph.pts[ch][i]) * 146 + 2, 3)
	end

end


function draw.histogram(graph, x, y, w, h)
	love.graphics.setColor(style.gray3)
	love.graphics.rectangle("fill", x, y, w, h, 3, 3)

	local x = x + 2.5
	local y = y + 2.5
	local w = w - 5
	local h = h - 5

	love.graphics.setLineWidth(0.7)
	love.graphics.setLineJoin("none")
	love.graphics.setColor(style.gray5)
	love.graphics.rectangle("line", x, y, w, h)

	love.graphics.line(x + math.round((w) * 0.25), y + h - 2.5, x + math.round((w) * 0.25), y + 2.5)
	love.graphics.line(x + math.round((w) * 0.50), y + h - 2.5, x + math.round((w) * 0.50), y + 2.5)
	love.graphics.line(x + math.round((w) * 0.75), y + h - 2.5, x + math.round((w) * 0.75), y + 2.5)

	local hist = graph.parent.data.histogram

	local mr = graph.parent.elem[1].frame.elem[1].value and 1 or 0
	local mg = graph.parent.elem[1].frame.elem[2].value and 1 or 0
	local mb = graph.parent.elem[1].frame.elem[3].value and 1 or 0
	local ml = graph.parent.elem[1].frame.elem[4].value and 1 or 0

	local scale = 0
	for i = 3, 252 do
		local v = math.max(hist:get_u32(i, 0, 0) * mr, hist:get_u32(i, 0, 1) * mg, hist:get_u32(i, 0, 2) * mb, hist:get_u32(i, 0, 3) * ml)
		scale = math.max(scale, v)
	end

	scale = math.max(scale, 1)

	local rc = {}
	local gc = {}
	local bc = {}
	local lc = {}

	for i = 1, 254 do
		local r = 1 - math.min(hist:get_u32(i, 0, 0) / scale, 1)
		local g = 1 - math.min(hist:get_u32(i, 0, 1) / scale, 1)
		local b = 1 - math.min(hist:get_u32(i, 0, 2) / scale, 1)
		local l = 1 - math.min(hist:get_u32(i, 0, 3) / scale, 1)

		rc[(i - 1) * 2 + 1] = x + w / 255 * i
		rc[(i - 1) * 2 + 2] = y + h * r
		gc[(i - 1) * 2 + 1] = x + w / 255 * i
		gc[(i - 1) * 2 + 2] = y + h * g
		bc[(i - 1) * 2 + 1] = x + w / 255 * i
		bc[(i - 1) * 2 + 2] = y + h * b
		lc[(i - 1) * 2 + 1] = x + w / 255 * i
		lc[(i - 1) * 2 + 2] = y + h * l
	end

	love.graphics.setLineWidth(4)
	love.graphics.setColor(0, 0, 0, 0.3)
	if mr > 0 then love.graphics.line(rc) end
	if mg > 0 then love.graphics.line(gc) end
	if mb > 0 then love.graphics.line(bc) end
	if ml > 0 then love.graphics.line(lc) end

	love.graphics.setLineWidth(2)
	if mr > 0 then
		love.graphics.setColor(style.red)
		love.graphics.line(rc)
	end
	if mg > 0 then
		love.graphics.setColor(style.green)
		love.graphics.line(gc)
	end
	if mb > 0 then
		love.graphics.setColor(style.blue)
		love.graphics.line(bc)
	end
	if ml > 0 then
		love.graphics.setColor(style.gray9)
		love.graphics.line(lc)
	end
end

function draw.preview(graph, x, y, w, h)
	love.graphics.setColor(1, 1, 1, 1)
	graph.parent.data.preview:refresh()
	graph.parent.data.preview:draw(x, y)
end

return draw
