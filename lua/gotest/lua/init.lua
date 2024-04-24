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
---@return Parser
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

local displayResults = core.marker.displayResults(query.find_test_line)

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
	local ns = core.ns
	local group = core.group
	for _, plugin in ipairs(functions) do
		plugin(__Config)
	end
	local bufferNum = {}
	vim.api.nvim_create_autocmd("BufEnter", {

		group = group,
		pattern = "*.lua",
		callback = function()
			local buffnr = vim.api.nvim_get_current_buf()
			local buffor_name = vim.api.nvim_buf_get_name(buffnr)
			local single_one = {}
			if core.endsWith(buffor_name, "_spec.lua") then
				local normalized_name =
				    core.removeSuffix(core.removePrefix(core.relative(buffor_name), "/tests/"), ".lua")
				bufferNum[normalized_name] = buffnr
				single_one[normalized_name] = buffnr
				vim.api.nvim_buf_clear_namespace(buffnr, ns, 0, -1)
			end
			local state = core.state

			displayResults(state.states(), single_one)
		end,
	})
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = group,
		pattern = "*.lua",
		callback = function()
			local buffnr = vim.api.nvim_get_current_buf()
			local buffor_name = vim.api.nvim_buf_get_name(buffnr)
			if core.endsWith(buffor_name, "_spec.lua") then
				local normalized_name =
				    core.removeSuffix(core.removePrefix(core.relative(buffor_name), "/tests/"), ".lua")
				bufferNum[normalized_name] = buffnr
				vim.api.nvim_buf_clear_namespace(buffnr, ns, 0, -1)
			end
			local aParser = M.parser(core.projectPath("tests/"))

			local state = core.state
			state.setup()
			vim.fn.jobstart(__Config.command, {
				stdout_buffered = true,
				on_stderr = function(_, data) end,
				on_stdout = function(_, data)
					if not data then
						return
					end -- if data are present append lines starting from end of file (-1) to end of file (-1)
					xpcall(function()
						for _, line in ipairs(data) do
							local parsed = aParser.parse(line)
							state.onParsing(parsed)
						end
					end, core.myerrorhandler)
				end,
				on_exit = function()
					displayResults(state.states(), bufferNum)
					core.storeTestOutputs(state.allOutputs())
				end,
			})
		end,
	})
end

return M
