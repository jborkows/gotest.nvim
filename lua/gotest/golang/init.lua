local M = {}
local parser = require("gotest.golang.parser")
local core = require("gotest.core")
local query = require("gotest.golang.query")

---comment
---@param t1 TestIdentifier
---@param t2 TestIdentifier
---@return boolean
M.match = query.match

local __Config = {
	command = { "go", "test", "./...", "-v", "-race", "-shuffle=on", "-json" },
}

M.TestCommand = function(cmd)
	return function(config)
		config.command = cmd
	end
end

-- @param ... function[]
M.setup = function(functions)
	for _, plugin in ipairs(functions) do
		plugin(__Config)
	end

	core.initializeMarker({
		pattern = "*.go",
		bufforNameProcessor = function(buffor_name)
			return buffor_name
		end,
		parserProvider = function()
			return parser
		end,
		testCommand = __Config.command,
		findTestLine = query.find_test_line,
	})
end

M.parse = parser.parse
return M
