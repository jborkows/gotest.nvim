local loggerModule = require("gotest.core.logging")
--- @class Failure
--- @field buffor_number integer
--- @field line_number integer
---
--- @class MarkerView
--- @field showFailures fun(failures:table<Failure>)
--- @field showSuccess fun(lines:table<integer>)

local successText = "✔️"

---@class MarkerViewFactory
---@field viewFor fun(ns:integer, buffor_number:integer):MarkerView

vim.api.nvim_set_hl(0, "OkMarking", { fg = "#FF0000", bg = "#00FF00", bold = true })
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
				local failuresDto = {}

				for _, value in ipairs(failures) do
					table.insert(failuresDto, {
						bufnr = value.buffor_number,
						lnum = value.line_number,
						col = 1,
						severity = vim.diagnostic.severity.ERROR,
						source = "testing-fun",
						message = "Test failed",
						user_data = {},
					})
				end

				vim.diagnostic.set(ns, buffor_number, failuresDto, {})
				vim.notify(
					string.format("Tests in %s failed.", vim.api.nvim_buf_get_name(buffor_number)),
					vim.log.levels.ERROR
				)
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
