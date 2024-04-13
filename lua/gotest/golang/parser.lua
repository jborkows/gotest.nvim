local M = {}
local core = require("gotest.core")

---comment
---@param text string
---@return ParsingResult
M.parse = function(text)
	local json = vim.fn.json_decode(text)

	if not vim.tbl_contains({ "output", "fail", "run", "pass" }, json.Action) then
		return core.ParsingResult:none()
	end

	if json.Test == nil then
		return core.ParsingResult:none()
	end
	local packageName = json.Package or ""
	local testName = json.Test or ""
	local key = core.TestIdentifier:new(packageName, testName)
	if json.Action == "output" then
		if json.Package == nil and json.Test == nil then
			return core.ParsingResult:onlyOutput(core.output(json.Output))
		else
			return core.ParsingResult:onlyOutput(core.testOutput(key)(json.Output))
		end
	elseif json.Action == "fail" then
		return core.ParsingResult:onlyEvent(core.failure(key))
	elseif json.Action == "pass" then
		return core.ParsingResult:onlyEvent(core.success(key))
	elseif json.Action == "run" then
		return core.ParsingResult:onlyEvent(core.running(key))
	else
		return core.ParsingResult:none()
	end
end

return M
