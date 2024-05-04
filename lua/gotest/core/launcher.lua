local loggerModule = require("gotest.core.logging")
local lazyDebug = loggerModule.lazyDebug
local jobId = nil

---@class JobHandler
---@field onData fun(line:string)
---@field onExit fun()
---

---@alias RunCommand fun(command:table<string>, handler: JobHandler>

--- executes command
---@param command table<string>
---@param handler JobHandler
local function runCommand(command, handler)
	if jobId ~= nil then
		vim.fn.jobstop(jobId)
	end
	lazyDebug(function()
		return "Running command: " .. vim.inspect(command)
	end)

	jobId = vim.fn.jobstart(command, {
		stdout_buffered = true,
		on_stderr = function(_, data)
			lazyDebug(function()
				return "Error stream: " .. vim.inspect(data)
			end)
		end,
		on_stdout = function(_, data)
			if not data then
				return
			end
			xpcall(function()
				for _, line in ipairs(data) do
					handler.onData(line)
				end
			end, loggerModule.myerrorhandler)
		end,
		on_exit = function()
			jobId = nil
			handler.onExit()
		end,
	})
end

return {
	---@type RunCommand
	runCommand = runCommand,
}
