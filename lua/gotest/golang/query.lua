local M = {}
local core = require("gotest.core")

local test_function_query_string = [[
(

  (package_clause
    ((package_identifier) @_package))
  (function_declaration
    name: ((identifier) @_name)
    )

)

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

local query = nil
---comment
---@param buffnr integer
---@param key TestIdentifier
---@return integer|nil
M.find_test_line = function(buffnr, key)
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
		if nodeFound ~= nil and M.match(key, core.TestIdentifier:new(packageName, name)) then
			local range = { nodeFound:range() }
			return range[1]
		end
	end
end
return M
