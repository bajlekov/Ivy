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

local style = require("ui.style")
local tint = style.tint

local drawElem = require("ui.elem.draw")
local event = require "ui.node.event"

local function draw(self, element)
	local nodeWidth = self.w or style.nodeWidth
	local nodeHeight = style.titleHeight + style.elemHeight * math.ceil(self.elem.n / self.elem.cols) - (self.elem.n == 0 and style.nodeBorder or style.elemBorder)

	do
		local nodeHeight = nodeHeight + (self.graph and self.graph.h + 1 or 0)
		local scale = settings.scaleUI
		local x, y = math.round(self.ui.x*scale)/scale, math.round(self.ui.y*scale)/scale
		local w = love.graphics.getWidth()/scale
		local h = love.graphics.getHeight()/scale

		if x > w - nodeWidth - 3 then x = w - nodeWidth - 3 end
		if y > h - nodeHeight - 3 then y = h - nodeHeight - 3 end
		if x < 3 then x = 3 end
		if y < 3 then y = 3 end

		if self.ui.x~=x or self.ui.y~=y then
			self:setPos(x, y)
		end
	end

	if element == "link out" then
		for i = 0, self.elem.n do
			if self.portOut[i] and self.portOut[i].link then
				self.portOut[i].link:draw()
			end
		end
		return
	end

	local x, y = self.ui.x, self.ui.y

	if self.graph then
		nodeHeight = nodeHeight + self.graph.h + style.nodeBorder
	end

	-- draw node base
	-- check if ports in/out, shrink node size if not
	do
		local left = next(self.portIn)
		local right = next(self.portOut)
		local x = x - style.nodeBorder - (left and style.elemHeight / 2 or 0)
		local y = y - style.nodeBorder
		local w = nodeWidth + style.nodeBorder * 2 + (left and style.elemHeight / 2 or 0) + (right and style.elemHeight / 2 or 0)
		local h = nodeHeight + style.nodeBorder * 2

		if style.shadow then
			love.graphics.setColor(style.shadowColor)
			love.graphics.rectangle("fill", x - 1, y - 1, w + 4, h + 4, 5, 5)
			love.graphics.rectangle("fill", x - 1, y - 1, w + 3, h + 3, 4, 4)
			love.graphics.rectangle("fill", x - 1, y - 1, w + 2, h + 2, 3, 3)
		end

		love.graphics.setColor(tint(style.nodeColor, self.tint))
		love.graphics.rectangle("fill", x, y, w, h, 3, 3)
	end

	if self.graph then
		self.graph:draw(x, y + nodeHeight - self.graph.h, nodeWidth, self.graph.h)
	end

	-- draw title
	drawElem.title(x, y, nodeWidth, style.titleHeight - style.nodeBorder, self.title, self.tint)

	-- status indicator
	if self.state == "waiting" then
		love.graphics.setColor(style.blue)
	elseif self.state == "processing" then
		love.graphics.setColor(settings.linkDebug and style.purple or style.blue)
	elseif self.state == "ready" then
		love.graphics.setColor(settings.linkDebug and style.green or style.blue)
	elseif self.state then -- unknown state
		love.graphics.setColor(style.red)
	else -- no state/disconnected
		love.graphics.setColor(style.titleFontColor)
	end

	love.graphics.setLineWidth(3)
	love.graphics.line(x + 25, y - 0.5, x + nodeWidth - 25, y - 0.5)
	love.graphics.setLineWidth(1)

	if self.portIn[0] then
		if self.portIn[0].link then
			love.graphics.setColor(tint(style.portOnColor, self.tint))
		else
			love.graphics.setColor(tint(style.portOffColor, self.tint))
		end
		love.graphics.rectangle("fill", x - style.nodeBorder - (style.elemHeight) / 2, y + style.titleHeight - style.elemHeight - style.nodeBorder + style.elemBorder, (style.elemHeight) / 2, style.elemHeight - style.elemBorder, 3, 3)
		love.graphics.rectangle("fill", x - style.nodeBorder - (style.elemHeight) / 2, y + style.titleHeight - style.elemHeight - style.nodeBorder + style.elemBorder, (style.elemHeight) / 2 - 3, style.elemHeight - style.elemBorder)
	end

	if self.portOut[0] then
		if self.portOut[0].link then
			love.graphics.setColor(tint(style.portOnColor, self.tint))
		else
			love.graphics.setColor(tint(style.portOffColor, self.tint))
		end
		love.graphics.rectangle("fill", x + nodeWidth + style.nodeBorder, y + style.titleHeight - style.elemHeight - style.nodeBorder + style.elemBorder, (style.elemHeight) / 2, style.elemHeight - style.elemBorder, 3, 3)
		love.graphics.rectangle("fill", x + nodeWidth + style.nodeBorder + 3, y + style.titleHeight - style.elemHeight - style.nodeBorder + style.elemBorder, (style.elemHeight) / 2 - 3, style.elemHeight - style.elemBorder)
	end

	for i = 1, self.elem.n do
		if self.portIn[i] then

			-- override elem toggles with toggle table
			if self.portIn[i].toggle then
				for k, v in pairs(self.portIn[i].toggle) do
					if self.elem[k] then
						if v then
							self.elem[k].disabled = self.portIn[i].link==nil
						else
							self.elem[k].disabled = self.portIn[i].link~=nil
						end
					end
				end
			else
				-- toggle matching elements
				if self.portIn[i].link then
					self.elem[i].disabled = true
				else
					self.elem[i].disabled = false
				end
			end

			if self.portIn[i].link then
				love.graphics.setColor(tint(style.portOnColor, self.tint))
			else
				love.graphics.setColor(tint(style.portOffColor, self.tint))
			end

			love.graphics.rectangle("fill", x - style.nodeBorder - (style.elemHeight) / 2, y + style.titleHeight + style.elemHeight * (i - 1), (style.elemHeight) / 2, style.elemHeight - style.elemBorder, 3, 3)
			love.graphics.rectangle("fill", x - style.nodeBorder - (style.elemHeight) / 2, y + style.titleHeight + style.elemHeight * (i - 1), (style.elemHeight) / 2 - 3, style.elemHeight - style.elemBorder)
			if self.portIn[i - 1] and i ~= 1 then
				love.graphics.rectangle("fill", x - style.nodeBorder - (style.elemHeight) / 2, y + style.titleHeight + style.elemHeight * (i - 1), (style.elemHeight) / 2, style.elemHeight - style.elemBorder - 3)
			end
			if self.portIn[i + 1] then
				love.graphics.rectangle("fill", x - style.nodeBorder - (style.elemHeight) / 2, y + style.titleHeight + style.elemHeight * (i - 1) + 3, (style.elemHeight) / 2, style.elemHeight - style.elemBorder - 3)
			end
		end
		if self.portOut[i] then
			if self.portOut[i].link then
				love.graphics.setColor(tint(style.portOnColor, self.tint))
			else
				love.graphics.setColor(tint(style.portOffColor, self.tint))
			end
			love.graphics.rectangle("fill", x + nodeWidth + style.nodeBorder, y + style.titleHeight + style.elemHeight * (i - 1), (style.elemHeight) / 2, style.elemHeight - style.elemBorder, 3, 3)
			love.graphics.rectangle("fill", x + nodeWidth + style.nodeBorder + 3, y + style.titleHeight + style.elemHeight * (i - 1), (style.elemHeight) / 2 - 3, style.elemHeight - style.elemBorder)
			if self.portOut[i - 1] and i ~= 1 then
				love.graphics.rectangle("fill", x + nodeWidth + style.nodeBorder, y + style.titleHeight + style.elemHeight * (i - 1), (style.elemHeight) / 2, style.elemHeight - style.elemBorder - 3)
			end
			if self.portOut[i + 1] then
				love.graphics.rectangle("fill", x + nodeWidth + style.nodeBorder, y + style.titleHeight + style.elemHeight * (i - 1) + 3, (style.elemHeight) / 2, style.elemHeight - style.elemBorder - 3)
			end
		end
	end

	if self.elem.cols == 1 then
		local w = nodeWidth
		local h = style.elemHeight - style.elemBorder
		for i = 1, self.elem.n do
			if self.elem[i] then
				self.elem[i].first = self.elem[i].first~=nil and self.elem[i].first or not (self.elem[i - 1] and self.elem[i - 1].type == self.elem[i].type)
				self.elem[i].last = self.elem[i].last~=nil and self.elem[i].last or not (self.elem[i + 1] and self.elem[i + 1].type == self.elem[i].type)

				local y = y + style.titleHeight + style.elemHeight * (i - 1)

				self.elem[i]:draw(x, y, w, h)
			end
		end
	else
		assert(self.elem.cols > 1)

		local h = style.elemHeight - style.elemBorder
		for i = 1, self.elem.n do
			local i_h = (i - 1) % self.elem.cols
			local i_v = math.floor((i - 1) / self.elem.cols)

			if self.elem[i] then
				local y = y + style.titleHeight + style.elemHeight * i_v
				local w = nodeWidth/self.elem.cols
				local xmin = math.floor(x + w * i_h + 1)
				local xmax = math.floor(x + w * (i_h + 1))

				if i_h==0 then
					self.elem[i].first = true
					xmin = x
				elseif i_h==self.elem.cols-1 then
					self.elem[i].last = true
					xmax = x + nodeWidth
				end

				self.elem[i].first = self.elem[i].first~=nil and self.elem[i].first or not (self.elem[i - 1] and self.elem[i - 1].type == self.elem[i].type)
				self.elem[i].last = self.elem[i].last~=nil and self.elem[i].last or not (self.elem[i + 1] and self.elem[i + 1].type == self.elem[i].type)

				self.elem[i]:draw(xmin, y, xmax - xmin, h)
			end
		end
	end

end

return draw
