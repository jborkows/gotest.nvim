local state = require("gotest.core.state")
local shower = require("gotest.core.show")
local marker = require("gotest.core.marker")
local dataModule = require("gotest.core.data")
local loggerModule = require("gotest.core.logging")
local paths = require("gotest.core.paths")

local strings = require("gotest.core.strings")
local M = {}
M.state = state
local lazyDebug = loggerModule.lazyDebug

M.TestIdentifier = dataModule.TestIdentifier
M.ParsingResult = dataModule.ParsingResult
M.success = dataModule.success
M.failure = dataModule.failure
M.running = dataModule.running
M.started = dataModule.started
---@class Output
---@field key TestIdentifier|nil
---@field message string

---@param key TestIdentifier
---@return fun(string):Output
M.testOutput = function(key)
	return function(message)
		--- Output
		return {
			key = key,
			message = message,
		}
	end
end

---@param message string
---@return Output
M.output = function(message)
	return {
		key = nil,
		message = message,
	}
end

M.relative = paths.relative
M.projectPath = paths.projectPath
M.removePrefix = strings.removePrefix
M.startsWith = strings.startsWith
M.removeSuffix = strings.removeSuffix
M.endsWith = strings.endsWith
M.trim = strings.trim
M.split = strings.split

M.setup = function()
	M._ns = vim.api.nvim_create_namespace("lua-live-test")
	M._group = vim.api.nvim_create_augroup("lua-live-test_au", { clear = true })
	state.setup()
	shower.setup()

	marker.setup(M._ns, M._group)
end

---comment
---@param lines table<string>
M.storeTestOutputs = function(lines)
	lazyDebug(function()
		return "Received " .. vim.inspect(lines)
	end)
	shower.keepResult(lines)
end

M.marker = marker

---@class TestOutputParser
---@field parse fun(text:string):ParsingResult

---@class SetupConfig
---@field pattern string
---@field testCommand table<string>
---@field bufforNameProcessor fun(text:string, buffnr:integer):string|nil
---@field findTestLine fun(buffnr:integer, key:TestIdentifier):integer|nil
---@field parserProvider fun():  TestOutputParser

---Initialize package autocommands
---@param setupConfig SetupConfig
M.initializeMarker = function(setupConfig)
	local ns = M._ns
	local group = M._group

	local displayResults = M.marker.displayResults(setupConfig.findTestLine)
	local bufferNum = {}
	vim.api.nvim_create_autocmd("BufEnter", {

		group = group,
		pattern = setupConfig.pattern,
		callback = function()
			local buffnr = vim.api.nvim_get_current_buf()
			local buffor_name = vim.api.nvim_buf_get_name(buffnr)
			local single_one = {}
			local normalized_name = setupConfig.bufforNameProcessor(buffor_name, 0)
			if normalized_name ~= nil then
				bufferNum[normalized_name] = buffnr
				single_one[normalized_name] = buffnr
				vim.api.nvim_buf_clear_namespace(buffnr, ns, 0, -1)
			end
			displayResults(state.states(), single_one)
		end,
	})
	-- TODO extract job executor so during testing it is possible to pass text into
	local jobId = nil
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = group,
		pattern = setupConfig.pattern,
		callback = function()
			local buffnr = vim.api.nvim_get_current_buf()
			local buffor_name = vim.api.nvim_buf_get_name(buffnr)

			local normalized_name = setupConfig.bufforNameProcessor(buffor_name, 0)
			if normalized_name ~= nil then
				bufferNum[normalized_name] = buffnr
				vim.api.nvim_buf_clear_namespace(buffnr, ns, 0, -1)
			end
			local aParser = setupConfig.parserProvider()

			state.setup()
			if jobId ~= nil then
				vim.fn.jobstop(jobId)
			end
			lazyDebug(function()
				return "Running command: " .. vim.inspect(setupConfig.testCommand)
			end)
			jobId = vim.fn.jobstart(setupConfig.testCommand, {
				stdout_buffered = true,
				on_stderr = function(_, data)
					lazyDebug(function()
						return "Error stream: " .. vim.inspect(data)
					end)
				end,
				on_stdout = function(_, data)
					if not data then
						return
					end -- if data are present append lines starting from end of file (-1) to end of file (-1)
					xpcall(function()
						for _, line in ipairs(data) do
							local parsed = aParser.parse(line)
							state.onParsing(parsed)
							M.storeTestOutputs(state.allOutputs())
						end
					end, loggerModule.myerrorhandler)
				end,
				on_exit = function()
					jobId = nil
					displayResults(state.states(), bufferNum)
					M.storeTestOutputs(state.allOutputs())
				end,
			})
		end,
	})
end

return M
