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


assert(love.window.setMode(1280, 720, {resizable = true, vsync = true, minwidth = 800, minheight = 600, msaa = 4} ))
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
		local devices = platform:get_devices() or {}
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
local image = require "ui.image"
local thread = require "thread"
thread.init(oclPlatform, oclDevice)
data.initDev(thread.getContext(), thread.getQueue())
image.initDev(thread.getContext(), thread.getQueue())

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


local exifData
local originalImage
local RAW_SRGBmatrix
local RAW_WBmultipliers
local RAW_PREmultipliers

local imageOffset = data:new(1, 1, 13)
local previewImage

local loadInputImage = true
local dirtyImage = true
local processReady = true

function love.filedropped(file)
	require "ui.notice".blocking("Loading image: "..(type(file) == "string" and file or file:getFilename()), true)
	assert(file, "ERROR: File loading failed")

	originalImage, RAW_SRGBmatrix, RAW_WBmultipliers, RAW_PREmultipliers = require("io."..settings.imageLoader).read(file)
	originalImage:syncDev()
	if RAW_SRGBmatrix then RAW_SRGBmatrix:syncDev() end
	if RAW_WBmultipliers then RAW_WBmultipliers:syncDev() end
	if RAW_PREmultipliers then RAW_PREmultipliers:syncDev() end

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
	panels.info.elem[7].right = (exifData.ExposureCompensation and ("%+0.1f"):format(exifData.ExposureCompensation) or " -").." EV"

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
	imageOffset:set(0, 0, 2, 1) -- scale
	local A, B, C, BR, CR, VR, BB, CB, VB = require("tools.lensfun")(exifData.LensModel or exifData.CameraModelName, exifData.FocalLength)
	imageOffset:set(0, 0, 3, A)
	imageOffset:set(0, 0, 4, B)
	imageOffset:set(0, 0, 5, C)
	imageOffset:set(0, 0, 6, BR or 0)
	imageOffset:set(0, 0, 7, CR or 0)
	imageOffset:set(0, 0, 8, VR or 1)
	imageOffset:set(0, 0, 9, BB or 0)
	imageOffset:set(0, 0, 10, CB or 0)
	imageOffset:set(0, 0, 11, VB or 1)

	-- calculate distortion correction optimal scale
	do
		local s_min = math.huge
		local s_max = -math.huge

		local x = originalImage.x/2
		for y = 0, originalImage.y/2 do
			local ru = math.sqrt(x^2 + y^2) / math.sqrt((originalImage.x)/2^2 + (originalImage.y/2)^2)
			local rd = ru*(A*ru*ru*ru + B*ru*ru + C*ru + (1-A-B-C))
			local rr = ru/rd
			if rr<s_min then s_min = rr end
			if rr>s_max then s_max = rr end
		end

		local y = originalImage.y/2
		for x = 0, originalImage.x/2 do
			local ru = math.sqrt(x^2 + y^2) / math.sqrt((originalImage.x)/2^2 + (originalImage.y/2)^2)
			local rd = ru*(A*ru*ru*ru + B*ru*ru + C*ru + (1-A-B-C))
			local rr = ru/rd
			if rr<s_min then s_min = rr end
			if rr>s_max then s_max = rr end
		end

		imageOffset:set(0, 0, 12, s_min)
	end
	imageOffset:syncDev()

	pipeline.input.imageData = originalImage:new()
	pipeline.output.image = image.new(pipeline.input.imageData)

	pipeline.output.image.scale = math.min(panels.image.w / pipeline.input.imageData.x, panels.image.h / pipeline.input.imageData.y, 1)
	pipeline.output.image.drawOffset.x = (panels.image.w - pipeline.input.imageData.x * pipeline.output.image.scale) / 2
	pipeline.output.image.drawOffset.y = (panels.image.h - pipeline.input.imageData.y * pipeline.output.image.scale) / 2

	previewImage = pipeline.output.image

	loadInputImage = true
	dirtyImage = true

	require "ops.tools".imageShapeSet(pipeline.input.imageData.x, pipeline.input.imageData.y, pipeline.input.imageData.z)
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

--local correctDistortion
panels.info.elem[15].onChange = function() loadInputImage = true end
panels.info.elem[16].onChange = function() loadInputImage = true end
panels.info.elem[18].onChange = function() loadInputImage = true end
panels.info.elem[19].onChange = function() loadInputImage = true end
panels.info.elem[20].onChange = function() loadInputImage = true end
panels.info.elem[21].onChange = function() loadInputImage = true end

local flags = data:new(1, 1, 7) -- distortion, tca, vignetting, sRGB, WB, reconstruct

function love.update()

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
			if node and node.state == "waiting" then node.state = "processing" end
			currentID = id
			processComplete = processComplete + 1
		elseif code == "end" and id then
			local node = node.list[id]
			if node and node.state == "processing" then
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

	if thread.done() then
		processReady = true
		message = tempMessage

		thread.freeData() -- clean all deleted data references once processing is finished
		previewImage = pipeline.output.image:refresh() -- set to display the new output.image next

		if pipeline.output.elem[1].value then
			hist = pipeline.output.data.histogram:syncHost(true, true)
		else
			hist = false
		end

		local t2 = love.timer.getTime()
		procTime = t2 - t1
	end

	if processReady and (dirtyImage or panels.parameters.elem[5].value) then
		t1 = love.timer.getTime()

		if loadInputImage then -- load cropped image if not already cached
			rescaleInputOutput()
			imageOffset:syncDev()

			local pool = require "tools.imagePool"
			pool.resize(originalImage.x, originalImage.y)
			pool.crop(imageOffset:get(0, 0, 0), imageOffset:get(0, 0, 1), pipeline.input.imageData.x, pipeline.input.imageData.y)

			--thread.ops.cropCorrectFisheye({originalImage, input.imageData, imageOffset}, "dev")

			if panels.info.elem[15].value or panels.info.elem[16].value then
				flags:set(0, 0, 0, panels.info.elem[15].value and 1 or 0)
				flags:set(0, 0, 1, panels.info.elem[16].value and 1 or 0)
				thread.ops.cropCorrect({originalImage, pipeline.input.imageData, imageOffset, flags}, "dev")
			else
				thread.ops.crop({originalImage, pipeline.input.imageData, imageOffset}, "dev")
			end
			require "ops.tools".imageShapeSet(pipeline.input.imageData.x, pipeline.input.imageData.y, pipeline.input.imageData.z)

			if RAW_SRGBmatrix and RAW_WBmultipliers  then
				flags:set(0, 0, 3, panels.info.elem[18].value and 0 or 1)
				flags:set(0, 0, 4, panels.info.elem[19].value and 1 or 0)
				flags:set(0, 0, 5, panels.info.elem[20].value and 1 or 0)
				flags:set(0, 0, 6, panels.info.elem[21].value and 1 or 0)
				thread.ops.RAWtoSRGB({pipeline.input.imageData, RAW_SRGBmatrix, RAW_WBmultipliers, RAW_PREmultipliers, flags}, "dev")
			end

      flags:syncDev()

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
			if n.refresh and loadInputImage then
				n.dirty = true
				table.insert(outputs, n)
			end
		end

		processTotal = 1

		local dfs = nodeDFS(node, outputs)

		for k, n in ipairs(dfs) do
			if n.dirty then
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
		loadInputImage = false
		dirtyImage = false

		love.window.requestAttention() -- highlight when processing is completed
	end
end



local style = require("ui.style")

function love.draw()
	love.graphics.scale(settings.scaleUI, settings.scaleUI)

	love.graphics.clear(style.backgroundColor)

	-- update status panel
	local processor = tostring("OpenCL "..panels.parameters.elem[3].right.." / "..jit.arch.." LuaJIT")
	panels.status.leftText = string.format(
		"UI: %.1ffps | Processing: %.1fms (%s) | Memory: CPU %.1fMB, GPU %.1fMB (Temp: CPU %.1fMB, GPU %.1fMB)",
		love.timer.getFPS(), procTime * 1000, processor,
		--data.stats.data.cpu_max/1024/1024, data.stats.data.gpu_max/1024/1024,
		--data.stats.thread.cpu_max/1024/1024, data.stats.thread.gpu_max/1024/1024)
    -999, -999, -999, -999)
	--data.stats.clearCPU()
	--data.stats.clearGPU()


	panels.ui:draw()

	love.graphics.setColor(1, 1, 1, 1)
	previewImage:draw(panels.image.x, panels.image.y)

	love.graphics.setColor(style.orange)
	love.graphics.setFont(style.messageFont)
	love.graphics.print(message, math.floor(panels.image.x + 5), math.floor(panels.image.y + 5))

	-- draw histogram
	local scale = 0
  if hist then
    hist:lock()
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
    hist:unlock()

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

	require "ui.widget".drawCursor()

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




local widget = require "ui.widget"
widget.setFrame(panels.image)

function widget.imagePan(dx, dy)
	if scrollable then
		local ox, oy = imageOffset:get(0, 0, 0), imageOffset:get(0, 0, 1)
		ox = ox - dx / displayScale
		oy = oy + dy / displayScale
		imageOffset:set(0, 0, 0, ox)
		imageOffset:set(0, 0, 1, oy)
		loadInputImage = true
	end
end

function widget.imageCoord(x, y)
	x = (x - previewImage.drawOffset.x) / previewImage.scale
	y = (y - previewImage.drawOffset.y) / previewImage.scale
	y = previewImage.y - y
	x = math.round(math.clamp(x, 0, previewImage.x - 1))
	y = math.round(math.clamp(y, 0, previewImage.y - 1))
	return x, y
end

function widget.imagePos()
	local x = previewImage.drawOffset.x
	local y = previewImage.drawOffset.y
	local w = previewImage.x * previewImage.scale
	local h = previewImage.y * previewImage.scale
	return x, y, w, h
end

function widget.imageOffset()
  local ox, oy = imageOffset:get(0, 0, 0), imageOffset:get(0, 0, 1)
  local w, h = originalImage.x, originalImage.y
  return ox, oy, w, h
end

function widget.imageSize()
	local w = previewImage.x
	local h = previewImage.y
	local s = previewImage.scale
	return w, h, s
end

function widget.imageSample(x, y)
	x, y = widget.imageCoord(x, y)
	local r = previewImage:get(x, y, 0)
	local g = previewImage:get(x, y, 1)
	local b = previewImage:get(x, y, 2)
	panels.hist.panel.elem[1].name = ("R: %03d\tG: %03d\tB: %03d"):format(r, g, b)
	panels.hist.panel.elem[1].value[1] = r / 255
	panels.hist.panel.elem[1].value[2] = g / 255
	panels.hist.panel.elem[1].value[3] = b / 255
end

widget.imagePanTool(panels.toolbox.elem[1])
widget.colorSampleTool(panels.toolbox.elem[2])

for k, v in pairs(widget.exclusive) do
	v.value = false
end
panels.toolbox.elem[1].value = true
panels.toolbox.elem[1]:onChange()

panels.image.onContext = overlay.show -- register node-add menu


local uiInput = require "ui.input"
local mousePressed = false

function love.mousemoved(x, y, dx, dy)
	uiInput.mouseMoved(x / settings.scaleUI, y / settings.scaleUI, dx / settings.scaleUI, dy / settings.scaleUI)

	if not mousePressed then
		if uiInput.mouseOverFrame(widget.frame) then
			widget.enable()
		else
			widget.disable()
		end
	end

	if love.mouse.isDown(1) then
		dirtyImage = true
	end
end

function love.mousepressed(x, y, button, isTouch)
	if not mousePressed then
		if uiInput.mouseOverFrame(widget.frame) then
			widget.enable()
		else
			widget.disable()
		end
	end

	mousePressed = true
	uiInput.mousePressed(x / settings.scaleUI, y / settings.scaleUI, button)
	dirtyImage = true
	cycles = {} -- clear cycle indication
end

function love.mousereleased(x, y, button, isTouch)
	mousePressed = false
	uiInput.mouseReleased(x / settings.scaleUI, y / settings.scaleUI, button)
	cycles = nodeDFS(node) -- populate cycle indication
	dirtyImage = true

	if uiInput.mouseOverFrame(widget.frame) then
		widget.enable()
	else
		widget.disable()
	end
end

function love.wheelmoved(x, y)
	if uiInput.mouseOverFrame(widget.frame) or widget.active then
		dirtyImage = dirtyImage or widget.wheelmoved(x, y)
	end
end

function pipeline.update()
  dirtyImage = true
end

local fullscreen = false
function love.keyreleased(key)
	if uiInput.mouseOverFrame(widget.frame) then
		widget.enable()
	else
		widget.disable()
	end
end

function love.keypressed(key)
	if uiInput.mouseOverFrame(widget.frame) then
		widget.enable()
	else
		widget.disable()
	end

	if key == "1" then
		displayScale = 1
		print("Scale: 100%")
	elseif key == "2" then
		displayScale = 2
		print("Scale: 200%")
	elseif key == "3" then
		displayScale = 4
		print("Scale: 400%")
	elseif key == "4" then
		displayScale = 8
		print("Scale: 800%")
	elseif key == "5" then
		displayScale = 16
		print("Scale: 1600%")
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
		-- document mode
		local nodeAddOverlay = require "ui.panels.nodeAddMenu"

		debug.see(nodeAddOverlay)

		pipeline.input:setPos(-200, 6)
		pipeline.output:setPos(400, 6)

		local function getNodes(t)
			for k, v in ipairs(t.elem) do
				if v.action then

					if pipeline.input.portOut[0].link then
						pipeline.input.portOut[0].link:remove()
					end

					local n = v.action(13, 6)

					local w, h -- calculate node size
					do
						local nodeWidth = n.w or style.nodeWidth
						local nodeHeight = style.titleHeight + style.elemHeight * n.elem.n - (n.elem.n == 0 and style.nodeBorder or style.elemBorder)
						if n.graph then
							nodeHeight = nodeHeight + n.graph.h + style.nodeBorder
						end
						local left = next(n.portIn)
						local right = next(n.portOut)
						w = nodeWidth + style.nodeBorder * 2 + style.elemHeight
						h = nodeHeight + style.nodeBorder * 2
					end

					local c = love.graphics.newCanvas(w + 8, h + 8, {msaa = 16})
					love.graphics.setCanvas(c)
					love.graphics.clear(style.backgroundColor)
					love.graphics.setColor(1, 1, 1, 1)

					if n.portIn[0] then
						local l = link:connect(pipeline.input.portOut[0], n.portIn[0])
						l.data = true
						l:draw()
					end
					if n.portOut[0] then
						local l = link:connect(n.portOut[0], pipeline.output.portIn[0])
						l.data = true
						l:draw()
					end
					n:draw()

					love.graphics.setCanvas()

					love.graphics.draw(c, 0, 0)
					local d = c:newImageData()
					d:encode("png", "testdoc.png")
					local path = love.filesystem.getSaveDirectory( )
					assert(os.rename(path.."/testdoc.png", "doc/nodes/"..table.concat(n.call, "-")..".png"))

					love.graphics.present()
					n:remove()
				end
				if v.frame then
					getNodes(v.frame)
				end
			end
		end

		getNodes(nodeAddOverlay)
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
