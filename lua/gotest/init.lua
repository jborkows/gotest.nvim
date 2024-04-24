local M = {}
local core = require("gotest.core")
local luaCore = require("gotest.lua")

M.debug = function()
	return {
		type = "Logging",
		fn = core.enableDebug,
	}
end

M.info = function()
	return {
		type = "Logging",
		fn = core.enableInfo,
	}
end

---comment
---@param cmd table<string>
---@return table
M.luaTestCommand = function(cmd)
	return {
		type = "Lua",
		fn = luaCore.luaTestCommand(cmd),
	}
end

-- @param ... function[]
M.setup = function(...)
	local configs = {}
	for _, plugin in ipairs({ ... }) do
		local config = plugin()
		if config.type == "Logging" then
			configs = config.fn
		end
	end
	require("gotest.core").setup(configs)

	configs = {}
	for _, plugin in ipairs({ ... }) do
		local config = plugin()
		if config.type == "Lua" then
			configs = config.fn
		end
	end
	require("gotest.lua").setup(configs)
end
return M
