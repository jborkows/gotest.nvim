local M = {}

---comment
---@param str string
---@param prefix string
---@return string
M.removePrefix = function(str, prefix)
	local prefixStart, prefixEnd = string.find(str, prefix)
	if prefixStart == 1 then -- Ensure the prefix is at the start
		return string.sub(str, prefixEnd + 1)
	end
	return str -- Return the original string if prefix not at start
end

---comment
---@param str string
---@param prefix string
---@return boolean
M.startsWith = function(str, prefix)
	local prefixStart, _ = string.find(str, prefix)
	return prefixStart == 1 -- Ensure the prefix is at the start
end

---comment
---@param str string
---@param suffix string
---@return string
M.removeSuffix = function(str, suffix)
	local suffixStart, suffixEnd = string.find(str, suffix, 1, true)
	if suffixEnd == #str then -- Ensure the suffix is at the end
		return string.sub(str, 1, suffixStart - 1)
	end
	return str -- Return the original string if suffix not at end
end

---comment
---@param str string
---@param suffix string
---@return boolean
M.endsWith = function(str, suffix)
	local _, suffixEnd = string.find(str, suffix, 1, true)
	return suffixEnd == #str
end

---commen
---@param s string
---@return string
M.trim = function(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

---comment
---@param str string
---@param delimiter string
---@return table<string>
M.split = function(str, delimiter)
	local result = {}
	local from = 1
	local delim_from, delim_to = string.find(str, delimiter, from)
	while delim_from do
		table.insert(result, string.sub(str, from, delim_from - 1))
		from = delim_to + 1
		delim_from, delim_to = string.find(str, delimiter, from)
	end
	table.insert(result, string.sub(str, from))
	return result
end
return M
