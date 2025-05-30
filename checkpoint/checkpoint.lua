-- https://github.com/klaleus/library-defold-checkpoint

local m_checkpoint = {}

--------------------------------------------------------------------------------
-- Lincense
--------------------------------------------------------------------------------

-- Copyright (c) 2025 Klaleus
-- 
-- This software is provided "as-is", without any express or implied warranty.
-- In no event will the authors be held liable for any damages arising from the use of this software.
-- 
-- Permission is granted to anyone to use this software for any purpose, including commercial applications,
-- and to alter it and redistribute it freely, subject to the following restrictions:
-- 
--     1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software.
--        If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
-- 
--     2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
-- 
--     3. This notice may not be removed or altered from any source distribution.

--------------------------------------------------------------------------------
-- Private Variables
--------------------------------------------------------------------------------

local _project_title = sys.get_config_string("project.title")

--------------------------------------------------------------------------------
-- Private Functions
--------------------------------------------------------------------------------

local function has_json_extension(path)
	local result = string.match(path, "%.json$")
	return result and true or false
end

-- "my/path/is/long.json" -> { "my", "path", "is", "long.json" }
local function get_path_components(path)
	local components = {}
	
	-- Maintain two indices, which denote the first and last characters of the current component.
	local name_index = 1
	local separator_index = string.find(path, "/")
	
	-- If an upcoming separator exists, then the current component is a directory.
	while separator_index do
		local directory_name = string.sub(path, name_index, separator_index - 1)
		components[#components + 1] = directory_name
		name_index = separator_index + 1
		separator_index = string.find(path, "/", name_index)
	end
	
	-- Remainder of the path is the file name and file extension.
	local file_name = string.sub(path, name_index)
	components[#components + 1] = file_name
	
	return components
end

-- "my/path/is/long.json" -> Create directories "my", "path", and "is".
local function create_directories(path)
	-- Strategy is to build the absolute path string component by component.
	-- The absolute path to the root save directory is guarenteed to already exist,
	-- so we tack on the remaining components and create them if they don't exist.
	local absolute_path = sys.get_save_file(_project_title, "")
	local path_components = get_path_components(path)

	-- Consider each directory individually.
	-- The last component is the file name, which should be skipped.
	for i = 1, #path_components - 1 do
		local directory_name = path_components[i]
		absolute_path = absolute_path .. directory_name .. "/"

		local attributes = lfs.attributes(absolute_path)
		if not attributes then
			
			local success, err = lfs.mkdir(absolute_path)
			if not success then
				return false, err
			end
		end
	end
end

local function write_json(path, data)
	local success, err = create_directories(path)
	if not success then
		return false, err
	end

	local absolute_path = sys.get_save_file(_project_title, path)
	local file, err = io.open(absolute_path, "w")
	if not file then
		return false, err
	end

	local text = json.encode(data)
	local success, err = file.write(file, text)
	if not success then
		file.close(file)
		return false, err
	end

	-- Save the file immediately, rather than waiting for the OS to schedule it.
	-- Otherwise, `m_checkpoint.read()` will return outdated data if called too quickly.
	file.flush(file)
	file.close(file)

	return true
end

-- Handles all file types except those which have specialized functions, such as `write_json()`.
-- Note that this is the only valid function for saving data that contains Defold structures, such as `vmath.vector3()`.
local function write_native(path, data)
	local success, err = create_directories(path)
	if not success then
		return false, err
	end

	local absolute_path = sys.get_save_file(_project_title, path)
	if not sys.save(absolute_path, data) then
		return false, "Failed to save file: " .. path
	end

	return true
end

local function read_json(path)
	local absolute_path = sys.get_save_file(_project_title, path)
	local file, err = io.open(absolute_path, "r")
	if not file then
		return false, err
	end

	local text = file.read(file, "*a")
	file.close(file)
	if not text then
		return false, "Failed to read file: " .. path
	end

	local success, data = pcall(json.decode, text)
	if not success then
		return false, data
	end
	
	return data
end

local function read_native(path)
	local absolute_path = sys.get_save_file(_project_title, path)
	local success, data = pcall(sys.load, absolute_path)
	if not success then
		return false, data
	end
	
	return data
end

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

--
-- Checks if a file exists.
--
-- This function is useful when deciding whether to read data from a file,
-- or use default data if there's no file to read from.
--
-- `path`: Relative path from the root save directory.
--
-- Returns a boolean.
--
-- ```
-- if m_checkpoint.exists("settings.json") then
--     local data, err = m_checkpoint.read("settings.json")
--     -- configure settings via `data`
-- else
--     local success, err = m_checkpoint.write("settings.json", default_data)
--     -- configure settings via `default_data`
-- end
-- ```
--
function m_checkpoint.exists(path)
	local absolute_path = sys.get_save_file(_project_title, path)
	local mode = lfs.attributes(absolute_path, "mode")
	return mode == "file"
end

--
-- Writes data to a file.
--
-- If the file doesn't exist, then it will be created, along with its entire directory hierarchy.
--
-- Note that Defold structures like `vmath.vector3()` are only compatible with binary file types.
-- If you'd like to write one of these structures to a file, then consider breaking it down into primitives.
--
-- `path`: Relative path from the root save directory.
-- `data`: Data table.
--
-- Returns `true` on success.
-- Returns `false` and an error string on failure.
--
-- ```
-- local data =
-- {
--     age = 27,
--     favorite_season = "winter",
--
--     -- In the case of `.myformat`, `vmath.vector3()` is okay.
--     coordinates = vmath.vector3(4, 7, 4)
-- }
-- local success, err = m_checkpoint.write("profiles/klaleus/bio.myformat", data)
-- ```
--
-- ```
-- local data =
-- {
--     age = 27,
--     favorite_season = "winter",
--
--     -- In this case of `.json`, `vmath.vector3()` must be broken down into primitives.
--     coordinates_x = 4,
--     coordinates_y = 7,
--     coordinates_z = 4
-- }
-- local success, err = _checkpoint.write("profiles/klaleus/bio.json", data)
-- ```
--
function m_checkpoint.write(path, data)
	if has_json_extension(path) then
		return write_json(path, data)
	end
	return write_native(path, data)
end

--
-- Reads data from a file.
--
-- `path`: Relative path from the root save directory.
--
-- Returns a table on success.
-- Returns `false` and an error string on failure.
--
-- ```
-- local data, err = m_checkpoint.read("settings.json")
-- ```
--
function m_checkpoint.read(path)
	-- Check if the file exists here instead of waiting for the corresponding `read()` function to return an error code.
	-- This allows us to return a "does not exist" string, rather than a less descriptive string from `io.open()`.
	if not m_checkpoint.exists(path) then
		return false, "File does not exist: " .. path
	end

	if has_json_extension(path) then
		return read_json(path)
	end
	return read_native(path)
end

return m_checkpoint