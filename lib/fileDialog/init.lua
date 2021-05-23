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

-- gcc -shared tinyfiledialogs.c -o tfd.dll -lcomdlg32 -lole32


local ffi = require "ffi"

local fileDialog = {}

local tfd
local libraw
if ffi.os=="Windows" then
	tfd = ffi.load("lib/fileDialog/Windows/tfd.dll")
elseif ffi.os=="Linux" then
	tfd = ffi.load("lib/fileDialog/Linux/libtfd.so")
end

ffi.cdef[[
	int tinyfd_winUtf8;

	char const * tinyfd_openFileDialog(
		char const * const aTitle , /* NULL or "" */
		char const * const aDefaultPathAndFile , /* NULL or "" */
		int aNumOfFilterPatterns , /* 0 */
		char ** aFilterPatterns , /* NULL | {"*.jpg","*.png"} */
		char const * const aSingleFilterDescription , /* NULL | "image files" */
		int aAllowMultipleSelects ) ; /* 0 or 1 */
			/* in case of multiple files, the separator is | */
			/* returns NULL on cancel */

	char * const tinyfd_saveFileDialog(
		char const * const aTitle , /* NULL or "" */
		char const * const aDefaultPathAndFile , /* NULL or "" */
		int aNumOfFilterPatterns , /* 0 */
		char ** aFilterPatterns , /* NULL | {"*.jpg","*.png"} */
		char const * const aSingleFilterDescription ) ; /* NULL | "text files" */
			/* returns NULL on cancel */
]]

if ffi.os=="Windows" then
	tfd.tinyfd_winUtf8 = 1
end

function fileDialog.fileOpen(title, path, filter, description)
	if type(filter)=="string" then filter = {filter} end

	local filterList
	if type(filter)=="table" then
		filterList = ffi.new("char*[?]", #filter)

		for k, v in ipairs(filter) do
			filter[k] = ffi.new("char[?]", #v, v) -- anchor filters in original array
			filterList[k-1] = filter[k]
		end
	end

	local str = tfd.tinyfd_openFileDialog(
		title,
		path,
		type(filter)=="table" and #filter or 0,
		filterList,
		description,
		0)
	return str~=NULL and ffi.string(str) or nil
end

function fileDialog.fileSave(title, path, filter, description)
	if type(filter)=="string" then filter = {filter} end

	local filterList
	if type(filter)=="table" then
		filterList = ffi.new("char*[?]", #filter)

		for k, v in ipairs(filter) do
			filter[k] = ffi.new("char[?]", #v, v) -- anchor filters in original array
			filterList[k-1] = filter[k]
		end
	end

	local str = tfd.tinyfd_saveFileDialog(
		title,
		path,
		type(filter)=="table" and #filter or 0,
		filterList,
		description)
	return str~=NULL and ffi.string(str) or nil
end

return fileDialog
