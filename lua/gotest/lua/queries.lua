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

	 (
	  function_call
	  name: (identifier) @_it
	  arguments: (arguments
		       (string
		content: ((string_content) @_name))
			)

	 )
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
	local name = key.testName
	-- local formatted = string.format(test_function_query_string, name)
	-- local query = vim.treesitter.query.parse("lua", formatted)
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
return M
