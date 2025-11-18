local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

if not RunService:IsRunMode() then
	return
end

-- 设置 _G.print 和 _G.warn，使测试文件可以使用它们
-- (在 cloud-test.lua 中也有相同的设置，保持一致性)
_G.print = print
_G.warn = warn

-- 检测项目类型并加载 TestEZ
local function loadTestEZ()
	return require(game.ReplicatedStorage.rbxts_include.node_modules["@rbxts"]["test-cloud-testez"])

end

-- 检查 test-target 引用
local testTarget = script.Parent:FindFirstChild("test-target")
local targetDirs = {}
local useTestTarget = false

if testTarget and testTarget:IsA("ObjectValue") and testTarget.Value then
	local value = testTarget.Value
	-- 支持 ModuleScript、Folder、Configuration 等任何 Instance
	table.insert(targetDirs, value)
	print("📍 使用 test-target 指定的目标:", value:GetFullName())
	useTestTarget = true
end

-- 只有在没有通过 test-target 指定时，才使用默认目录
if not useTestTarget then
	print("📍 扫描默认测试目录...")

	-- 默认测试目标：ReplicatedStorage 和 ServerScriptService
	local candidateTargets = {
		{name = "ReplicatedStorage", instance = ReplicatedStorage},
		{name = "ServerScriptService", instance = ServerScriptService},
	}

	-- 收集存在的目标
	for _, candidate in ipairs(candidateTargets) do
		if candidate.instance then
			table.insert(targetDirs, candidate.instance)
			print("  ✓ 找到:", candidate.name)
		else
			print("  ✗ 未找到:", candidate.name)
		end
	end

	if #targetDirs > 0 then
		print("📍 将测试", #targetDirs, "个默认目录")
	else
		warn("⚠️ 未找到任何默认测试目录")
	end
end

-- 引入 testez 运行单元测试
if #targetDirs > 0 then
	local TestEZ = loadTestEZ()
	TestEZ.TestBootstrap:run(targetDirs, nil)
else
	warn("⚠️ 未找到测试目标")
end