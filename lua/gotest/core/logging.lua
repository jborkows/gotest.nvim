local M = {}
---@type "info"|"debug"
local level = "info"

local loggerPath = string.format("%s/%s.log", vim.api.nvim_call_function("stdpath", { "cache" }), "gotest")

local function writeMessage(message, logLevel)
	local file = io.open(loggerPath, "a")

	if file ~= nil then
		local timestamp = os.date("%Y-%m-%d %H:%M:%S")
		file:write(
			string.format("[%s][%s] %s: %s\n", string.upper(logLevel), timestamp,
				vim.api.nvim_buf_get_name(0), message)
		)
		file:flush()
	end
end

local logger = {
	---@param message string
	info = function(message)
		writeMessage(message, "info")
	end,

	---@param message string
	error = function(message)
		writeMessage(message, "error")
	end,

	---@param message string
	debug = function(message)
		if level == "debug" then
			writeMessage(message, "debug")
		end
	end,
}

M.myerrorhandler = function(err)
	logger.error("" .. err)
end

---comment
---@param fn fun(): string
M.lazyDebug = function(fn)
	if level == "debug" then
		logger.debug(fn())
	end
end
M.debug = logger.debug
M.info = logger.info
---comment
---@param inputLevel "info"|"debug"
M.setup = function(inputLevel)
	level = inputLevel
end
return M
