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

local style = require("ui.style")

local draw = {}

function draw.curve(graph, x, y, w, h)
	h = h - 20 -- offset for curve toggles, possibly make this dynamic
	love.graphics.setColor(style.gray3)

	love.graphics.rectangle("fill", x, y, w, h, 3, 3)
	
	-- curve type toggles
	do
		local y = y + 152
		local h = 18

		local p0 = x + 2.5
		local p1 = x + 2.5 + math.round((w - 5) * 0.25)
		local p2 = x + 2.5 + math.round((w - 5) * 0.50)
		local p3 = x + 2.5 + math.round((w - 5) * 0.75)
		local p4 = x + 2.5 + w - 5
		love.graphics.rectangle("fill", x, y, w, h, 3, 3) -- background
		love.graphics.setColor(style.gray5)

		if graph.curve.type=="linear" then
			love.graphics.rectangle("fill", p0,   y+2.5, p1-p0-1, h-5)
		elseif graph.curve.type=="bezier" then
			love.graphics.rectangle("fill", p1+1, y+2.5, p2-p1-2, h-5)
		elseif graph.curve.type=="hermite" then
			love.graphics.rectangle("fill", p2+1, y+2.5, p3-p2-2, h-5)
		elseif graph.curve.type=="cubic" then
			love.graphics.rectangle("fill", p3+1, y+2.5, p4-p3-1, h-5)
		end

		love.graphics.rectangle("line", p0,   y+2.5, p1-p0-1, h-5)
		love.graphics.rectangle("line", p1+1, y+2.5, p2-p1-2, h-5)
		love.graphics.rectangle("line", p2+1, y+2.5, p3-p2-2, h-5)
		love.graphics.rectangle("line", p3+1, y+2.5, p4-p3-1, h-5)
		
		love.graphics.setColor(style.gray9)
		love.graphics.setFont(style.smallFont)
		love.graphics.printf("Linear", p0,   y+4, p1-p0-1, "center")
		love.graphics.printf("Bezier", p1+1, y+4, p2-p1-2, "center")
		love.graphics.printf("Hermite", p2+1, y+4, p3-p2-2, "center")
		love.graphics.printf("Cubic", p3+1, y+4, p4-p3-1, "center")
	end

	if graph.background then
		love.graphics.setColor(0.8, 0.8, 0.8, 1)
		love.graphics.draw(graph.background, x+2.5, y+2.5, 0, (w-5)/512, (h-5)/512)
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

	love.graphics.setLineJoin("none")

	local n = w-4

	if graph.parent.data.curve.z==3 then
		-- draw 3 curves
		love.graphics.setColor(0, 0, 0, 0.3)
		love.graphics.setLineWidth(4)

		graph.curveR:drawLines(x + 2, y + 2, w - 4, h - 4, n)
		graph.curveG:drawLines(x + 2, y + 2, w - 4, h - 4, n)
		graph.curveB:drawLines(x + 2, y + 2, w - 4, h - 4, n)
		if graph.channel == 1 then
			graph.curveR:drawPts(x + 2, y + 2, w - 4, h - 4, 4)
		end
		if graph.channel == 2 then
			graph.curveG:drawPts(x + 2, y + 2, w - 4, h - 4, 4)
		end
		if graph.channel == 3 then
			graph.curveB:drawPts(x + 2, y + 2, w - 4, h - 4, 4)
		end

		love.graphics.setLineWidth(2)

		love.graphics.setColor(style.red)
		graph.curveR:drawLines(x + 2, y + 2, w - 4, h - 4, n)
		love.graphics.setColor(style.green)
		graph.curveG:drawLines(x + 2, y + 2, w - 4, h - 4, n)
		love.graphics.setColor(style.blue)
		graph.curveB:drawLines(x + 2, y + 2, w - 4, h - 4, n)
		if graph.channel == 1 then
			love.graphics.setColor(style.green)
			graph.curveG:drawLines(x + 2, y + 2, w - 4, h - 4, n)
			love.graphics.setColor(style.blue)
			graph.curveB:drawLines(x + 2, y + 2, w - 4, h - 4, n)
			love.graphics.setColor(style.red)
			graph.curveR:drawLines(x + 2, y + 2, w - 4, h - 4, n)
			graph.curveR:drawPts(x + 2, y + 2, w - 4, h - 4, 3)
		end
		if graph.channel == 2 then
			love.graphics.setColor(style.red)
			graph.curveR:drawLines(x + 2, y + 2, w - 4, h - 4, n)
			love.graphics.setColor(style.blue)
			graph.curveB:drawLines(x + 2, y + 2, w - 4, h - 4, n)
			love.graphics.setColor(style.green)
			graph.curveG:drawLines(x + 2, y + 2, w - 4, h - 4, n)
			graph.curveG:drawPts(x + 2, y + 2, w - 4, h - 4, 3)
		end
		if graph.channel == 3 then
			love.graphics.setColor(style.red)
			graph.curveR:drawLines(x + 2, y + 2, w - 4, h - 4, n)
			love.graphics.setColor(style.green)
			graph.curveG:drawLines(x + 2, y + 2, w - 4, h - 4, n)
			love.graphics.setColor(style.blue)
			graph.curveB:drawLines(x + 2, y + 2, w - 4, h - 4, n)
			graph.curveB:drawPts(x + 2, y + 2, w - 4, h - 4, 3)
		end
	else
		-- draw single curve
		love.graphics.setColor(0, 0, 0, 0.3)
		love.graphics.setLineWidth(4)
		graph.curve:drawLines(x + 2, y + 2, w - 4, h - 4, n)
		graph.curve:drawPts(x + 2, y + 2, w - 4, h - 4, 4)

		love.graphics.setLineWidth(2)
		love.graphics.setColor(style.gray9)
		graph.curve:drawLines(x + 2, y + 2, w - 4, h - 4, n)
		graph.curve:drawPts(x + 2, y + 2, w - 4, h - 4, 3)
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
	hist:lock()

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
	hist:unlock()

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

function draw.plot(graph, x, y, w, h)
	love.graphics.setColor(style.gray3)
	love.graphics.rectangle("fill", x, y, w, h, 3, 3)

	local plot = graph.parent.data.plot

	local x = x + 2.5
	local y = y + 2.5
	local w = w - 5
	local h = h - 5

	love.graphics.setColor(1, 1, 1, 1)
	plot:refresh()
	plot:draw(x-0.5, y-0.5)

	love.graphics.setLineWidth(0.7)
	love.graphics.setLineJoin("none")
	love.graphics.setColor(style.gray5)
	love.graphics.rectangle("line", x, y, w, h)

	love.graphics.setColor(1, 1, 1, 0.475)

	if graph.grid.horizontal then
		love.graphics.line(x + 2.5, y + math.round((h) * 0.25), x + w - 2.5, y + math.round((h) * 0.25))
		love.graphics.line(x + 2.5, y + math.round((h) * 0.50), x + w - 2.5, y + math.round((h) * 0.50))
		love.graphics.line(x + 2.5, y + math.round((h) * 0.75), x + w - 2.5, y + math.round((h) * 0.75))
	end

	if graph.grid.vertical then
		love.graphics.line(x + math.round((w) * 0.25), y + 2.5, x + math.round((w) * 0.25), y + h - 2.5)
		love.graphics.line(x + math.round((w) * 0.50), y + 2.5, x + math.round((w) * 0.50), y + h - 2.5)
		love.graphics.line(x + math.round((w) * 0.75), y + 2.5, x + math.round((w) * 0.75), y + h - 2.5)
	end

	if graph.grid.cross then
		love.graphics.line(x + 2.5, y + math.round((h) * 0.50), x + w - 2.5, y + math.round((h) * 0.50))
		love.graphics.line(x + math.round((w) * 0.50), y + 2.5, x + math.round((w) * 0.50), y + h - 2.5)
	end

	if graph.grid.polar then
		love.graphics.line(x + 2.5, y + math.round((h) * 0.50), x + w - 2.5, y + math.round((h) * 0.50))
		love.graphics.line(x + math.round((w) * 0.50), y + 2.5, x + math.round((w) * 0.50), y + h - 2.5)
		love.graphics.line(x + 2.5, y + 2.5, x + w - 2.5, y + h - 2.5)
		love.graphics.line(x + w - 2.5, y + 2.5, x + 2.5, y + h - 2.5)
		local r = math.min(h, w) * 0.5 - 2
		love.graphics.circle("line", x + math.round((w) * 0.50), y + math.round((h) * 0.50), r*0.5, 256)
		love.graphics.circle("line", x + math.round((w) * 0.50), y + math.round((h) * 0.50), r, 256)
	end
end

function draw.curveView(graph, x, y, w, h)
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

	local hist = graph.parent.data.curve
	hist:lock()

	local a = {}

	for i = 0, 255 do
		local v = hist:get(0, 0, i)

		a[(i - 1) * 2 + 1] = x + w / 255 * i
		a[(i - 1) * 2 + 2] = y + h * (1 - v)
	end
	hist:unlock()

	love.graphics.setLineWidth(4)
	love.graphics.setColor(0, 0, 0, 0.3)
	love.graphics.line(a)

	love.graphics.setLineWidth(2)
	love.graphics.setColor(style.gray9)
	love.graphics.line(a)
end

function draw.preview(graph, x, y, w, h)
	love.graphics.setColor(1, 1, 1, 1)
	graph.parent.data.preview:refresh()
	graph.parent.data.preview:draw(x, y)
end


local pixelcode = [[
	#define wp_x 0.95042854537718f
	#define wp_y 1.0f
	#define wp_z 1.0889003707981f
	#define E (216.0f/24389.0f)
	#define K (24389.0f/27.0f)

	float xyz(float V) {
		float V3 = V*V*V;
		if (V3>E) {
			return V3;
		} else {
			return (116.0f*V - 16.0f)/K;
		}
	}

	vec4 LAB_XYZ(vec4 i) {
		vec4 o;
		o.y = (i.x + 0.16f)/1.16f;
		o.x = i.y*0.2f + o.y;
		o.z = o.y - i.z*0.5f;
		o.x = wp_x*xyz(o.x);
		o.y = wp_y*xyz(o.y);
		o.z = wp_z*xyz(o.z);
		return o;
	}

	vec4 XYZ_LRGB(vec4 i) {
		vec4 o;
		o.x = i.x* 3.2404542f + i.y*-1.5371385f + i.z*-0.4985314f;
		o.y = i.x*-0.9692660f + i.y* 1.8760108f + i.z* 0.0415560f;
		o.z = i.x* 0.0556434f + i.y*-0.2040259f + i.z* 1.0572252f;
		return o;
	}

	#define A    0.055f
	#define G    2.4f
	#define N    0.03928571428571429f
	#define F    12.923210180787855f

	float srgb(float v) {
		if (v<N/F) {
			return F*v;
		} else {
			return (1+A)*pow(v, 1/G) - A;
		}
	}

	vec4 LRGB_SRGB(vec4 i) {
		return vec4(srgb(i.x), srgb(i.y), srgb(i.z), 0.0f);
	}

	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
	{
			vec4 texcolor = Texel(texture, texture_coords);
			float x = (texture_coords.x-0.5f)*2.0f;
			float y = (texture_coords.y-0.5f)*2.0f;

			if (x*x + y*y < 1.0f) {
				float r = 0.75f-0.5f*sqrt(x*x + y*y);
				vec4 col = LRGB_SRGB(XYZ_LRGB(LAB_XYZ(vec4(r, x*0.5f, y*0.5f, 0.0f))));
				texcolor.r = col.r;
				texcolor.g = col.g;
				texcolor.b = col.b;
			} else {
				texcolor.r = 0.3;
				texcolor.g = 0.3;
				texcolor.b = 0.3;
			}

			return texcolor;
	}
]]

local shader = love.graphics.newShader(pixelcode)

local canvas = love.graphics.newCanvas(100, 100, {msaa = 4})
local tempCanvas = love.graphics.getCanvas()
love.graphics.setCanvas(canvas)
love.graphics.setColor(0, 0, 0, 1)
love.graphics.rectangle("fill", 0, 0, 100, 100, 3.5, 3.5)
love.graphics.setCanvas(tempCanvas)

function draw.colorwheel(graph, x, y, w, h)
	love.graphics.setColor(style.gray3)

	love.graphics.setShader(shader)
	love.graphics.draw(canvas, x, y)
	love.graphics.setShader()

	love.graphics.setLineWidth(0.7)
	love.graphics.setLineJoin("miter")
	love.graphics.setColor(style.gray5)

	love.graphics.line(x + 50.5, y + h - 3.5, x + 50.5, y + 3.5)
	love.graphics.line(x + 3.5, y + 50.5, x + h - 3.5, y + 50.5)


	love.graphics.setLineWidth(1.2)
	love.graphics.circle("line", x+50, y+50, 50)

	love.graphics.setColor({0, 0, 0, 0.3})
	love.graphics.setLineWidth(3)
	love.graphics.circle("line", x + 50 + graph.x*50, y + 50 + graph.y*50, 3)

	love.graphics.setColor(style.gray9)
	love.graphics.setLineWidth(1.5)
	love.graphics.circle("line", x + 50 + graph.x*50, y + 50 + graph.y*50, 3)
end

return draw
