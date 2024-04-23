local M = {}
local parser = require("gotest.lua.parser")
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

local test_function_query_string = [[
(
 (
  function_call
  name: (identifier) @_it
  arguments: (arguments
	       (string
content: ((string_content) @_name))
		)

	)
(#eq? @_it "it")
(#eq? @_name "%s")

 )

]]

---comment
---@param buffnr integer
---@param key TestIdentifier
---@return integer|nil
local find_test_line = function(buffnr, key)
	local name = key.testName
	local formatted = string.format(test_function_query_string, name)
	local query = vim.treesitter.query.parse("lua", formatted)
	local tsparser = vim.treesitter.get_parser(buffnr, "lua", {})
	local tree = tsparser:parse()[1]
	local root = tree:root()
	for id, node in query:iter_captures(root, buffnr, 0, -1) do
		if id == 1 then
			local range = { node:range() }
			return range[1]
		end
	end
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
	return find_test_line(bufnr, key)
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
	for key, singleState in pairs(states) do
		if buffers[key.packageName] == nil then
			goto finish
		end

		local file_buffer_no = buffers[key.packageName]
		local found_line = M.find(file_buffer_no, key)
		if found_line == nil then
			goto finish
		end
		if singleState == "success" then
			if success[file_buffer_no] ~= nil then
				success[file_buffer_no] = {}
			end
			table.insert(success[file_buffer_no], found_line)
			goto finish
		end
		if singleState == "failure" then
			if failed[file_buffer_no] ~= nil then
				failed[file_buffer_no] = {}
			end
			table.insert(failed[file_buffer_no], {
				bufnr = file_buffer_no,
				lnum = found_line,
				col = 0,
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
end

M.setup = function()
	local bufferNum = {}
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = group,
		pattern = "*.lua",
		callback = function()
			local buffnr = vim.api.nvim_get_current_buf()
			local buffor_name = vim.api.nvim_buf_get_name(buffnr)
			if core.endsWith(buffor_name, ".spec.lua") then
				local normalized_name =
				    core.removeSuffix(core.removePrefix(core.relative(buffor_name), "/tests/"), ".lua")
				bufferNum[normalized_name] = buffnr
				vim.api.nvim_buf_clear_namespace(buffnr, ns, 0, -1)
			end
			local aParser = M.parser(core.projectPath("tests/"))

			local state = core.state
			vim.fn.jobstart(M.command, {
				stdout_buffered = true,
				on_stderr = function(_, data) end,
				on_stdout = function(_, data)
					if not data then
						return
					end -- if data are present append lines starting from end of file (-1) to end of file (-1)
					for _, line in ipairs(data) do
						local parsed = aParser.parse(line)
						state.onParsing(parsed)
					end
				end,
				on_exit = function()
					displayResults(state.states(), bufferNum)
				end,
			})
		end,
	})
end

return M
