local M = {}

---comment
---@param message Message|nil
M.onMessage = function(message) end
--- @alias State "success"|"failure"|"N/A"
--
---@param packageName string
---@param testName string
---@return State
M.state = function(packageName, testName)
	return "N/A"
end
---comment
---@param packageName string
---@param testName string
---@return string[]
M.outputs = function(packageName, testName)
	return {}
end ---comment

M.clear = function() end

return M
