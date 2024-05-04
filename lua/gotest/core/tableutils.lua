local M = {}
---@alias T any

---@param entries T
---@param predicate fun(entry:T):boolean
M.contains = function(entries, predicate)
	if entries == nil then
		return false
	end
	for _, value in ipairs(entries) do
		if predicate(value) == true then
			return true
		end
	end

	return false
end
return M
