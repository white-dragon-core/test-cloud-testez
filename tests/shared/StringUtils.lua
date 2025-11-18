-- String utility functions
local StringUtils = {}

-- Reverse a string
function StringUtils.reverse(str)
	return string.reverse(str)
end

-- Check if string starts with prefix
function StringUtils.startsWith(str, prefix)
	return string.sub(str, 1, string.len(prefix)) == prefix
end

-- Check if string ends with suffix
function StringUtils.endsWith(str, suffix)
	if suffix == "" then
		return true
	end
	return string.sub(str, -string.len(suffix)) == suffix
end

-- Split string by delimiter
function StringUtils.split(str, delimiter)
	local result = {}
	local pattern = string.format("([^%s]+)", delimiter)

	for match in string.gmatch(str, pattern) do
		table.insert(result, match)
	end

	return result
end

-- Trim whitespace from both ends
function StringUtils.trim(str)
	return string.match(str, "^%s*(.-)%s*$")
end

-- Convert to title case
function StringUtils.titleCase(str)
	local result = string.gsub(str, "(%a)([%w_']*)", function(first, rest)
		return string.upper(first) .. string.lower(rest)
	end)
	return result
end

return StringUtils
