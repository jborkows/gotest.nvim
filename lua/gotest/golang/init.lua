local M = {}
local parser = require("gotest.golang.parser")
local core = require("gotest.core")
local query = require("gotest.golang.query")

M.match = query.match

local __Config = {
	command = { "go", "test", "./...", "-v", "-race", "-shuffle=on", "-json" },
	pattern = "*.go",
}

---
---@param cmd table<string>
---@return function
M.TestCommand = function(cmd)
	return function(config)
		config.command = cmd
	end
end

---@param inputPattern string
---@return function
M.TestFilePattern = function(inputPattern)
	return function(config)
		config.pattern = inputPattern
	end
end

-- @param ... function[]
M.setup = function(functions)
	for _, plugin in ipairs(functions) do
		plugin(__Config)
	end

	require("gotest.core.tschecker").checkLanguage("go")

	core.initializeMarker({

		interestedFilesSuffix = ".go",
		pattern = __Config.pattern,
		bufforNameProcessor = function(buffor_name, buffor_number)
			return query.package_name_query(buffor_number) or buffor_name
		end,
		parserProvider = function()
			return parser
		end,
		testCommand = __Config.command,
		findTestLine = query.find_test_line,
		findTestKey = query.findTestKey,
	})
end

M.parse = parser.parse
return M
