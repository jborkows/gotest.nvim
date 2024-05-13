local loggerModule = require("gotest.core.logging")
local lazyDebug = loggerModule.lazyDebug
local M = {}

--- @alias State "start"|"success"|"failure"|"N/A"|"run"

--- @class TestState
--- @field key TestIdentifier
--- @field state State|nil
--- @field messages string[]
local TestState = {}
TestState.__index = TestState
---
---@param key TestIdentifier
---@return TestState
function TestState:new(key)
	local a = setmetatable({}, TestState)
	a.key = key
	a.messages = {}
	return a
end

---@return State
function TestState:status()
	local value = self.state
	if value ~= nil then
		return value
	else
		return "N/A"
	end
end

---@return string
function TestState:asKey()
	return self.key.packageName .. "->" .. self.key.testName
end

---@param state State
function TestState:changeState(state)
	self.state = state
end

local TestStateManager = {
	---@type table<string,TestState>
	tests = {},
	---@type table<string>
	messages = {},
}

---comment
---@param key TestIdentifier
---@return TestState
function TestStateManager:get(key)
	local testState = TestState:new(key)
	local stringKey = testState:asKey()
	if self.tests[stringKey] == nil then
		self.tests[stringKey] = testState
	end
	return self.tests[stringKey]
end

---@param message string
function TestState:addMessage(message)
	lazyDebug(function()
		return self:asKey() .. " adding '" .. message .. "'"
	end)
	table.insert(self.messages, message)
end

---@return StateMachine|nil
function TestState:translate()
	local state = self.state
	if state == nil then
		return "notstarted"
	elseif state == "success" then
		return "finished"
	elseif state == "failure" then
		return "finished"
	elseif state == "run" then
		return "running"
	else
		return nil
	end
end

---@param message ParsingResult
function TestStateManager:reactOn(message)
	self:changeState(message)
	self:addMessage(message)
end

---@param message ParsingResult
function TestStateManager:changeState(message)
	local event = message.event
	if event == nil then
		return
	end
	local state = event.type
	local key = event.key
	local testState = self:get(key)
	local machineState = testState:translate()
	testState.state = state
end

function TestStateManager:clear()
	self.messages = {}
end

---@param message ParsingResult
function TestStateManager:addMessage(message)
	local output = message.output
	if output == nil then
		return
	end
	table.insert(self.messages, output.message)

	local key = output.key
	if key == nil then
		return
	end
	local testState = self:get(key)
	testState:addMessage(output.message)
end

---@alias StateMachine "finished"|"running"|"notstarted"

---@param message ParsingResult
M.onParsing = function(message)
	if message.empty then
		return
	end

	if message.event ~= nil and message.event.type == "start" then
		M.setup()
		return
	end
	TestStateManager:reactOn(message)
end

---comment
---@return table<TestIdentifier, State>
M.states = function()
	local result = {}
	for _, value in pairs(TestStateManager.tests) do
		result[value.key] = value.state
	end
	return result
end

---@param key:TestIdentifier
---@return State
M.state = function(key)
	local state = TestStateManager:get(key)
	return state:status()
end

---comment
---@param key TestIdentifier
---@return string[]
M.outputs = function(key)
	return TestStateManager:get(key).messages
end

--- all gathered entries from stdin
---@return string[]
M.allOutputs = function()
	return TestStateManager.messages
end

M.setup = function()
	TestStateManager:clear()
end

return M
