local M = {}

M.debug = function()
	local logging = require("gotest.core.logging")
	return {
		type = "Logging",
		fn = logging.enableDebug,
	}
end

M.info = function()
	local logging = require("gotest.core.logging")
	return {
		type = "Logging",
		fn = logging.enableInfo,
	}
end

---comment
---@param cmd table<string>
---@return table
M.luaTestCommand = function(cmd)
	local luaCore = require("gotest.lua")
	return {
		type = "Lua",
		fn = luaCore.luaTestCommand(cmd),
	}
end

---comment
---@param cmd table<string>
---@return fun():table
M.goTestCommand = function(cmd)
	local golangCore = require("gotest.golang")
	return function()
		return {
			type = "Go",
			fn = golangCore.TestCommand(cmd),
		}
	end
end

-- @param ... function[]
M.setup = function(...)
	local configurations = {
		{
			type = "Logging",
			setup = function()
				local logging = require("gotest.core.logging")
				return logging.setup
			end,
		},

		{
			type = "Lua",
			setup = function()
				return require("gotest.lua").setup
			end,
		},

		{
			type = "Go",
			setup = function()
				return require("gotest.golang").setup
			end,
		},
	}

	for _, configEater in ipairs(configurations) do
		local configs = {}
		for _, plugin in ipairs({ ... }) do
			local config = plugin()
			if config.type == configEater.type then
				table.insert(configs, config.fn)
			end
		end
		configEater.setup()(configs)
	end
end
return M
