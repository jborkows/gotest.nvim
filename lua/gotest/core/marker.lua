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
---@param ns
---@param viewFactory
---@param find_test_line fun(bufnr:number,key: TestIdentifier):integer|nil
---@return fun(states:table<TestIdentifier,State>,buffers:table<string,number>)
M.displayResults = function(ns, viewFactory, find_test_line)
	return function(states, buffers)
		--- @type table<integer,table<Failure>>
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
				})
				goto finish
			end

			::finish::
		end

		lazyDebug(function()
			return "Found success: " .. vim.inspect(success)
		end)
		for buffer_no, lines in pairs(success) do
			local view = viewFactory.viewFor(ns, buffer_no)
			view.showSuccess(lines)
		end

		for buffer_no, failures in pairs(failed) do
			local view = viewFactory.viewFor(ns, buffer_no)
			view.showFailures(failures)
		end
	end
end
return M
