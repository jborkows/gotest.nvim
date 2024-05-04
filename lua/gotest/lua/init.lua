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
---@return TestOutputParser
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

local __Config = {
	command = { "make", "tests" },
}

M.luaTestCommand = function(cmd)
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
		interestedFilesSuffix = ".lua",
		pattern = "*.lua",
		bufforNameProcessor = function(buffor_name, _)
			if not core.endsWith(buffor_name, "_spec.lua") then
				return nil
			end

			local normalized_name = core.removeSuffix(
			core.removePrefix(core.relative(buffor_name), "/tests/"), ".lua")
			return normalized_name
		end,
		parserProvider = function()
			return M.parser(core.projectPath("tests/"))
		end,
		testCommand = __Config.command,
		findTestLine = query.find_test_line,
	})
end

return M
