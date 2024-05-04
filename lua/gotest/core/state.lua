local M = {}

--- @alias State "start"|"success"|"failure"|"N/A"|"run"
--- table<TestIdentifier,State>
M.__states = {}
--- table <TestIdentifier, string[]>
M.__test_messages = {}

--- string[]
M.__messages = {}

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

---@param key TestIdentifier
---@return string
local asKey = function(key)
	return key.testName .. " " .. key.packageName
end

---@param state State
---@param key TestIdentifier
local stateReactor = function(state, key)
	local oldState = M.__states[asKey(key)]
	local oldStateValue = nil
	if oldState ~= nil then
		oldStateValue = oldState.state
	end
	local machineState = stateTranslator(oldStateValue)
	if machineState == "notstarted" then
		--NOP
	elseif machineState == "finished" then
		M.__test_messages[key] = {}
	end
	M.__states[asKey(key)] = {
		state = state,
		key = key,
	}
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
				if M.__test_messages[message.output.key] == nil then
					M.__test_messages[message.output.key] = {}
				end
				table.insert(M.__test_messages[message.output.key], message.output.message)
			end
		end
	end
end
---comment
---@param key TestIdentifier
---@return State
M.state = function(key)
	local value = M.__states[asKey(key)]
	if value ~= nil then
		return value.state
	else
		return "N/A"
	end
end

---comment
---@return table<TestIdentifier, State>
M.states = function()
	local result = {}
	for _, value in pairs(M.__states) do
		result[value.key] = value.state
	end
	return result
end

---comment
---@param key TestIdentifier
---@return string[]
M.outputs = function(key)
	if M.__test_messages[key] == nil then
		return {}
	else
		return M.__test_messages[key]
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
