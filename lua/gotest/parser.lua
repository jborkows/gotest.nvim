local M = {}

---comment
---@param text string
---@return Message | nil
M.parse = function(text)
	--- @alias MessageAction "output"|"fail"|"run"|"pass"
	--- @class Message
	--- @field package string
	--- @field testName string
	--- @field action Action
	--- @field match fun(packageName:string,testName:string):boolean

	local json = vim.fn.json_decode(text)

	if not vim.tbl_contains({ "output", "fail", "run", "pass" }, json.Action) then
		return nil
	end

	if json.Test == nil then
		return nil
	end
	local Message = {}
	Message.package = json.Package or ""
	Message.testName = json.Test or ""
	--- @class Action
	--- @field Type string
	--- @field output string|nil
	Message.action = {
		--- @type MessageAction
		Type = json.Action,
		output = json.Output,
	}

	---
	---@param packageName string
	---@param testName string
	---@return boolean
	Message.match = function(packageName, testName)
		return Message.testName == testName and string.match(Message.package, packageName .. "$") ~= nil
	end
	return Message
end

return M
