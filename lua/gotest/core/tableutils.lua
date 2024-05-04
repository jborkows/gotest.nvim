local M = {}
---@alias T any

---@param entries table<T>
---@param predicate fun(entry:T):boolean
---@return boolean
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

---@param entries table<T>
---@param element:T
---@return boolean
M.containsElement = function(entries, element)
	return M.contains(entries, function(entry)
		return entry == element
	end)
end

---@param first table<T>
---@return boolean
M.isEmpty = function(entries)
	return entries == nil or table.maxn(entries) == 0
end

---@param first table<T>
---@param second table<T>
---@return table<T>
M.add = function(first, second)
	local isEmpty = M.isEmpty
	if isEmpty(first) and isEmpty(second) then
		return {}
	end
	if isEmpty(first) and not isEmpty(second) then
		return M.add(second, first)
	end
	if isEmpty(second) then
		return first
	end
	if isEmpty(first) then
		return second
	end

	local result = {}
	for _, value in ipairs(first) do
		table.insert(result, value)
	end

	for _, value in ipairs(second) do
		table.insert(result, value)
	end
	return result
end
return M
