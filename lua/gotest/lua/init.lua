local M = {}
local parser = require("gotest.lua.parser")
local query = require("gotest.lua.queries")
local core = require("gotest.core")

---comment
---@param t1 TestIdentifier
---@param t2 TestIdentifier
---@return boolean
local function match(t1, t2)
	return t1.testName == t2.testName and string.match(t1.packageName, t2.packageName .. "$") ~= nil
end

---comment
---@param t1 TestIdentifier
---@param t2 TestIdentifier
---@return boolean
M.match = function(t1, t2)
	return match(t1, t2) or match(t2, t1)
end
---comment
---@param test_package_prefix string
---@return Parser
M.parser = function(test_package_prefix)
	return parser.parser(test_package_prefix)
end

---comment
---@param bufnr integer
---@param key TestIdentifier
---@return integer|nil
M.find = function(bufnr, key)
	local buffor_name = vim.api.nvim_buf_get_name(bufnr)
	local normalized_name = core.removeSuffix(core.removePrefix(core.relative(buffor_name), "/tests/"), ".lua")
	if key.packageName ~= normalized_name then
		return nil
	end
	return query.find_test_line(bufnr, key)
end
M.command = { "make", "tests" }

local ns = vim.api.nvim_create_namespace("lua-live-test")
local group = vim.api.nvim_create_augroup("lua-live-test_au", { clear = true })

---comment
---@param states table<TestIdentifier,State>
---@param buffers table<string,number>
local displayResults = function(states, buffers)
	local failed = {}
	local success = {}
	print(vim.inspect(buffers))
	print(vim.inspect(states))
	for key, singleState in pairs(states) do
		if buffers[key.packageName] == nil then
			goto finish
		end

		local file_buffer_no = buffers[key.packageName]
		local found_line = query.find_test_line(file_buffer_no, key)

		print("For " .. vim.inspect(key) .. " found line" .. found_line)
		if found_line == nil then
			goto finish
		end
		if singleState == "success" then
			if success[file_buffer_no] == nil then
				success[file_buffer_no] = {}
			end

			table.insert(success[file_buffer_no], found_line)
			goto finish
		end
		if singleState == "failure" then
			if failed[file_buffer_no] == nil then
				failed[file_buffer_no] = {}
			end
			table.insert(failed[file_buffer_no], {
				bufnr = file_buffer_no,
				lnum = found_line,
				col = 1,
				severity = vim.diagnostic.severity.ERROR,
				source = "testing-fun",
				message = "Test failed",
				user_data = {},
			})
			goto finish
		end

		::finish::
	end

	local text = { "✔️" }
	print(vim.inspect(success))
	for buffer_no, lines in pairs(success) do
		for _, line in ipairs(lines) do
			xpcall(function()
				vim.api.nvim_buf_set_extmark(buffer_no, ns, line, 0, { virt_text = { text } })
			end, core.myerrorhandler)
		end
	end

	for buffer_no, failures in pairs(failed) do
		vim.diagnostic.set(ns, buffer_no, failures, {})
	end
	if table.maxn(failed) > 0 then
		vim.notify("Test failed", vim.log.levels.ERROR)
	end
end

M.setup = function()
	local bufferNum = {}
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = group,
		pattern = "*.lua",
		callback = function()
			local buffnr = vim.api.nvim_get_current_buf()
			local buffor_name = vim.api.nvim_buf_get_name(buffnr)
			if core.endsWith(buffor_name, "_spec.lua") then
				local normalized_name =
				    core.removeSuffix(core.removePrefix(core.relative(buffor_name), "/tests/"), ".lua")
				bufferNum[normalized_name] = buffnr
				vim.api.nvim_buf_clear_namespace(buffnr, ns, 0, -1)
			end
			local aParser = M.parser(core.projectPath("tests/"))

			local state = core.state
			state.setup()
			vim.fn.jobstart(M.command, {
				stdout_buffered = true,
				on_stderr = function(_, data) end,
				on_stdout = function(_, data)
					if not data then
						return
					end -- if data are present append lines starting from end of file (-1) to end of file (-1)
					xpcall(function()
						for _, line in ipairs(data) do
							local parsed = aParser.parse(line)
							state.onParsing(parsed)
						end
					end, core.myerrorhandler)
				end,
				on_exit = function()
					displayResults(state.states(), bufferNum)
				end,
			})
		end,
	})
end

return M
