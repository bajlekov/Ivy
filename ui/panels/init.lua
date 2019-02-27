--[[
  Copyright (C) 2011-2018 G. Bajlekov

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


local Frame = require "ui.frame"
local Overlay = require "ui.overlay"

local ui = Frame:new():registerBaseFrame()

local menu = ui:frame("Menu", 19):toolbar(true)
local main = ui:frame("main")
local left = main:frame("left", 200)
local info = left:frame("Image Info", "fit"):panel()
local histPanel = left:frame("Histogram", 200 + 20 + 29):panel()

local filler = left:frame("filler"):panel(true)

local right = main:frame("right")
local toolbox = right:frame("Toolbox", 39):toolbar()
local image = right:frame("Image")
local status = ui:frame("Status", 16 + 4):statusbar()


--info:addElem("label", 1, "Image Details", true)
info:addElem("text", 1, "Name:", "unknown")
info:addElem("text", 2, "Make:", "unknown")
info:addElem("text", 3, "Model:", "unknown")
info:addElem("text", 4, "Lens:", "unknown")
info:addElem("text", 5, "Focal length:", "unknown")
info:addElem("text", 6, "Mode:", "unknown")
info:addElem("text", 7, "Exp. +/-:", "unknown")
info:addElem("text", 8, "Shutter:", "unknown")
info:addElem("text", 9, "Aperture:", "unknown")
info:addElem("text", 10, "ISO:", "unknown")
info:addElem("text", 11, "Date:", "unknown")
info:addElem("text", 12, "Size:", "unknown")
info:addElem("bool", 13, "Correct Distortion", true)

do
	local a = toolbox:addElem("bool", 1, "Move image", false)
	local b = toolbox:addElem("bool", 2, "Color picker", false)
	local ex = {a, b}
	a.exclusive = ex
	b.exclusive = ex
	b.last = true

	local c = toolbox:addElem("bool", 3, "Auto-connect", settings.nodeAutoConnect)
	c.first = true
	c.action = function(elem, mouse)
		settings.nodeAutoConnect = elem.value
	end
end

local nodeAddOverlay = require "ui.panels.nodeAddMenu"
toolbox:addElem("dropdown", 5, "Add node", nodeAddOverlay:copy())
require "ops.custom"("node", true)


-- track exclusive set of tools operating on the image panel
global("imageSample")
imageSample = {
	x = 0, y = 0,
	ix = 0, iy = 0,
	r = 0, g = 0, b = 0,
	dx = 0, dy = 0,
	exclusive = {toolbox.elem[1], toolbox.elem[2]},
	panel = image,
}
setmetatable(imageSample.exclusive, {__mode = "v"}) -- important to not anchor these elems!!!


-- TODO: move to menu
menu:addElem("label", 1, "Ivy")
local fileMenu = Overlay:new()
fileMenu.w = 201
menu:addElem("dropdown", 2, "File", fileMenu)
local processMenu = Overlay:new()
processMenu.w = 201
menu:addElem("dropdown", 3, "Process", processMenu)
local settingsMenu = Overlay:new()
settingsMenu.w = 201
menu:addElem("dropdown", 4, "Settings", settingsMenu)
local helpMenu = Overlay:new()
helpMenu.w = 201
menu:addElem("dropdown", 5, "Help", helpMenu)

fileMenu:addElem("button", 1, "Load Image...", function()
	local file = require "lib.zenity".fileOpen({
		title = "Load input image from file:",
		filename = "img.jpg",
		filter = "*",
	})
	if file then
		love.filedropped(file)
	end
end)
fileMenu:addElem("button", 2, "Save Image...", function(x, y)
	local file = require "lib.zenity".fileSave({
		title = "Save output image to file:",
		filename = "out.png",
		filter = "*.png",
	})

	if file then
		require "ui.notice".blocking("Saving image: "..file)
		require "tools.pipeline".output.image.imageData:encode("png", "out.png")
		local path = love.filesystem.getSaveDirectory( )
		--os.remove("out.png") --FIXME: ask to overwrite image or indicate failed saving
		-- TODO: convert to different format using imagemagick, optionally via 16bit ppm
		local p, err = os.rename(path.."/out.png", file)
		if not p then

			local errorMessage = Overlay:new("Error:")
			errorMessage:addElem("label", 2, err)
			errorMessage:addElem("button", 4, "OK")

			errorMessage.w = 500
			errorMessage:set(x, y)
			errorMessage.visible = true
		end
	end
end)

processMenu:addElem("button", 1, "New Process...", function() require "tools.process".new() end )
processMenu:addElem("button", 2, "Load Process...", function()
	local file = require "lib.zenity".fileOpen({
		title = "Load process pipeline from file:",
		filename = "process.lua",
		filter = "*.lua",
	})
	if file then
		require "tools.process".load(file)
	end
end )
processMenu:addElem("button", 3, "Append Process...", function()
	local file = require "lib.zenity".fileOpen({
		title = "Append process pipeline from file:",
		filename = "process.lua",
		filter = "*.lua",
	})
	if file then
		require "tools.process".load(file, true)
	end
end )
processMenu:addElem("button", 4, "Save Process...", function()
	local file = require "lib.zenity".fileSave({
		title = "Save process pipeline to file:",
		filename = "process.lua",
		filter = "*.lua",
	})
	if file then
		require "tools.process".save(file)
	end
end )


settingsMenu:addElem("label", 1, "Processing")
settingsMenu:addElem("text", 3, "", "unknown")
settingsMenu:addElem("text", 4, "", "unknown")
settingsMenu:addElem("bool", 5, "Continuous", false)

--helpMenu:addElem("button", 1, "Demo")
helpMenu:addElem("button", 1, "Documentation", function()
	love.system.openURL("file://"..love.filesystem.getWorkingDirectory().."/doc/build/html/index.html")
end)
helpMenu:addElem("button", 2, "About", function(x, y)
	local about = Overlay:new("About")
	about:addElem("label", 2, "Ivy")
	about:addElem("label", 3, "Version: 0.0.0-ALPHA")
	about:addElem("label", 4, "(C) 2011-2018 G. Bajlekov")
	about:addElem("label", 6, "GNU General Public License v3.0 or later")
	about:addElem("text", 8, [[
Ivy is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
]])

	about:addElem("button", 18, "Release Notes")
	about:addElem("button", 19, "License")
	about:addElem("button", 21, "OK")

	about.w = 500
	about:set(x, y)
	about.visible = true
end)

local thread = require "thread"
local device = thread.getDevice()
if device then -- TODO: proper device name parsing
	local deviceName = device:get_info("name")
	deviceName = deviceName:gsub("Intel%(R%) Core%(TM%)", "Intel Core")
	deviceName = deviceName:gsub(" CPU.*", "")
	deviceName = deviceName:gsub("Intel%(R%) HD Graphics ", "Intel HD")
	deviceName = deviceName:gsub("Ellesmere", "AMD RX 480")
	deviceName = deviceName:gsub("GeForce", "NVIDIA")
	settingsMenu.elem[3].right = deviceName

	local OCLversion = device:get_info("version")
	settingsMenu.elem[4].right = OCLversion
else
	settingsMenu.elem[3].right = "disabled"
	settingsMenu.elem[4].right = "disabled"
end

do
	local deviceSelect = settingsMenu:addElem("dropdown", 2, "OpenCL Devices")

	local warning = Overlay:new("Warning!")
	warning:addElem("text", 1, "Restart application to apply changes.")
	warning:addElem("button", 2, "OK")
	warning.w = 300

	deviceSelect.action = function(x, y)
		local overlay = Overlay:new("OpenCL Devices:")
		local cl = require("lib.opencl")

		local exclusive = {}

		local n = 1
		local platforms = cl.get_platforms()
		for i, platform in ipairs(platforms) do
			overlay:addElem("label", n, platform:get_info("name"))
			n = n + 1
			local devices = platform:get_devices()
			for j, device in ipairs(devices) do
				local e = overlay:addElem("bool", n, device:get_info("name"), i == settings.openclPlatform and j == settings.openclDevice)
				table.insert(exclusive, e)
				e.exclusive = exclusive
				e.action = function(mouse)
					settings.openclPlatform = i
					settings.openclDevice = j

					warning:set(e.parent.x, e.parent.y)
					warning.visible = true
				end
				n = n + 1
			end
		end

		-- not working
		--overlay:addElem("button", n + 1, "Restart!", function() love.event.quit("restart") end)

		overlay.w = 300
		overlay:set(x, y)
		overlay.visible = true
	end
end

do
	local oclLowMemSelect = settingsMenu:addElem("bool", 6, "Low OCL mem.", false)
	local warning = Overlay:new("Warning!")
	warning:addElem("text", 1, "Restart application to apply changes.")
	warning:addElem("button", 2, "OK")
	warning.w = 300

	oclLowMemSelect.value = settings.openclLowMemory or false

	oclLowMemSelect.action = function(e, m)
		settings.openclLowMemory = e.value
		warning:set(e.x, m.y)
		warning.visible = true
	end
end

do
	local hostLowMemSelect = settingsMenu:addElem("bool", 7, "Low host mem.", false)
	local warning = Overlay:new("Warning!")
	warning:addElem("text", 1, "Restart application to apply changes.")
	warning:addElem("button", 2, "OK")
	warning.w = 300

	hostLowMemSelect.value = settings.hostLowMemory or false

	hostLowMemSelect.action = function(e, m)
		settings.hostLowMemory = e.value
		warning:set(e.x, m.y)
		warning.visible = true
	end
end



histPanel:addElem("color", 1, "Color picker")

local overlayHistogram = Overlay:new()
local hist_r = overlayHistogram:addElem("bool", 1, "Red", false)
local hist_g = overlayHistogram:addElem("bool", 2, "Green", false)
local hist_b = overlayHistogram:addElem("bool", 3, "Blue", false)
local hist_l = overlayHistogram:addElem("bool", 4, "Lightness", true)
overlayHistogram:addElem("button", 5, "OK")
histPanel:addElem("dropdown", 2, "Visibility", overlayHistogram)


status.centerText = "Ivy (C) 2011-2018 G. Bajlekov"
local major, minor, revision = love.getVersion()
local loveVersion = string.format("LÖVE %d.%d.%d", major, minor, revision)
status.rightText = loveVersion.."/"..jit.version.." on "..jit.os.." "..jit.arch

local panels = {
	ui = ui,
	toolbox = toolbox,
	parameters = settingsMenu, --menu > process
	info = info,
	image = image,
	status = status,
	hist = {panel = histPanel, r = hist_r, g = hist_g, b = hist_b, l = hist_l}
}


ui:arrange()

return panels
