local core = require("gotest.core")

local M = {}

--comment
---@param prefix string
---@return TestOutputParser
M.parser = function(prefix)
	---@type TestOutputParser
	local Parser = {}
	local packageName = ""
	Parser.parse = function(text)
		local result = function()
			if string.match(text, "Starting") then
				return core.ParsingResult:onlyEvent(core.started())
			end

			local pattern = "Testing:%s*" .. prefix .. "(.*).lua"

			local extracted = string.match(text, pattern)
			if extracted ~= nil then
				packageName = core.trim(extracted)
				return core.ParsingResult:none()
			end

			if string.find(text, "||") then
				local splitted = core.split(text, "||")
				local what = core.trim(splitted[2])
				if string.find(splitted[1], "Success") then
					return core.ParsingResult:onlyEvent(core.success(core.TestIdentifier:new(
					packageName, what)))
				end

				if string.find(splitted[1], "Fail") then
					return core.ParsingResult:onlyEvent(core.failure(core.TestIdentifier:new(
					packageName, what)))
				end
			else
			end

			return core.ParsingResult:none()
		end
		return result():withOutput(core.output(text))
	end
	return Parser
end
return M
