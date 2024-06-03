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
end

---comment
---@param lines table<string>
M.storeTestOutputs = function(lines)
	lazyDebug(function()
		return "Received " .. vim.inspect(lines)
	end)
	shower.keepResult(lines)
end

---@type MarkerViewFactory
local markerViewFactory = require("gotest.core.markerView")

---@type RunCommand
local runCommand = require("gotest.core.launcher").runCommand

---test only
---@param factory MarkerViewFactory
M.__useMarkerView = function(factory)
	local old = markerViewFactory
	markerViewFactory = factory
	return old
end

---test only
---@param runner RunCommand
---@return RunCommand
M.__useRunner = function(runner)
	local old = runCommand
	runCommand = runner
	return old
end

---@class TestOutputParser
---@field parse fun(text:string):ParsingResult

---@class SetupConfig
---@field pattern string
---@field interestedFilesSuffix string
---@field testCommand table<string>
---@field bufforNameProcessor fun(text:string, buffnr:integer):string|nil
---@field findTestLine fun(buffnr:integer, key:TestIdentifier):integer|nil
---@field findTestKey fun(line:integer, column:integer):TestIdentifier|nil
---@field parserProvider fun():  TestOutputParser

local saveCommands = {}
---Initialize package autocommands
---@param setupConfig SetupConfig
M.initializeMarker = function(setupConfig)
	local ns = M._ns
	local group = M._group

	local displayResults = marker.displayResults(ns, function()
		return markerViewFactory
	end, setupConfig.findTestLine)
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
	local save = function(setupConfig)
		local buffnr = vim.api.nvim_get_current_buf()
		local buffor_name = vim.api.nvim_buf_get_name(buffnr)

		local normalized_name = setupConfig.bufforNameProcessor(buffor_name, 0)

		if
		    normalized_name ~= nil
		    and require("gotest.core.strings").endsWith(normalized_name, setupConfig.interestedFilesSuffix)
		then
			bufferNum[normalized_name] = buffnr
			vim.api.nvim_buf_clear_namespace(buffnr, ns, 0, -1)
		end
		local aParser = setupConfig.parserProvider()

		state.setup()

		runCommand(setupConfig.testCommand, {
			onData = function(line)
				local parsed = aParser.parse(line)
				state.onParsing(parsed)
				M.storeTestOutputs(state.allOutputs())
			end,
			onExit = function(exitResult)
				if exitResult.hasFailed then
					return
				end
				displayResults(state.states(), bufferNum)
				M.storeTestOutputs(state.allOutputs())
				marker.onTestFinished(state.states(), function()
					return markerViewFactory
				end)
			end,
		})
	end

	saveCommands[setupConfig.pattern] = { saveCommand = save, setupConfig = setupConfig }
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = group,
		pattern = setupConfig.pattern,
		callback = function()
			save(setupConfig)
		end,
	})
end

M.executeTests = function()
	for pattern, value in pairs(saveCommands) do
		local saveCommand = value.saveCommand
		local setupConfig = value.setupConfig

		local name = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
		if require("gotest.core.strings").endsWith(name, setupConfig.interestedFilesSuffix) then
			lazyDebug(function()
				return "Matched " ..
				name .. " to pattern " .. pattern .. " with " .. vim.inspect(setupConfig)
			end)
			saveCommand(setupConfig)
			return
		end
	end
	if saveCommands == nil then
		return
	end
end
vim.api.nvim_create_user_command("ExecuteTests", function()
	M.executeTests()
end, {})

vim.api.nvim_create_user_command("TestResult", function()
	for _, value in pairs(saveCommands) do
		local setupConfig = value.setupConfig

		local name = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
		if require("gotest.core.strings").endsWith(name, setupConfig.interestedFilesSuffix) then
			lazyDebug(function()
				return "Matched " .. name .. " to pattern " .. " with " .. vim.inspect(setupConfig)
			end)
			local current_pos = vim.api.nvim_win_get_cursor(0)
			local current_line = current_pos[1]
			local current_col = current_pos[2]
			local key = setupConfig.findTestKey(current_line, current_col)

			if key == nil then
				lazyDebug(function()
					return "Not found key for " .. current_line .. ";" .. current_pos
				end)
				return
			end

			lazyDebug(function()
				return "Found key " .. key.packageName .. "->" .. key.testName
			end)
			local messages = state.outputs(key)
			lazyDebug(function()
				return "Found "
				    .. table.maxn(messages)
				    .. " messages for key "
				    .. key.packageName
				    .. "->"
				    .. key.testName
			end)
			if require("gotest.core.tableutils").isEmpty(messages) then
				return
			end

			require("gotest.core.show").showSingle(key, messages)
			return
		end
	end
end, {})

return M
