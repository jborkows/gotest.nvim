local core = require("gotest.core")
local paths = require("gotest.core.paths")
local strings = require("gotest.core.strings")
local M = {}

local test_function_query_string = [[
(

  (function_call
    name: ((identifier) @_describename)
    arguments: (arguments
      (string
        content: ((string_content) @_describe))
      (function_definition
        parameters: (parameters)
        body: (block

	 ((
	  function_call
	  name: (identifier) @_it
	  arguments: (arguments
		       (string
		content: ((string_content) @_name))
			)

	 ) @_function)
	)
      )
      )
  )
	(#eq? @_describename "describe")

(#eq? @_it "it")
	)



]]

local query = vim.treesitter.query.parse("lua", test_function_query_string)
---comment
---@param buffnr integer
---@param key TestIdentifier
---@return integer|nil
M.find_test_line = function(buffnr, key)
	local tsparser = vim.treesitter.get_parser(buffnr, "lua", {})
	local tree = tsparser:parse()[1]
	local root = tree:root()

	for _, match, metadata in query:iter_matches(root, buffnr) do
		local name = ""
		local describe = ""
		local nodeFound = nil
		for id, node in pairs(match) do
			local capture_name = query.captures[id] -- Get the capture name
			if capture_name == "_name" then -- Check if this is the capture we're interested in
				name = vim.treesitter.get_node_text(node, buffnr)
				nodeFound = node
			end
			if capture_name == "_describe" then
				describe = vim.treesitter.get_node_text(node, buffnr)
			end
		end
		if key.testName == describe .. " " .. name then
			local range = { nodeFound:range() }
			return range[1]
		end
	end
end

---comment
---@param line integer
---@param column integer
---@return TestIdentifier|nil
M.findTestKey = function(line, column)
	local parsers = require("nvim-treesitter.parsers")
	local current_buf = vim.api.nvim_get_current_buf()
	if not parsers.has_parser() then
		return
	end
	local root_tree = parsers.get_parser(current_buf):parse()[1]
	local root = root_tree:root()

	for _, match, _ in query:iter_matches(root, current_buf) do
		local name = ""
		local describe = ""
		local nodeFound = nil
		for id, node in pairs(match) do
			local capture_name = query.captures[id] -- Get the capture name
			if capture_name == "_name" then -- Check if this is the capture we're interested in
				name = vim.treesitter.get_node_text(node, current_buf)
			elseif capture_name == "_describe" then
				describe = vim.treesitter.get_node_text(node, current_buf)
			elseif capture_name == "_function" then
				nodeFound = node
			end
		end
		local testName = describe .. " " .. name

		if nodeFound ~= nil and vim.treesitter.is_in_node_range(nodeFound, line - 1, column) then
			local fileName = vim.api.nvim_buf_get_name(current_buf)
			local projectFile = paths.relative(fileName)
			local noLua = strings.removeSuffix(projectFile, ".lua")
			return core.TestIdentifier:new(noLua, testName)
		end
	end
	return nil
end
return M
