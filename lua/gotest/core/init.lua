local state = require("gotest.core.state")
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
	return setmetatable({ packageName = packageName, testName = testName }, TestIdentifier)
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
	local obj = setmetatable({ output = output, event = event }, ParsingResult)
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
	local suffixStart, suffixEnd = string.find(str, suffix, 1, true)
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

local logger = require("plenary.log"):new()
logger.level = "debug"

M.myerrorhandler = function(err)
	logger.info("ERROR:" .. err)
end

M.debug = function(message)
	logger.debug(message)
end

M.setup = function()
	state.setup()
end

return M
