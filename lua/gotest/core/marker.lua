local loggerModule = require("gotest.core.logging")
local lazyDebug = loggerModule.lazyDebug
local M = {}

---@param find_test_line fun( buffers:table<string,number>,key: TestIdentifier):integer|nil
---@return integer|nil
local find_buffer = function(buffers, key)
	if buffers[key.packageName] ~= nil then
		return buffers[key.packageName]
	end
	for name, value in pairs(buffers) do
		if string.match(name, key.packageName) then
			return value
		end
		if string.match(key.packageName, name) then
			return value
		end
	end
end

---comment
---@param find_test_line fun(bufnr:number,key: TestIdentifier):integer|nil
---@return fun(states:table<TestIdentifier,State>,buffers:table<string,number>)
M.displayResults = function(find_test_line)
	return function(states, buffers)
		local failed = {}
		local success = {}
		lazyDebug(function()
			return "Found buffers: " .. vim.inspect(buffers)
		end)
		lazyDebug(function()
			return "Found states: " .. vim.inspect(states)
		end)
		for key, singleState in pairs(states) do
			local file_buffer_no = find_buffer(buffers, key)
			if file_buffer_no == nil then
				goto finish
			end

			local found_line = find_test_line(file_buffer_no, key)

			if found_line == nil then
				lazyDebug(function()
					return "For " .. vim.inspect(key) .. "cannot find line"
				end)
				goto finish
			end

			lazyDebug(function()
				return "For " .. vim.inspect(key) .. " found line" .. found_line
			end)
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
		lazyDebug(function()
			return "Found success: " .. vim.inspect(success)
		end)
		for buffer_no, lines in pairs(success) do
			for _, line in ipairs(lines) do
				xpcall(function()
					vim.api.nvim_buf_set_extmark(buffer_no, M._ns, line, 0, { virt_text = { text } })
				end, loggerModule.myerrorhandler)
			end
		end

		for buffer_no, failures in pairs(failed) do
			vim.diagnostic.set(M._ns, buffer_no, failures, {})
		end
		if table.maxn(failed) > 0 then
			vim.notify("Test failed", vim.log.levels.ERROR)
		end
	end
end
M.setup = function(ns, group)
	M._group = group
	M._ns = ns
end
return M
