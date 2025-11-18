--[[
	Extended matchers for TestEZ Expectation
	Implements additional assertion methods beyond the core matchers
]]

local ExpectationMatchers = {}

--[[
	Deep equality comparison for tables
	Recursively compares table contents
]]
function ExpectationMatchers.deepEqual(value, otherValue)
	-- Helper function to perform deep comparison
	local function deepCompare(a, b, path)
		path = path or "root"

		-- If types are different, they're not equal
		if type(a) ~= type(b) then
			return false, string.format(
				"Type mismatch at %s: expected %s, got %s",
				path,
				type(b),
				type(a)
			)
		end

		-- For non-table types, use regular equality
		if type(a) ~= "table" then
			if a ~= b then
				return false, string.format(
					"Value mismatch at %s: expected %s, got %s",
					path,
					tostring(b),
					tostring(a)
				)
			end
			return true
		end

		-- For tables, check all keys recursively
		-- First, check that all keys in 'a' exist in 'b' with same values
		for key, valueA in pairs(a) do
			local valueB = b[key]
			local newPath = path .. "." .. tostring(key)

			if valueB == nil then
				return false, string.format(
					"Missing key at %s in expected table",
					newPath
				)
			end

			local success, err = deepCompare(valueA, valueB, newPath)
			if not success then
				return false, err
			end
		end

		-- Then, check that 'b' doesn't have extra keys
		for key, _ in pairs(b) do
			if a[key] == nil then
				return false, string.format(
					"Unexpected key at %s.%s in actual table",
					path,
					tostring(key)
				)
			end
		end

		return true
	end

	-- Perform the comparison
	local success, errorMessage = deepCompare(value, otherValue)

	return {
		pass = success,
		message = success
			and "Expected tables not to be deeply equal"
			or ("Expected tables to be deeply equal:\n" .. errorMessage)
	}
end

--[[
	Check if a value contains another value
	Works with strings (substring) and tables (element)
]]
function ExpectationMatchers.include(value, searchValue)
	local valueType = type(value)
	local pass = false
	local message = ""

	if valueType == "string" then
		-- String contains substring
		-- Use string.find with plain text search (not pattern matching)
		local searchType = type(searchValue)
		if searchType ~= "string" then
			pass = false
			message = string.format(
				"Cannot search for %s in string (searchValue must be a string)",
				searchType
			)
		else
			pass = string.find(value, searchValue, 1, true) ~= nil
			message = pass
				and string.format("Expected string not to contain %q", searchValue)
				or string.format("Expected string to contain %q, but got %q", searchValue, value)
		end
	elseif valueType == "table" then
		-- Table contains element
		pass = false
		for _, element in pairs(value) do
			if element == searchValue then
				pass = true
				break
			end
		end

		message = pass
			and string.format("Expected table not to contain %s", tostring(searchValue))
			or string.format("Expected table to contain %s", tostring(searchValue))
	else
		-- Unsupported type
		pass = false
		message = string.format(
			"include() only works with strings and tables, got %s",
			valueType
		)
	end

	return {
		pass = pass,
		message = message
	}
end

-- Alias for include
ExpectationMatchers.contain = ExpectationMatchers.include

--[[
	Check the length of a string or table
]]
function ExpectationMatchers.lengthOf(value, expectedLength)
	local valueType = type(value)
	local pass = false
	local message = ""

	-- Validate expectedLength is a number
	if type(expectedLength) ~= "number" then
		pass = false
		message = string.format(
			"lengthOf() requires a number, got %s",
			type(expectedLength)
		)
	elseif valueType == "string" then
		-- String length using string.len or #
		local actualLength = string.len(value)
		pass = actualLength == expectedLength

		message = pass
			and string.format("Expected string not to have length %d", expectedLength)
			or string.format("Expected string to have length %d, but got %d", expectedLength, actualLength)
	elseif valueType == "table" then
		-- Table length using #
		local actualLength = #value
		pass = actualLength == expectedLength

		message = pass
			and string.format("Expected table not to have length %d", expectedLength)
			or string.format("Expected table to have length %d, but got %d", expectedLength, actualLength)
	else
		-- Unsupported type
		pass = false
		message = string.format(
			"lengthOf() only works with strings and tables, got %s",
			valueType
		)
	end

	return {
		pass = pass,
		message = message
	}
end

--[[
	Numeric comparison matchers
]]

function ExpectationMatchers.greaterThan(value, compareValue)
	-- Validate both values are numbers
	if type(value) ~= "number" then
		return {
			pass = false,
			message = string.format("greaterThan() requires value to be a number, got %s", type(value))
		}
	end

	if type(compareValue) ~= "number" then
		return {
			pass = false,
			message = string.format("greaterThan() requires compareValue to be a number, got %s", type(compareValue))
		}
	end

	local pass = value > compareValue

	return {
		pass = pass,
		message = pass
			and string.format("Expected %s not to be greater than %s", tostring(value), tostring(compareValue))
			or string.format("Expected %s to be greater than %s", tostring(value), tostring(compareValue))
	}
end

ExpectationMatchers.above = ExpectationMatchers.greaterThan

function ExpectationMatchers.lessThan(value, compareValue)
	-- Validate both values are numbers
	if type(value) ~= "number" then
		return {
			pass = false,
			message = string.format("lessThan() requires value to be a number, got %s", type(value))
		}
	end

	if type(compareValue) ~= "number" then
		return {
			pass = false,
			message = string.format("lessThan() requires compareValue to be a number, got %s", type(compareValue))
		}
	end

	local pass = value < compareValue

	return {
		pass = pass,
		message = pass
			and string.format("Expected %s not to be less than %s", tostring(value), tostring(compareValue))
			or string.format("Expected %s to be less than %s", tostring(value), tostring(compareValue))
	}
end

ExpectationMatchers.below = ExpectationMatchers.lessThan

function ExpectationMatchers.greaterThanOrEqual(value, compareValue)
	-- Validate both values are numbers
	if type(value) ~= "number" then
		return {
			pass = false,
			message = string.format("greaterThanOrEqual() requires value to be a number, got %s", type(value))
		}
	end

	if type(compareValue) ~= "number" then
		return {
			pass = false,
			message = string.format("greaterThanOrEqual() requires compareValue to be a number, got %s", type(compareValue))
		}
	end

	local pass = value >= compareValue

	return {
		pass = pass,
		message = pass
			and string.format("Expected %s not to be greater than or equal to %s", tostring(value), tostring(compareValue))
			or string.format("Expected %s to be greater than or equal to %s", tostring(value), tostring(compareValue))
	}
end

ExpectationMatchers.atLeast = ExpectationMatchers.greaterThanOrEqual

function ExpectationMatchers.lessThanOrEqual(value, compareValue)
	-- Validate both values are numbers
	if type(value) ~= "number" then
		return {
			pass = false,
			message = string.format("lessThanOrEqual() requires value to be a number, got %s", type(value))
		}
	end

	if type(compareValue) ~= "number" then
		return {
			pass = false,
			message = string.format("lessThanOrEqual() requires compareValue to be a number, got %s", type(compareValue))
		}
	end

	local pass = value <= compareValue

	return {
		pass = pass,
		message = pass
			and string.format("Expected %s not to be less than or equal to %s", tostring(value), tostring(compareValue))
			or string.format("Expected %s to be less than or equal to %s", tostring(value), tostring(compareValue))
	}
end

ExpectationMatchers.atMost = ExpectationMatchers.lessThanOrEqual

--[[
	Check if value is empty (empty table or empty string)
	For tables: checks if table has no key-value pairs
	For strings: checks if string length is 0
]]
function ExpectationMatchers.empty(value)
	local valueType = type(value)

	-- Only tables and strings can be empty
	if valueType ~= "table" and valueType ~= "string" then
		return {
			pass = false,
			message = string.format("empty() requires a table or string, got %s", valueType)
		}
	end

	local isEmpty

	if valueType == "table" then
		-- Check if table has any key-value pairs
		isEmpty = next(value) == nil
	else -- string
		isEmpty = #value == 0
	end

	return {
		pass = isEmpty,
		message = isEmpty
			and string.format("Expected %s not to be empty", valueType)
			or string.format("Expected %s to be empty", valueType)
	}
end

--[[
	Match string against Lua pattern
	Uses string.match() for pattern matching
]]
function ExpectationMatchers.match(value, pattern)
	if type(value) ~= "string" then
		return {
			pass = false,
			message = string.format("match() requires a string, got %s", type(value))
		}
	end

	if type(pattern) ~= "string" then
		return {
			pass = false,
			message = string.format("match() requires pattern to be a string, got %s", type(pattern))
		}
	end

	local matchResult = string.match(value, pattern)
	local didMatch = matchResult ~= nil

	return {
		pass = didMatch,
		message = didMatch
			and string.format("Expected '%s' not to match pattern '%s'", value, pattern)
			or string.format("Expected '%s' to match pattern '%s'", value, pattern)
	}
end

--[[
	Check if object has a property (optionally with a specific value)
	For tables only
]]
function ExpectationMatchers.property(value, propertyName, expectedValue)
	if type(value) ~= "table" then
		return {
			pass = false,
			message = string.format("property() requires a table, got %s", type(value))
		}
	end

	if type(propertyName) ~= "string" and type(propertyName) ~= "number" then
		return {
			pass = false,
			message = string.format("property() requires propertyName to be a string or number, got %s", type(propertyName))
		}
	end

	local propertyValue = value[propertyName]
	local hasProperty = propertyValue ~= nil

	-- If no expected value provided, just check if property exists
	if expectedValue == nil then
		return {
			pass = hasProperty,
			message = hasProperty
				and string.format("Expected table not to have property '%s'", tostring(propertyName))
				or string.format("Expected table to have property '%s'", tostring(propertyName))
		}
	end

	-- If expected value provided, check both existence and value
	local valueMatches = propertyValue == expectedValue

	return {
		pass = hasProperty and valueMatches,
		message = (hasProperty and valueMatches)
			and string.format("Expected table not to have property '%s' with value %s", tostring(propertyName), tostring(expectedValue))
			or (not hasProperty)
				and string.format("Expected table to have property '%s'", tostring(propertyName))
				or string.format("Expected property '%s' to have value %s, got %s", tostring(propertyName), tostring(expectedValue), tostring(propertyValue))
	}
end

--[[
	Check if number is within a range (inclusive)
	min <= value <= max
]]
function ExpectationMatchers.within(value, min, max)
	if type(value) ~= "number" then
		return {
			pass = false,
			message = string.format("within() requires a number, got %s", type(value))
		}
	end

	if type(min) ~= "number" then
		return {
			pass = false,
			message = string.format("within() requires min to be a number, got %s", type(min))
		}
	end

	if type(max) ~= "number" then
		return {
			pass = false,
			message = string.format("within() requires max to be a number, got %s", type(max))
		}
	end

	local isWithin = value >= min and value <= max

	return {
		pass = isWithin,
		message = isWithin
			and string.format("Expected %s not to be within %s..%s", tostring(value), tostring(min), tostring(max))
			or string.format("Expected %s to be within %s..%s", tostring(value), tostring(min), tostring(max))
	}
end

--[[
	Check if value is one of the values in a list
	Uses equality comparison (==)
]]
function ExpectationMatchers.oneOf(value, list)
	if type(list) ~= "table" then
		return {
			pass = false,
			message = string.format("oneOf() requires list to be a table, got %s", type(list))
		}
	end

	-- Check if list is empty
	if next(list) == nil then
		return {
			pass = false,
			message = "oneOf() requires a non-empty list"
		}
	end

	-- Check if value is in the list
	local found = false
	for _, item in pairs(list) do
		if value == item then
			found = true
			break
		end
	end

	-- Build list representation for message
	local listStr = "{"
	local first = true
	for _, item in pairs(list) do
		if not first then
			listStr = listStr .. ", "
		end
		listStr = listStr .. tostring(item)
		first = false
	end
	listStr = listStr .. "}"

	return {
		pass = found,
		message = found
			and string.format("Expected %s not to be one of %s", tostring(value), listStr)
			or string.format("Expected %s to be one of %s", tostring(value), listStr)
	}
end

--[[
	Check if string starts with a prefix
	Case sensitive
]]
function ExpectationMatchers.startWith(value, prefix)
	if type(value) ~= "string" then
		return {
			pass = false,
			message = string.format("startWith() requires a string, got %s", type(value))
		}
	end

	if type(prefix) ~= "string" then
		return {
			pass = false,
			message = string.format("startWith() requires prefix to be a string, got %s", type(prefix))
		}
	end

	-- Empty prefix always matches
	if #prefix == 0 then
		return {
			pass = true,
			message = string.format("Expected '%s' not to start with ''", value)
		}
	end

	-- Use string.sub to check if the beginning matches
	local doesStartWith = string.sub(value, 1, #prefix) == prefix

	return {
		pass = doesStartWith,
		message = doesStartWith
			and string.format("Expected '%s' not to start with '%s'", value, prefix)
			or string.format("Expected '%s' to start with '%s'", value, prefix)
	}
end

--[[
	Check if string ends with a suffix
	Case sensitive
]]
function ExpectationMatchers.endWith(value, suffix)
	if type(value) ~= "string" then
		return {
			pass = false,
			message = string.format("endWith() requires a string, got %s", type(value))
		}
	end

	if type(suffix) ~= "string" then
		return {
			pass = false,
			message = string.format("endWith() requires suffix to be a string, got %s", type(suffix))
		}
	end

	-- Empty suffix always matches
	if #suffix == 0 then
		return {
			pass = true,
			message = string.format("Expected '%s' not to end with ''", value)
		}
	end

	-- Use string.sub to check if the ending matches
	local doesEndWith = string.sub(value, -#suffix) == suffix

	return {
		pass = doesEndWith,
		message = doesEndWith
			and string.format("Expected '%s' not to end with '%s'", value, suffix)
			or string.format("Expected '%s' to end with '%s'", value, suffix)
	}
end

--[[
	Check if value is nil
	More explicit than using .never.to.be.ok()
]]
function ExpectationMatchers.nilValue(value)
	local isNil = value == nil

	return {
		pass = isNil,
		message = isNil
			and "Expected value not to be nil"
			or string.format("Expected nil, got %s", tostring(value))
	}
end

--[[
	Check if value is exactly true (not just truthy)
]]
function ExpectationMatchers.trueValue(value)
	local isTrue = value == true

	return {
		pass = isTrue,
		message = isTrue
			and "Expected value not to be true"
			or string.format("Expected true, got %s", tostring(value))
	}
end

--[[
	Check if value is exactly false (not just falsy)
]]
function ExpectationMatchers.falseValue(value)
	local isFalse = value == false

	return {
		pass = isFalse,
		message = isFalse
			and "Expected value not to be false"
			or string.format("Expected false, got %s", tostring(value))
	}
end

--[[
	Check if value is NaN (Not a Number)
]]
function ExpectationMatchers.NaN(value)
	if type(value) ~= "number" then
		return {
			pass = false,
			message = string.format("NaN() requires a number, got %s", type(value))
		}
	end

	-- In Lua, NaN is the only value that is not equal to itself
	local isNaN = value ~= value

	return {
		pass = isNaN,
		message = isNaN
			and "Expected value not to be NaN"
			or string.format("Expected NaN, got %s", tostring(value))
	}
end

--[[
	Check if table has specific keys
]]
function ExpectationMatchers.keys(value, ...)
	if type(value) ~= "table" then
		return {
			pass = false,
			message = string.format("keys() requires a table, got %s", type(value))
		}
	end

	local expectedKeys = {...}

	if #expectedKeys == 0 then
		return {
			pass = false,
			message = "keys() requires at least one key"
		}
	end

	-- Check if all expected keys exist
	for _, key in ipairs(expectedKeys) do
		if value[key] == nil then
			return {
				pass = false,
				message = string.format("Expected table to have key '%s'", tostring(key))
			}
		end
	end

	-- Build keys list for message
	local keysList = table.concat(expectedKeys, ", ")

	return {
		pass = true,
		message = string.format("Expected table not to have keys: %s", keysList)
	}
end

--[[
	Check if array contains all members of another array (unordered)
]]
function ExpectationMatchers.members(value, expectedMembers)
	if type(value) ~= "table" then
		return {
			pass = false,
			message = string.format("members() requires a table, got %s", type(value))
		}
	end

	if type(expectedMembers) ~= "table" then
		return {
			pass = false,
			message = string.format("members() requires expectedMembers to be a table, got %s", type(expectedMembers))
		}
	end

	-- Create a set of actual members for quick lookup
	local actualSet = {}
	for _, member in pairs(value) do
		actualSet[member] = true
	end

	-- Check if all expected members are in the actual set
	for _, member in pairs(expectedMembers) do
		if not actualSet[member] then
			return {
				pass = false,
				message = string.format("Expected array to contain member %s", tostring(member))
			}
		end
	end

	-- Check if all actual members are in the expected set
	local expectedSet = {}
	for _, member in pairs(expectedMembers) do
		expectedSet[member] = true
	end

	for _, member in pairs(value) do
		if not expectedSet[member] then
			return {
				pass = false,
				message = string.format("Expected array not to contain member %s", tostring(member))
			}
		end
	end

	return {
		pass = true,
		message = "Expected arrays not to have the same members"
	}
end

return ExpectationMatchers
