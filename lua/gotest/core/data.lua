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

M.success = success
M.failure = failure
M.running = running
M.started = started
M.ParsingResult = ParsingResult
M.TestIdentifier = TestIdentifier
return M
