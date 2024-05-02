local M = {}
local function is_plugin_installed(name)
	local present, _ = pcall(require, name)
	return present
end
-- Function to check if TS grammar for a language is installed
local function is_ts_language_installed(lang)
	local ts = require("nvim-treesitter.install")
	local installed = ts.is_installed(lang)
	return installed
end
---checks if Treesitter language is installed and installs it if it is not there
---@param languageName string
M.checkLanguage = function(languageName)
	if is_plugin_installed("nvim-treesitter") == nil then
		print("Nvim treesitter is not installed!")
		return
	end

	if not is_ts_language_installed(languageName) then
		vim.api.nvim_command("TSInstall " .. languageName)
	end
end
-- Install TS grammar for Go if nvim-treesitter is installed and Go isn't installed
return M
