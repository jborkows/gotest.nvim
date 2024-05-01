local M = {}

local errorHandler = require("gotest.core.logging").myerrorhandler
local lazyDebug = require("gotest.core.logging").lazyDebug
M._lines = {}
---comment
---@param lines table<string>
M.keepResult = function(lines)
	M._lines = lines
end
M._show = function()
	-- Create a new buffer that is not listed, scratch, and in readonly mode
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
	-- Define the floating window's size and position
	local width = vim.api.nvim_get_option_value("columns", {}) - 20
	local height = vim.api.nvim_get_option_value("lines", {}) - 10
	local col = 10
	local row = 5
	-- Define the floating window's configuration
	local opts = {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
	}
	local lines = {}
	if table.maxn(M._lines) > 0 then
		for _, value in pairs(M._lines) do
			for line in string.gmatch(value, "([^\n]+)") do
				table.insert(lines, line)
			end
		end
	else
		lines = { "No test data available 😔" }
	end
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	local win = vim.api.nvim_open_win(buf, true, opts)

	vim.api.nvim_buf_set_keymap(buf, "n", "<ESC>", "", {
		noremap = true,
		silent = true,
		callback = function()
			local ok, _ = xpcall(function()
				vim.api.nvim_win_close(win, false)
			end, errorHandler)
			lazyDebug(function()
				if ! ok then
					return "Failed closing window"
				end
			end)
		end,
	})
end

M.setup = function()
	vim.api.nvim_create_user_command("TestResults", function()
		M._show()
	end, {})
end
return M
