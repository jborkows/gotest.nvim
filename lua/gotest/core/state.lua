local M = {}

--- @alias State "success"|"failure"|"N/A"|"running"
--- table<TestIdentifier,State>
M.__states = {}
--- table <TestIdentifier, string[]>
M.__test_messages = {}

--- string[]
M.__messages = {}

---@param message ParsingResult
M.onParsing = function(message)
	if message.empty then
		return
	end
	if message.event ~= nil then
		M.__states[message.event.key] = message.event.type
	end

	if message.output ~= nil then
		if message.output ~= nil then
			table.insert(M.__messages, message.output.message)
			if M.__test_messages[message.output.key] == nil then
				M.__test_messages[message.output.key] = {}
			end
			table.insert(M.__test_messages[message.output.key], message.output.message)
		end
	end
end
---comment
---@param key TestIdentifier
---@return State
M.state = function(key)
	local value = M.__states[key]
	if value ~= nil then
		return value
	else
		return "N/A"
	end
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

M.clear = function() end

return M
