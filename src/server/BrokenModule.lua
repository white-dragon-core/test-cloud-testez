-- BrokenModule: 一个故意包含运行时错误的模块
-- 用于测试 TestEZ 是否能正确捕获 require() 错误，并提供详细的错误位置信息

local BrokenModule = {}

-- 辅助函数，用于模拟深层调用堆栈
local function deepFunction()
	-- 这里故意使用一个不存在的全局变量来触发运行时错误
	-- 错误应该被准确定位到这一行
	local value = THIS_DOES_NOT_EXIST.someProperty
	return value
end

-- 中间层函数
function BrokenModule.init()
	-- 调用会触发错误的函数
	return deepFunction()
end

-- 模块加载时就执行，会立即触发错误
BrokenModule.init()

return BrokenModule
