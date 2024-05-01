local M = {}
local strings = require("gotest.core.strings")

local function find_project_root()
	-- full path of directory
	local current_file = vim.fn.expand("%:p:h")
	while current_file ~= "/" and not vim.loop.fs_stat(current_file .. "/.git") do
		current_file = vim.fn.fnamemodify(current_file, ":h")
	end
	if current_file == "/" then
		return ""
	else
		return current_file
	end
end

local project_root = find_project_root()
---@param path string
---@return string
M.relative = function(path)
	return strings.removePrefix(path, project_root)
end

---comment
---@param relativePath string
---@return string
M.projectPath = function(relativePath)
	return project_root .. "/" .. relativePath
end
return M
