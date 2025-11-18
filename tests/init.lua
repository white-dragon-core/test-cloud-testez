-- only for test

-- Main module entry point
local Module = {}

-- Re-export submodules
Module.MathUtils = require(script.MathUtils)
Module.StringUtils = require(script.StringUtils)

return Module
