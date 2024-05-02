local loggerModule = require("gotest.core.logging")
--- @class Failure
--- @field buffor_number integer
--- @field line_number integer
---
--- @class MarkerView
--- @field showFailures fun(failures:table<Failure>)
--- @field showSuccess fun(lines:table<integer>)

local successText = "✔️"
local failureText = "Failed ❌"

---@class MarkerViewFactory
---@field viewFor fun(ns:integer, buffor_number:integer):MarkerView

vim.api.nvim_set_hl(0, "OkMarking", { fg = "#00FF00", bold = false })
vim.api.nvim_set_hl(0, "FailureMarking", { fg = "#FF0000", bold = false })
local M = {

	---comment
	---@param ns integer
	---@param buffor_number integer
	---@return MarkerView
	viewFor = function(ns, buffor_number)
		local view = {
			---@param failures table<Failure>
			showFailures = function(failures)
				if table.maxn(failures) < 1 then
					return
				end

				for _, value in ipairs(failures) do
					xpcall(function()
						vim.api.nvim_buf_set_extmark(
							buffor_number,
							ns,
							value.line_number,
							0,
							{ virt_text = { { failureText, "FailureMarking" } } }
						)
					end, loggerModule.myerrorhandler)
				end

				print(string.format("Tests in %s failed.", vim.api.nvim_buf_get_name(buffor_number)))
			end,
			---comment
			---@param lines table<integer>
			showSuccess = function(lines)
				for _, line in ipairs(lines) do
					xpcall(function()
						vim.api.nvim_buf_set_extmark(
							buffor_number,
							ns,
							line,
							0,
							{ virt_text = { { successText, "OkMarking" } } }
						)
					end, loggerModule.myerrorhandler)
				end
			end,
		}
		return view
	end,
}

return M
