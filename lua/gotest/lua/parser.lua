local core = require("gotest.core")

local M = {}

--comment
---@param prefix string
---@return Parser
M.parser = function(prefix)
	---@class Parser
	---@field parse fun(text:string):ParsingResult
	local Parser = {}
	Parser.packageName = ""
	Parser.parse = function(text)
		local result = function()
			if string.match(text, "Starting") then
				return core.ParsingResult:onlyEvent(core.started())
			end

			local pattern = "Testing:%s*" .. prefix .. "(.*)"
			local extracted = string.match(text, pattern)
			if extracted ~= nil then
				Parser.packageName = core.trim(extracted)
				return core.ParsingResult:none()
			end

			if string.find(text, "||") then
				local splitted = core.split(text, "||")
				local what = core.trim(splitted[2])
				if string.find(splitted[1], "Success") then
					return core.ParsingResult:onlyEvent(core.success(core.TestIdentifier:new(
					Parser.packageName, what)))
				end

				if string.find(splitted[1], "Fail") then
					return core.ParsingResult:onlyEvent(core.failure(core.TestIdentifier:new(
					Parser.packageName, what)))
				end
			end

			return core.ParsingResult:none()
		end
		return result():withOutput(core.output(text))
	end
	return Parser
end
return M
