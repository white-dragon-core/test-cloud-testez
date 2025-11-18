local Expectation = require(script.Parent.Expectation)
local checkMatcherNameCollisions = Expectation.checkMatcherNameCollisions

local function copy(t)
	local result = {}

	for key, value in pairs(t) do
		result[key] = value
	end

	return result
end

local ExpectationContext = {}
ExpectationContext.__index = ExpectationContext

function ExpectationContext.new(parent)
	local self = {
		_extensions = parent and copy(parent._extensions) or {},
	}

	-- Auto-load extended matchers on the root context (when parent is nil)
	if not parent then
		-- Load extended matchers module
		local success, ExtendedMatchers = pcall(function()
			return require(script.Parent.ExpectationMatchers)
		end)

		-- If the module exists, register all matchers
		if success and ExtendedMatchers then
			for key, value in pairs(ExtendedMatchers) do
				self._extensions[key] = value
			end
		end
	end

	return setmetatable(self, ExpectationContext)
end

function ExpectationContext:startExpectationChain(...)
	return Expectation.new(...):extend(self._extensions)
end

function ExpectationContext:extend(config)
	for key, value in pairs(config) do
		assert(self._extensions[key] == nil, string.format("Cannot reassign %q in expect.extend", key))
		assert(checkMatcherNameCollisions(key), string.format("Cannot overwrite matcher %q; it already exists", key))

		self._extensions[key] = value
	end
end

return ExpectationContext
