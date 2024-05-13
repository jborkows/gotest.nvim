local M = {}
local core = require("gotest.core")
local paths = require("gotest.core.paths")
local strings = require("gotest.core.strings")

local test_function_query_string = [[

(
  (package_clause
    ((package_identifier) @_package))
  ((function_declaration
    name: ((identifier) @_name)
    )
) @_function)

]]

---@param t1 TestIdentifier
---@param t2 TestIdentifier
---@return boolean
local match = function(t1, t2)
	return t1.testName == t2.testName and string.match(t1.packageName, t2.packageName .. "$") ~= nil
end

---comment
---@param t1 TestIdentifier
---@param t2 TestIdentifier
---@return boolean
M.match = function(t1, t2)
	return match(t1, t2) or match(t2, t1)
end

local _query = nil

local function queryProvider()
	if _query == nil then
		_query = vim.treesitter.query.parse("go", test_function_query_string)
	end
	return _query
end

local packageQuery = nil
---comment
---@param buffnr integer
---@param key TestIdentifier
---@return integer|nil
M.find_test_line = function(buffnr, key)
	local query = queryProvider()
	local tsparser = vim.treesitter.get_parser(buffnr, "go", {})
	local tree = tsparser:parse()[1]
	local root = tree:root()

	for _, found, metadata in query:iter_matches(root, buffnr) do
		local name = ""
		local packageName = ""
		local nodeFound = nil
		for id, node in pairs(found) do
			local capture_name = query.captures[id] -- Get the capture name
			if capture_name == "_name" then -- Check if this is the capture we're interested in
				name = vim.treesitter.get_node_text(node, buffnr)
				nodeFound = node
			end
			if capture_name == "_package" then
				packageName = vim.treesitter.get_node_text(node, buffnr)
			end
		end
		if nodeFound ~= nil and M.match(key, core.TestIdentifier:new(packageName, name)) then
			local range = { nodeFound:range() }
			return range[1]
		end
	end
end

---@param buffnr integer
---@return string|nil
M.package_name_query = function(buffnr)
	if query == nil then
		query = vim.treesitter.query.parse("go", test_function_query_string)
	end
	local tsparser = vim.treesitter.get_parser(buffnr, "go", {})
	local tree = tsparser:parse()[1]
	local root = tree:root()

	for _, found, metadata in query:iter_matches(root, buffnr) do
		local name = ""
		local packageName = ""
		local nodeFound = nil
		for id, node in pairs(found) do
			local capture_name = query.captures[id] -- Get the capture name
			if capture_name == "_name" then -- Check if this is the capture we're interested in
				name = vim.treesitter.get_node_text(node, buffnr)
				nodeFound = node
			end
			if capture_name == "_package" then
				packageName = vim.treesitter.get_node_text(node, buffnr)
			end
		end
		if nodeFound ~= nil and core.startsWith(name, "Test") then
			return packageName
		end
	end
end

local packagePrefix = nil
M.initializePrefix = function()
	local filename = paths.relative("go.mod")

	local file = io.open(filename, "r")
	if file == nil then
		return
	end
	for line in file:lines() do
		if strings.startsWith(line, "module") then
			packagePrefix = strings.removePrefix(line, "module ")
			goto finish
		end
	end
	::finish::
	file:close()
end

---comment
---@param line integer
---@param column integer
---@return TestIdentifier|nil
M.findTestKey = function(line, column)
	local parsers = require("nvim-treesitter.parsers")
	local current_buf = vim.api.nvim_get_current_buf()
	if not parsers.has_parser() then
		print("Return")
		return
	end
	local root_tree = parsers.get_parser(current_buf):parse()[1]
	local root = root_tree:root()
	local query = queryProvider()

	for _, found, _ in query:iter_matches(root, current_buf) do
		local item = {}
		for id, node in pairs(found) do
			local entry = query.captures[id]
			if entry == "_name" then
				local name = vim.treesitter.get_node_text(node, current_buf)
				item["testName"] = name
			elseif entry == "_function" then
				item["functionblock"] = node
			elseif entry == "_package" then
				local packageName = vim.treesitter.get_node_text(node, current_buf)
				if packagePrefix ~= nil then
					local fileName = vim.api.nvim_buf_get_name(current_buf)
					if string.find(fileName, "/internal/") ~= nil then
						packageName = packagePrefix .. "/internal/" .. packageName
					else
						packageName = packagePrefix .. "/" .. packageName
					end
				end
				item["packageName"] = packageName
			end
		end

		if vim.treesitter.is_in_node_range(item.functionblock, line - 1, column) then
			local packageName = item["packageName"]

			return core.TestIdentifier:new(packageName, item["testName"])
		end
	end
	return nil
end

return M
