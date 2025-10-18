--[[
	两层细化定位测试脚本

	架构：
	- 第一层（0-15秒）：文件级测试，每帧一个 ModuleScript
	- 第二层（15-50秒）：测试用例级测试，每帧一个 it

	Session ID: {{SESSION_ID}}
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- 设置云端测试标志
_G.__isInCloud__ = true

-- Session ID（由 JS 注入）
local sessionId = "{{SESSION_ID}}"

-- 立即保存脚本启动标记
print("[INIT] 脚本开始执行...")


-- ==================== 全局状态 ====================
local phase = "LAYER1" -- LAYER1 | LAYER2 | DONE
local globalStartTime = os.clock()
local layer1TimeLimit = 15 -- 增加到30秒，给更多文件测试时间
local layer2TimeLimit = 30 -- 总共90秒

-- 第一层状态
local allTestFiles = {}
local currentFileIndex = 1
local currentFileStartTime = {}
local layer1Passed = {}
local layer1Timeout = {}

-- 第二层状态
local layer2Queue = {} -- {file = ..., filePath = ..., itName = ...}
local currentItIndex = 1
local currentItStartTime = nil
local currentItTask = nil
local currentItCompleted = false
local currentItResult = nil
local layer2Passed = {}
local layer2Timeout = {}

-- ==================== 加载 TestEZ ====================
local TestEZ
local function loadTestEZ()
	-- 尝试从多个位置加载 TestEZ
	if ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("testez") then
		TestEZ = require(ReplicatedStorage.Packages.testez)
		return
	end

	if ReplicatedStorage:FindFirstChild("rbxts_include") then
		local nodeModules = ReplicatedStorage.rbxts_include:FindFirstChild("node_modules")
		if nodeModules then
			local rbxts = nodeModules:FindFirstChild("@rbxts")
			if rbxts and rbxts:FindFirstChild("testez") then
				local testezModule = rbxts.testez
				if testezModule:FindFirstChild("src") then
					TestEZ = require(testezModule.src)
					return
				else
					TestEZ = require(testezModule)
					return
				end
			end

			if nodeModules:FindFirstChild("testez") then
				local testezModule = nodeModules.testez
				if testezModule:FindFirstChild("src") then
					TestEZ = require(testezModule.src)
					return
				else
					TestEZ = require(testezModule)
					return
				end
			end
		end
	end

	error("TestEZ not found")
end

local success, err = pcall(loadTestEZ)
if not success then
	print("[INIT] ❌ TestEZ 加载失败: " .. tostring(err))
	
	error("Failed to load TestEZ: " .. tostring(err))
end

print("[INIT] ✓ TestEZ 加载成功")


-- ==================== 工具函数 ====================

-- 递归扫描测试文件
local function scanTestFiles(parent:Part)
	local testFiles = {}

	for _, child in ipairs(parent:GetDescendants()) do
		if child:IsA("ModuleScript") and child.Name:lower():find("%.spec") then
			table.insert(testFiles, child)
		end
	end

	return testFiles
end

-- 解析源码提取 it 测试名称
local function extractItNames(sourceCode)
	local itNames = {}

	-- 匹配 it("name", ...) 或 it('name', ...)
	for itName in string.gmatch(sourceCode, 'it%s*%(["\']([^"\']+)["\']') do
		table.insert(itNames, itName)
	end

	return itNames
end


local TextReporter = require(game.ReplicatedStorage.rbxts_include.node_modules["@rbxts"].testez.src.Reporters.TextReporter)




-- 保存汇总信息
local function saveSummary()
	local layer1Summary = {
		total = #allTestFiles,
		passed = #layer1Passed,
		timeout = #layer1Timeout
	}

	local layer2Summary = {
		total = #layer2Queue,
		passed = #layer2Passed,
		timeout = #layer2Timeout
	}

	
end

-- ==================== 第一层：文件级测试 ====================

-- 初始化第一层
local function initLayer1()
	-- 打印调试信息
	print("[Layer1] 开始初始化...")
	print(string.format("[Layer1] 检查目录: rbxts_include=%s, Lib=%s, Packages=%s, TS=%s",
		tostring(ReplicatedStorage:FindFirstChild("rbxts_include") ~= nil),
		tostring(ReplicatedStorage:FindFirstChild("Lib") ~= nil),
		tostring(ReplicatedStorage:FindFirstChild("Packages") ~= nil),
		tostring(ReplicatedStorage:FindFirstChild("TS") ~= nil)
	))

	-- 扫描所有可能包含测试的目录
	local scanDirs = {}

	-- 优先级1: 特定包目录
	if ReplicatedStorage:FindFirstChild("rbxts_include") then
		local nodeModules = ReplicatedStorage.rbxts_include:FindFirstChild("node_modules")
		if nodeModules and nodeModules:FindFirstChild("@white-dragon-bevy") then
			table.insert(scanDirs, {
				dir = nodeModules["@white-dragon-bevy"],
				name = "rbxts_include/node_modules/@white-dragon-bevy"
			})
		end
	end

	-- 优先级2: TypeScript 项目目录
	if ReplicatedStorage:FindFirstChild("TS") then
		table.insert(scanDirs, {
			dir = ReplicatedStorage.TS,
			name = "TS"
		})
	end

	-- 优先级3: rbxts_include（如果没有找到@white-dragon-bevy）
	if ReplicatedStorage:FindFirstChild("rbxts_include") and #scanDirs == 0 then
		table.insert(scanDirs, {
			dir = ReplicatedStorage.rbxts_include,
			name = "rbxts_include"
		})
	end

	-- 优先级4: Lua 项目目录
	if ReplicatedStorage:FindFirstChild("Lib") then
		table.insert(scanDirs, {
			dir = ReplicatedStorage.Lib,
			name = "Lib"
		})
	end

	-- 优先级5: 如果没有找到任何预期目录，扫描整个 ReplicatedStorage
	if #scanDirs == 0 then
		print("[Layer1] ⚠️ 未找到预期目录，尝试扫描 ReplicatedStorage 根目录")
		table.insert(scanDirs, {
			dir = ReplicatedStorage,
			name = "ReplicatedStorage"
		})
	end

	-- 扫描所有目录并合并测试文件
	allTestFiles = {}
	for _, scanInfo in ipairs(scanDirs) do
		print(string.format("[Layer1] 扫描目录: %s", scanInfo.name))
		local files = scanTestFiles(scanInfo.dir)
		print(string.format("[Layer1] 在 %s 中找到 %d 个测试文件", scanInfo.name, #files))

		for _, file in ipairs(files) do
			table.insert(allTestFiles, file)
		end
	end

	print(string.format("[Layer1] 总共找到 %d 个测试文件", #allTestFiles))

	-- 如果没有找到测试文件，保存错误信息
	if #allTestFiles == 0 then
		print("[Layer1] ⚠️ 警告: 没有找到任何测试文件")

		-- 列出所有扫描目录的直接子对象
		for _, scanInfo in ipairs(scanDirs) do
			print(string.format("[Layer1] %s 的直接子对象:", scanInfo.name))
			for _, child in ipairs(scanInfo.dir:GetChildren()) do
				local isSpec = child:IsA("ModuleScript") and child.Name:lower():find("%.spec")
				print(string.format("  - %s (%s) %s", child.Name, child.ClassName, isSpec and "[.spec]" or ""))
			end
		end

		
	end
end



initLayer1()




game:GetService("RunService").Heartbeat:Connect(function()


	if currentFileIndex > #allTestFiles then
		return
	end

	local file = allTestFiles[currentFileIndex]
	print(string.format("[Layer1] 测试 [%d/%d]: %s", currentFileIndex, #allTestFiles, file.Name))

	local success, result = pcall(function()
		 TestEZ.TestBootstrap:run({file}, TextReporter)
		 return true
	end)
	if not success then
		print(string.format("[Layer1] 测试失败: %s", result))
		return
	end

	
	currentFileIndex +=1
	
end)