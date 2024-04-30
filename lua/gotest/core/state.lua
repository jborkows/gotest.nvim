local M = {}

--- @alias State "start"|"success"|"failure"|"N/A"|"run"
--- table<TestIdentifier,State>
M.__states = {}
--- table <TestIdentifier, string[]>
M.__test_messages = {}

--- string[]
M.__messages = {}

---@param key TestIdentifier
---@return string
local keyInMap = function(key)
	return string.format("%s -> %s", key.packageName, key.testName)
end

---@alias StateMachine "finished"|"running"|"notstarted"

---@param state State|nil
---@return StateMachine
local stateTranslator = function(state)
	if state == nil then
		return "notstarted"
	elseif state == "success" then
		return "finished"
	elseif state == "failure" then
		return "finished"
	elseif state == "run" then
		return "running"
	end
end
---@param state State
---@param key TestIdentifier
local stateReactor = function(state, key)
	local oldState = M.__states[keyInMap(key)]
	local machineState = stateTranslator(oldState)
	if machineState == "notstarted" then
		--NOP
	elseif machineState == "finished" then
		M.__test_messages[keyInMap(key)] = {}
	end
	M.__states[keyInMap(key)] = state
end

---@param message ParsingResult
M.onParsing = function(message)
	if message.empty then
		return
	end

	if message.event ~= nil and message.event.type == "start" then
		M.setup()
		return
	end
	if message.event ~= nil then
		stateReactor(message.event.type, message.event.key)
	end

	if message.output ~= nil then
		if message.output ~= nil then
			table.insert(M.__messages, message.output.message)
			if message.output.key ~= nil then
				if M.__test_messages[keyInMap(message.output.key)] == nil then
					M.__test_messages[keyInMap(message.output.key)] = {}
				end
				table.insert(M.__test_messages[keyInMap(message.output.key)], message.output.message)
			end
		end
	end
end
---comment
---@param key TestIdentifier
---@return State
M.state = function(key)
	local value = M.__states[keyInMap(key)]
	if value ~= nil then
		return value
	else
		return "N/A"
	end
end

---comment
---@return table<TestIdentifier, State>
M.states = function()
	return M.__states
end

---comment
---@param key TestIdentifier
---@return string[]
M.outputs = function(key)
	local keyValue = keyInMap(key)
	if M.__test_messages[keyValue] == nil then
		return {}
	else
		return M.__test_messages[keyValue]
	end
end ---comment

--- all gathered entries from stdin
---@return string[]
M.allOutputs = function()
	return M.__messages
end

M.setup = function()
	M.__messages = {}
	M.__states = {}
	M.__test_messages = {}
end

return M
