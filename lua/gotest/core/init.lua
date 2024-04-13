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

--- @alias EventType "failure"|"run"|"success"

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

M.success = success
M.failure = failure
M.running = running
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
M.setup = function()
	state.setup()
end
return M
