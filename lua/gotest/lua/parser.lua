local core = require("gotest.core")

local M = {}

--comment
---@param prefix string
---@return Parser-
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
				Parser.packageName = extracted
				return core.ParsingResult:none()
			end

			local pattern = "Success%s*||%s*(.*)"
			local extracted = string.match(text, pattern)
			if extracted ~= nil then
				return core.ParsingResult:onlyEvent(
					core.success(core.TestIdentifier:new(Parser.packageName, extracted))
				)
			end

			local pattern = "Fail%s*||%s*(.*)"
			local extracted = string.match(text, pattern)
			if extracted ~= nil then
				return core.ParsingResult:onlyEvent(
					core.failure(core.TestIdentifier:new(Parser.packageName, extracted))
				)
			end

			return core.ParsingResult:none()
		end
		return result():withOutput(core.output(text))
	end
	return Parser
end
return M
