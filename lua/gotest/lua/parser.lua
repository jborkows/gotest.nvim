local M = {}
local core = require("gotest.core")

---comment
---@param text string
---@return ParsingResult
M.parse = function(text)
	return core.ParsingResult.none()
end

return M
