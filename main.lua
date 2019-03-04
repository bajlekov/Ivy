--[[
  Copyright (C) 2011-2019 G. Bajlekov

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

print([[    Ivy
    Copyright (C) 2019  Galin Bajlekov

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

]])

require "setup"
local ffi = require "ffi"

local serpent = require("lib.serpent")


global("settings")
if love.filesystem.isFused() then
	if love.filesystem.mount(love.filesystem.getSourceBaseDirectory(), "base") then
		settings = require "base.settings"
	end
else
	settings = loadfile("settings.lua")()
end


assert(love.window.setMode(1280, 720, {resizable = true, vsync = true, minwidth = 1280, minheight = 720, msaa = 4} ))
love.window.setTitle("Ivy: Initializing...")
love.window.setIcon(love.image.newImageData("res/icon.png"))

love.window.maximize()
require "ui.notice".blocking("Initializing ...", true)


local oclPlatform = false
local oclDevice = false
do
	oclPlatform = settings.openclPlatform
	oclDevice = settings.openclDevice

	local cl = require("lib.opencl")

	local platforms = cl.get_platforms()
	assert(#platforms>0, "No OpenCL platform found!")
	if oclPlatform > #platforms then
		oclPlatform = 1
		settings.openclPlatform = 1
		oclDevice = 1
		settings.openclDevice = 1
	end
	local devices = platforms[oclPlatform]:get_devices()
	if oclDevice > #devices then
		oclDevice = 1
		settings.openclDevice = 1
	end

	local function mem(n)
		return math.floor((n / 1024 / 1024)).."MB"
	end

	local function tab(t)
		return "[ "..table.concat(t, ", ").." ]"
	end

	local platforms = cl.get_platforms()
	for i, platform in ipairs(platforms) do
		print("platform: " .. i)
		print("name    : " .. platform:get_info("name"))
		print("vendor  : " .. platform:get_info("vendor"))
		print("version : " .. platform:get_info("version"))
		print()
		local devices = platform:get_devices()
		for j, device in ipairs(devices) do
			print("\tplatform: " .. i)
			print("\tdevice  : " .. j)
			print("\tname    : " .. device:get_info("name"))
			print("\tvendor  : " .. device:get_info("vendor"))
			print("\tversion : " .. device:get_info("version"))
			print("\tcompute : " .. device:get_info("max_compute_units"))
			print("\tmemory  : " .. mem(device:get_info("global_mem_size")))
			print("\tworkgr. : " .. device:get_info("max_work_group_size"))
			print()
		end
	end
end

local data = require "data"
local thread = require "thread"
thread.init(oclPlatform, oclDevice, settings.nativeCoreCount)
data.initDev(thread.getContext(), thread.getQueue())

local image = require "ui.image"
local panels = require "ui.panels"
local overlay = require "ui.overlay"
local node = require "ui.node"
local link = require "ui.node.link"

local ops = require "ops"

local pipeline = require "tools.pipeline"
do
	local autoconnect = settings.nodeAutoConnect
	settings.nodeAutoConnect = false
	pipeline.input = ops.input(300, 200)
	pipeline.output = ops.output(500, 200)
	settings.nodeAutoConnect = autoconnect
end

if not pcall(function() require "tools.process".load("process.lua") end) then
	require "tools.process".new()
end

pipeline.output.data.histogram = data:new(256, 1, 4):allocHost()

local nodeDFS = require "ui.node.dfs"
local cycles = nodeDFS(node)


local OCL = true

local exifData
local originalImage
local RAW_SRGBmatrix
local RAW_WBmultipliers

local imageOffset = data:new(1, 1, 6)
local previewImage

local loadInputImage = true
local dirtyImage = true
local processReady = true

function love.filedropped(file)
	require "ui.notice".blocking("Loading image: "..(type(file) == "string" and file or file:getFilename()), true)
	collectgarbage("collect")
	assert(file, "ERROR: File loading failed")

	originalImage, RAW_SRGBmatrix, RAW_WBmultipliers = require("io."..settings.imageLoader).read(file)
	originalImage:toDevice(true)
	if RAW_SRGBmatrix then RAW_SRGBmatrix:toDevice(true) end
	if RAW_WBmultipliers then RAW_WBmultipliers:toDevice(true) end

	love.window.setTitle("Ivy: "..( type(file) == "string" and file or file:getFilename() ))
	exifData = require("io.exif").read(file)

	local fileName = type(file) == "string" and file or file:getFilename() or "-"
	panels.info.elem[1].right = fileName:gsub("^(.*/)", ""):gsub("^(.*\\)", "")
	panels.info.elem[2].right = exifData.Make or " - "
	panels.info.elem[3].right = exifData.CameraModelName or " - "
	panels.info.elem[4].right = exifData.LensModel or " - "
	panels.info.elem[5].right = (exifData.FocalLength or " - ").."mm"

	local programModes = {
		"Manual Exposure",
		"Program AE",
		"Aperture Priority AE",
		"Shutter Priority AE",
		"Creative",
		"Action",
		"Portrait",
		"Landscape",
		"Bulb",
	}

	panels.info.elem[6].right = exifData.ExposureProgram and programModes[tonumber(exifData.ExposureProgram)] or "-"
	panels.info.elem[7].right = (exifData.ExposureCompensation or " -").." EV"

	local shutter = tonumber(exifData.ShutterSpeed)
	if shutter then
		if shutter > 0.5 then
			shutter = ("%0.2f"):format(shutter)
		else
			shutter = ("1/%d"):format(1 / shutter)
		end
	end

	panels.info.elem[8].right = (shutter or " - ").."s"
	panels.info.elem[9].right = "f/"..(exifData.Aperture or " - ")
	panels.info.elem[10].right = "ISO "..(exifData.ISO or " - ")
	panels.info.elem[11].right = exifData.Date or " - "
	panels.info.elem[12].right = ("%d X %d (%.1fMP)"):format(originalImage.x, originalImage.y, originalImage.x*originalImage.y*1e-6)

	imageOffset:set(0, 0, 0, 0) -- x offset
	imageOffset:set(0, 0, 1, 0) -- y offset
	imageOffset:set(0, 0, 2, 1) -- scale!!
	local A, B, C = require("tools.lensfun")(exifData.LensModel or exifData.CameraModelName, exifData.FocalLength)
	imageOffset:set(0, 0, 3, A) -- distortion correction
	imageOffset:set(0, 0, 4, B) -- distortion correction
	imageOffset:set(0, 0, 5, C) -- distortion correction
	imageOffset:toDevice()

	pipeline.input.imageData = originalImage:new()
	pipeline.output.image = image.new(pipeline.input.imageData)

	pipeline.output.image.scale = math.min(panels.image.w / pipeline.input.imageData.x, panels.image.h / pipeline.input.imageData.y, 1)
	pipeline.output.image.drawOffset.x = (panels.image.w - pipeline.input.imageData.x * pipeline.output.image.scale) / 2
	pipeline.output.image.drawOffset.y = (panels.image.h - pipeline.input.imageData.y * pipeline.output.image.scale) / 2

	previewImage = pipeline.output.image

	loadInputImage = true
	dirtyImage = true

	local t = require "ops.tools"
	t.imageShapeSet(pipeline.input.imageData.x, pipeline.input.imageData.y, pipeline.input.imageData.z)
end

-- trigger image load at start
love.filedropped(settings.imagePath)



local scrollable = false
local displayScale = false

local function rescaleInputOutput()
	if displayScale then
		scrollable = true

		pipeline.input.imageData = data:new(math.floor(panels.image.w / displayScale), math.floor(panels.image.h / displayScale), 3)
		pipeline.output.image = image.new(pipeline.input.imageData)

		pipeline.output.image.scale = displayScale
		pipeline.output.image.drawOffset.x = 0
		pipeline.output.image.drawOffset.y = 0
	else
		scrollable = false
		pipeline.input.imageData = originalImage:new()
		pipeline.output.image = image.new(pipeline.input.imageData)

		pipeline.output.image.scale = math.min(panels.image.w / pipeline.input.imageData.x, panels.image.h / pipeline.input.imageData.y, 1)
		pipeline.output.image.drawOffset.x = (panels.image.w - pipeline.input.imageData.x * pipeline.output.image.scale) / 2
		pipeline.output.image.drawOffset.y = (panels.image.h - pipeline.input.imageData.y * pipeline.output.image.scale) / 2
	end
end



local processComplete = 0
local processTotal = 0

local messageCh = love.thread.getChannel("messageCh")
local currentID = false
local message = ""
local tempMessage = ""

local t1 = love.timer.getTime()
local procTime = 0

local reloadDev = true
local hist

local correctDistortion

function love.update()

	if correctDistortion~=panels.info.elem[13].value then
		loadInputImage = true
	end

	-- handle thread messages
	while messageCh:getCount() > 0 do
		local messageIn = messageCh:pop()

		local code = messageIn[1]
		local id = messageIn[2]

		if code == "error" then
			tempMessage = id:sub(1, 4096)
			--node.list[currentID].state = "error"
		elseif code == "start" and id then
			local node = node.list[id]
			if node.state == "waiting" then node.state = "processing" end
			currentID = id
			processComplete = processComplete + 1
		elseif code == "end" and id then
			local node = node.list[id]
			if node.state == "processing" then
				node.state = "ready"
			end

			-- deallocate link data after node is complete
			-- not useful as, due to processing queue, all buffers are initialized at the start
			-- this would require full synchronization

			-- FIXME: use static deallocation scheme!
			if not settings.linkCache then
				debug.tic()
				for i = 0, node.elem.n do
					if node.portIn[i] and node.portIn[i].link then
						local link = node.portIn[i].link
						local old = true
						if link.portIn.parent.protected then
							old = false
						else
							for p in pairs(link.portOut) do
								if p.parent.state~="ready" or p.parent.protected then
									old = false
									break
								end
							end
						end
						if old then
							link.data:free()
							link.data = nil
							for k, v in pairs(link.dataCS) do
								v:free()
							end
							link.dataCS = {}
						end
					end
				end
				debug.toc("link cache clear")
			end

			assert(id == currentID)
			currentID = false
			processComplete = processComplete + 1
		end
	end

	if thread.done(OCL) then
		processReady = true
		message = tempMessage

		link.collectGarbage() -- clean all deleted data references once processing is finished
		previewImage = pipeline.output.image:refresh() -- set to display the new output.image next

		if pipeline.output.elem[1].value then
			hist = pipeline.output.data.histogram:copy()
		else
			hist = false
		end

		local t2 = love.timer.getTime()
		procTime = t2 - t1
	end

	if processReady and (dirtyImage or panels.parameters.elem[5].value) then
		t1 = love.timer.getTime()

		if loadInputImage then -- load cropped image if not already cached
			loadInputImage = false

			rescaleInputOutput()
			imageOffset:toDevice()

			--thread.ops.cropCorrectFisheye({originalImage, input.imageData, imageOffset}, OCL and "dev" or "par")
			if panels.info.elem[13].value then
				thread.ops.cropCorrect({originalImage, pipeline.input.imageData, imageOffset}, "dev")
			else
				thread.ops.crop({originalImage, pipeline.input.imageData, imageOffset}, "dev")
			end
			correctDistortion = panels.info.elem[13].value

			if RAW_SRGBmatrix and RAW_WBmultipliers then
				thread.ops.RAWtoSRGB({pipeline.input.imageData, RAW_SRGBmatrix, RAW_WBmultipliers}, "dev")
			end

			pipeline.input.imageData.__cpuDirty = true
			pipeline.input.imageData.__gpuDirty = false

			if pipeline.input.portOut[0].link then
				pipeline.input:process()
				pipeline.input.dirty = true
			end
		else
			if pipeline.input.portOut[0].link and  not pipeline.input.portOut[0].link.data then
				pipeline.input:process()
			end
			pipeline.input.dirty = not settings.linkCache
		end

		if reloadDev then
			thread.ops.reloadDev()
			reloadDev = false
		end

		local outputs = {}
		for n in node.stack:traverseUp() do
			n.state = false
			if n.compute then
				n.dirty = true
				table.insert(outputs, n)
			end
		end

		processTotal = 1

		local dfs = nodeDFS(node, outputs)

		for k, n in ipairs(dfs) do
			if n.dirty then
				n.procType = OCL and "dev" or "par" -- "dev": device, "host": host, "par": host parallel
				n.state = "waiting"
				n:process()
				processTotal = processTotal + 1
			else
				n.state = "ready"
			end

			-- dirty directly dependent nodes, equivalent to a single forward step of dfs
			if n.dirty and n.portOut then
				n.dirty = false
				for i = 0, n.elem.n do -- traverse all outputs
					if n.portOut[i] and n.portOut[i].link then
						for k, v in pairs(n.portOut[i].link.portOut) do
							k.parent.dirty = true
						end
					end
				end
			end
		end

		thread.ops.done()

		processComplete = 0

		processReady = false
		dirtyImage = false

		love.window.requestAttention() -- highlight when processing is completed
	end
end



local style = require("ui.style")
local alloc = require("data.alloc")

function love.draw()
	love.graphics.scale(settings.scaleUI, settings.scaleUI)

	love.graphics.clear(style.backgroundColor)

	-- update status panel
	local processor = tostring("OpenCL "..panels.parameters.elem[3].right.." / "..jit.arch.." LuaJIT")
	panels.status.leftText = string.format("UI: %.1ffps | Processing: %.1fms (%s) | Memory used: %.1fMB (%d buffers)", love.timer.getFPS(), procTime * 1000, processor, alloc.trace.size(), alloc.trace.countLarge())

	panels.ui:draw()

	love.graphics.setColor(1, 1, 1, 1)
	previewImage:draw(panels.image.x, panels.image.y)

	love.graphics.setColor(style.orange)
	love.graphics.setFont(style.messageFont)
	love.graphics.print(message, math.floor(panels.image.x + 5), math.floor(panels.image.y + 5))

	-- draw histogram
	local scale = 0
	if hist then
		local histPanel = panels.hist.panel
		local mr = panels.hist.r.value and 1 or 0
		local mg = panels.hist.g.value and 1 or 0
		local mb = panels.hist.b.value and 1 or 0
		local ml = panels.hist.l.value and 1 or 0

		for i = 3, 252 do
			local v = math.max(hist:get_u32(i, 0, 0) * mr, hist:get_u32(i, 0, 1) * mg, hist:get_u32(i, 0, 2) * mb, hist:get_u32(i, 0, 3) * ml)
			scale = math.max(scale, v)
		end

		scale = math.max(scale, 1)

		local rc = {}
		local gc = {}
		local bc = {}
		local lc = {}

		local x = histPanel.x + 5.5
		local y = histPanel.y + histPanel.h - histPanel.w + 5.5
		local w = histPanel.w - 11
		local h = histPanel.w - 11

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

		local x = histPanel.x + 1
		local y = histPanel.y + histPanel.h

		love.graphics.setLineJoin("none")
		love.graphics.setColor(style.gray3)
		love.graphics.rectangle("fill", x + 2, y - histPanel.w + 3, histPanel.w - 6, histPanel.w - 6, 3, 3)

		love.graphics.setLineWidth(0.7)
		love.graphics.setLineJoin("none")
		love.graphics.setColor(style.gray5)
		love.graphics.rectangle("line", x + 4.5, y - histPanel.w + 5.5, histPanel.w - 11, histPanel.w - 11)
		love.graphics.line(x + 4.5 + math.round((histPanel.w - 10) * 0.25), y - histPanel.w + 8, x + 4.5 + math.round((histPanel.w - 10) * 0.25), y - 8)
		love.graphics.line(x + 4.5 + math.round((histPanel.w - 10) * 0.50), y - histPanel.w + 8, x + 4.5 + math.round((histPanel.w - 10) * 0.50), y - 8)
		love.graphics.line(x + 4.5 + math.round((histPanel.w - 10) * 0.75), y - histPanel.w + 8, x + 4.5 + math.round((histPanel.w - 10) * 0.75), y - 8)

		love.graphics.setLineWidth(4)
		love.graphics.setColor(0, 0, 0, 0.3)
		if panels.hist.r.value then love.graphics.line(rc) end
		if panels.hist.g.value then love.graphics.line(gc) end
		if panels.hist.b.value then love.graphics.line(bc) end
		if panels.hist.l.value then love.graphics.line(lc) end


		love.graphics.setLineWidth(2)
		if panels.hist.r.value then
			love.graphics.setColor(style.red)
			love.graphics.line(rc)

			local value = histPanel.elem[1].value[1]
			if value>0.001 and value<0.999 then
				love.graphics.line(x + 4.5 + math.round((histPanel.w - 10) * value), y - histPanel.w + 8, x + 4.5 + math.round((histPanel.w - 10) * value), y - 8)
			end
		end
		if panels.hist.g.value then
			love.graphics.setColor(style.green)
			love.graphics.line(gc)

			local value = histPanel.elem[1].value[2]
			if value>0.001 and value<0.999 then
				love.graphics.line(x + 4.5 + math.round((histPanel.w - 10) * value), y - histPanel.w + 8, x + 4.5 + math.round((histPanel.w - 10) * value), y - 8)
			end
		end
		if panels.hist.b.value then
			love.graphics.setColor(style.blue)
			love.graphics.line(bc)

			local value = histPanel.elem[1].value[3]
			if value>0.001 and value<0.999 then
				love.graphics.line(x + 4.5 + math.round((histPanel.w - 10) * value), y - histPanel.w + 8, x + 4.5 + math.round((histPanel.w - 10) * value), y - 8)
			end
		end
		if panels.hist.l.value then
			love.graphics.setColor(style.gray9)
			love.graphics.line(lc)
		end

	end

	-- draw nodes
	for n in node.stack:traverseUp() do
		n:draw("link out")
	end
	for n in node.stack:traverseUp() do
		n:draw()
	end
	if #cycles > 0 then
		for k, v in pairs(cycles) do
			v:draw(style.red)
		end
	end

	overlay:draw()

	-- draw notice
	if not processReady then
		--require "ui.notice".overlay(("Processing... [%d%%]"):format(processComplete / processTotal * 100))
		require "ui.notice".overlay("Processing...")
	end
end



-- image panning function
local function imagePan(dx, dy)
	if scrollable then
		local ox, oy = imageOffset:get(0, 0, 0), imageOffset:get(0, 0, 1)
		ox = ox - dx / displayScale
		oy = oy + dy / displayScale
		imageOffset:set(0, 0, 0, ox)
		imageOffset:set(0, 0, 1, oy)
		loadInputImage = true
	end
end

-- register frame callbacks
local function imagePanDragCallback(mouse) imagePan(mouse.dx, mouse.dy) end
local function imagePanCallback(frame, mouse) return imagePanDragCallback end

--TODO: keep track of drag changes
--TODO: set x, y to false after click release

function imageSample.coord(x, y)
	x = (x - previewImage.drawOffset.x) / previewImage.scale
	y = (y - previewImage.drawOffset.y) / previewImage.scale
	y = previewImage.y - y
	x = math.floor(math.min(math.max(x, 0), previewImage.x - 1))
	y = math.floor(math.min(math.max(y, 0), previewImage.y - 1))
	imageSample.ix = x
	imageSample.iy = y
	return x, y
end

-- color picker function
function imageSample.sample(x, y)
	x, y = imageSample.coord(x, y)
	imageSample.r = previewImage:get(x, y, 0)
	imageSample.g = previewImage:get(x, y, 1)
	imageSample.b = previewImage:get(x, y, 2)
	panels.hist.panel.elem[1].name = ("R: %03d\tG: %03d\tB: %03d"):format(imageSample.r, imageSample.g, imageSample.b)
	panels.hist.panel.elem[1].value[1] = imageSample.r / 255
	panels.hist.panel.elem[1].value[2] = imageSample.g / 255
	panels.hist.panel.elem[1].value[3] = imageSample.b / 255
end

local function imageSampleReleaseCallback()
	imageSample.dx = 0
	imageSample.dy = 0
end
local function imageSampleDragCallback(mouse)
	imageSample.dx = mouse.x - mouse.ox
	imageSample.dy = mouse.y - mouse.oy
	imageSample.sample(imageSample.x + imageSample.dx, imageSample.y + imageSample.dy)
	return imageSampleReleaseCallback
end
local function imageSampleCallback(frame, mouse)
	local x = mouse.lx
	local y = mouse.ly
	imageSample.x = x
	imageSample.y = y
	imageSample.sample(x, y)
	return imageSampleDragCallback
end

panels.image.onSpaceAction = imagePanCallback
panels.toolbox.elem[1].onChange = function(elem) if elem.value then panels.image.onAction = imagePanCallback end end
panels.toolbox.elem[2].onChange = function(elem) if elem.value then panels.image.onAction = imageSampleCallback end print("color picker") end

for k, v in pairs(imageSample.exclusive) do
	v.value = false
end
panels.toolbox.elem[1].value = true
panels.toolbox.elem[1]:onChange()
panels.image.onContext = overlay.show


local uiInput = require "ui.input"

function love.mousemoved(x, y, dx, dy)
	uiInput.mouseMoved(x / settings.scaleUI, y / settings.scaleUI, dx / settings.scaleUI, dy / settings.scaleUI)
	if love.mouse.isDown(1) then
		dirtyImage = true
	end
end

function love.mousepressed(x, y, button, isTouch)
	uiInput.mousePressed(x / settings.scaleUI, y / settings.scaleUI, button)
	dirtyImage = true
	cycles = {} -- clear cycle indication
end

function love.mousereleased(x, y, button, isTouch)
	uiInput.mouseReleased(x / settings.scaleUI, y / settings.scaleUI, button)
	cycles = nodeDFS(node) -- populate cycle indication
	dirtyImage = true
end

function pipeline.update()
  dirtyImage = true
end

local fullscreen = false
function love.keypressed(key)
	if key == "1" then
		displayScale = 1
		print("Scale: 100%")
	elseif key == "2" then
		displayScale = 2
		print("Scale: 200%")
	elseif key == "3" then
		displayScale = 4
		print("Scale: 300%")
	elseif key == "4" then
		displayScale = 8
		print("Scale: 400%")
	elseif key == "5" then
		displayScale = 16
		print("Scale: 500%")
	end

	if key == "r" then
		tempMessage = ""
		reloadDev = true
		--TODO: reload native plugins too, by reinitiating all threads?
	end

	if key == "s" then
		require "ui.notice".blocking("Saving image: out.png")

		previewImage.imageData:encode("png", "out.png")
		local path = love.filesystem.getSaveDirectory( )
		os.remove("out.png")
		os.rename(path.."/out.png", "out.png")
	end

	if key == "q" then
		love.event.quit()
	end

	if key=="d" then
		--debug.see(panels.image.onAction)
	end

	if key == "`" then
		print("Scale: FIT")
		scrollable = false
		displayScale = false
		imageOffset:set(0, 0, 0, 0)
		imageOffset:set(0, 0, 1, 0)
	end

	if key == "f11" then
		fullscreen = not fullscreen
		love.window.setFullscreen(fullscreen)
	end

	loadInputImage = true
	dirtyImage = true
end

function love.resize(w, h)
	panels.ui:arrange(w, h)
	loadInputImage = true
	dirtyImage = true
end

function love.quit()
	local f = io.open("settings.lua", "w")
	f:write(serpent.dump(settings, {sortkeys = true, indent = "  ", nocode = true}))
	f:close()

	require "tools.process".save("process.lua")

	return false
end
