local M = {}
local core = require("gotest.core")
local luaCore = require("gotest.lua")
local golangCore = require("gotest.golang")

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

---comment
---@param cmd table<string>
---@return table
M.goTestCommand = function(cmd)
	return {
		type = "Go",
		fn = golangCore.TestCommand(cmd),
	}
end

-- @param ... function[]
M.setup = function(...)
	local configurations = {
		core = {
			type = "Logging",
			setup = function()
				return require("gotest.core").setup
			end,
		},

		lua = {
			type = "Lua",
			setup = function()
				return require("gotest.lua").setup
			end,
		},

		go = {
			type = "Go",
			setup = function()
				return require("gotest.golang").setup
			end,
		},
	}

	for _, configEater in pairs(configurations) do
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
