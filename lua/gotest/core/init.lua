local state = require("gotest.core.state")
local shower = require("gotest.core.show")
local marker = require("gotest.core.marker")
local loggerModule = require("gotest.core.logging")
local lazyDebug = loggerModule.lazyDebug
local M = {}

--- @class TestIdentifier
--- @field packageName string
--- @field testName string
local TestIdentifier = {}
TestIdentifier.__index = TestIdentifier
---
---@param packageName string
---@param testName string
---@return TestIdentifier
function TestIdentifier:new(packageName, testName)
	local a = setmetatable({}, TestIdentifier)
	a.testName = testName
	a.packageName = packageName
	return a
end

---comment
---@param this TestIdentifier
---@param other TestIdentifier
---@return boolean
function TestIdentifier.__eq(this, other)
	return this ~= nil and other ~= nil and this.testName == other.testName and this.packageName == other
	.packageName
end

--- @alias EventType "failure"|"run"|"success"|"start"

---@param testIdentifier TestIdentifier
---@return Event
local function success(testIdentifier)
	--- @class Event
	--- @field key TestIdentifier
	--- @field type EventType
	local event = {}
	event.key = testIdentifier
	event.type = "success"
	return event
end

---@param testIdentifier TestIdentifier
---@return Event
local function failure(testIdentifier)
	return {
		key = testIdentifier,
		type = "failure",
	}
end

---@param testIdentifier TestIdentifier
---@return Event
local function running(testIdentifier)
	return {
		key = testIdentifier,
		type = "run",
	}
end

---@return Event
local function started()
	return {
		key = nil,
		type = "start",
	}
end

M.success = success
M.failure = failure
M.running = running
M.started = started
M.state = state

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

---@class ParsingResult
---@field event Event | nil
---@field output Output | nil
---@field empty boolean
local ParsingResult = {}
ParsingResult.__index = ParsingResult

---@param event Event|nil
---@param output Output|nil
---@return ParsingResult
function ParsingResult:new(event, output)
	local obj = setmetatable({}, ParsingResult)
	obj.output = output
	obj.event = event
	lazyDebug(function()
		return vim.inspect(event or "")
	end)
	obj.empty = false
	return obj
end

---@param event Event
---@return ParsingResult
function ParsingResult:onlyEvent(event)
	return ParsingResult:new(event, nil)
end

---comment
---@param output Output
---@return ParsingResult
function ParsingResult:withOutput(output)
	return ParsingResult:new(self.event, output)
end

---@param output Output
---@return ParsingResult
function ParsingResult:onlyOutput(output)
	return ParsingResult:new(nil, output)
end

function ParsingResult:none()
	local obj = ParsingResult:new(nil, nil)
	obj.empty = true
	return obj
end

M.TestIdentifier = TestIdentifier
M.ParsingResult = ParsingResult

local function find_project_root()
	-- full path of directory
	local current_file = vim.fn.expand("%:p:h")
	while current_file ~= "/" and not vim.loop.fs_stat(current_file .. "/.git") do
		current_file = vim.fn.fnamemodify(current_file, ":h")
	end
	if current_file == "/" then
		return nil
	else
		return current_file
	end
end
local project_root = find_project_root()

---comment
---@param str string
---@param prefix string
---@return string
M.removePrefix = function(str, prefix)
	local prefixStart, prefixEnd = string.find(str, prefix)
	if prefixStart == 1 then -- Ensure the prefix is at the start
		return string.sub(str, prefixEnd + 1)
	end
	return str -- Return the original string if prefix not at start
end

---comment
---@param str string
---@param prefix string
---@return boolean
M.startsWith = function(str, prefix)
	local prefixStart, _ = string.find(str, prefix)
	return prefixStart == 1 -- Ensure the prefix is at the start
end

---comment
---@param str string
---@param suffix string
---@return string
M.removeSuffix = function(str, suffix)
	local suffixStart, suffixEnd = string.find(str, suffix, 1, true)
	if suffixEnd == #str then -- Ensure the suffix is at the end
		return string.sub(str, 1, suffixStart - 1)
	end
	return str -- Return the original string if suffix not at end
end

---comment
---@param str string
---@param suffix string
---@return boolean
M.endsWith = function(str, suffix)
	local _, suffixEnd = string.find(str, suffix, 1, true)
	return suffixEnd == #str
end

---comment
---@param path string
---@return string
M.relative = function(path)
	return M.removePrefix(path, project_root)
end

---comment
---@param relativePath string
---@return string
M.projectPath = function(relativePath)
	return project_root .. "/" .. relativePath
end

M.trim = function(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

M.split = function(str, delimiter)
	local result = {}
	local from = 1
	local delim_from, delim_to = string.find(str, delimiter, from)
	while delim_from do
		table.insert(result, string.sub(str, from, delim_from - 1))
		from = delim_to + 1
		delim_from, delim_to = string.find(str, delimiter, from)
	end
	table.insert(result, string.sub(str, from))
	return result
end

-- @class __Config
-- @field logerLevel string
-- @field UserCommandName string
local __Config = {
	loggerLevel = "info",
}

-- @param ... function[]
M.setup = function(functions)
	for _, plugin in ipairs(functions) do
		plugin(__Config)
	end
	loggerModule.setup(__Config.loggerLevel)
	M._ns = vim.api.nvim_create_namespace("lua-live-test")
	M._group = vim.api.nvim_create_augroup("lua-live-test_au", { clear = true })
	state.setup()
	shower.setup()

	marker.setup(M._ns, M._group)
end

-- @return function
-- @param _config __Config
M.enableDebug =
-- @param _config __Config
    function(_config)
	    _config.loggerLevel = "debug"
    end
-- @return function
-- @param _config __Config
M.enableInfo =
-- @param _config __Config
    function(_config)
	    _config.loggerLevel = "info"
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

---@class SetupConfig
---@field pattern string
---@field testCommand table<string>
---@field bufforNameProcessor fun(text:string, buffnr:integer):string|nil
---@field findTestLine fun(buffnr:integer, key:TestIdentifier):integer|nil
---@field parserProvider fun(): Parser

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
					end, M.myerrorhandler)
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
