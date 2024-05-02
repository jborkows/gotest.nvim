local M = {}
local function is_plugin_installed(name)
	local present, _ = pcall(require, name)
	return present
end
---checks if Treesitter language is installed and installs it if it is not there
---@param languageName string
M.checkLanguage = function(languageName)
	if is_plugin_installed("nvim-treesitter") == false then
		print("Nvim treesitter is not installed!")
		return
	end

	vim.api.nvim_command("TSUpdate " .. languageName)
end
return M
