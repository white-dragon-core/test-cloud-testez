--[[
	两层细化定位测试脚本

	架构：
	- 第一层（0-15秒）：文件级测试，每帧一个 ModuleScript
	- 第二层（15-50秒）：测试用例级测试，每帧一个 it

	Session ID: {{SESSION_ID}}
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local HttpService = game:GetService("HttpService")

-- 设置云端测试标志
_G.__isInCloud__ = true

-- Session ID（由 JS 注入）
local sessionId = "{{SESSION_ID}}"
local store = MemoryStoreService:GetSortedMap("test-results-" .. sessionId)

-- 立即保存脚本启动标记
print("[INIT] 脚本开始执行...")
pcall(function()
	store:SetAsync("script-started", HttpService:JSONEncode({
		started = true,
		timestamp = os.time(),
		sessionId = sessionId
	}), 3600)
end)

-- ==================== 全局状态 ====================
local phase = "LAYER1" -- LAYER1 | LAYER2 | DONE
local globalStartTime = os.clock()
local layer1TimeLimit = 5 -- 增加到30秒，给更多文件测试时间
local layer2TimeLimit = 10 -- 总共90秒

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
	pcall(function()
		store:SetAsync("testez-load-error", HttpService:JSONEncode({
			error = "Failed to load TestEZ",
			message = tostring(err),
			hasPackages = ReplicatedStorage:FindFirstChild("Packages") ~= nil,
			hasRbxtsInclude = ReplicatedStorage:FindFirstChild("rbxts_include") ~= nil
		}), 3600)
	end)
	error("Failed to load TestEZ: " .. tostring(err))
end

print("[INIT] ✓ TestEZ 加载成功")
pcall(function()
	store:SetAsync("testez-loaded", HttpService:JSONEncode({loaded = true}), 3600)
end)

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




-- 保存第二层结果到 MemoryStore
local function saveLayer2Result(index, item, status, elapsed)
	local key = string.format("layer2-it-%03d", index)
	local data = {
		index = index,
		file = item.file,
		filePath = item.filePath,
		itName = item.itName,
		status = status,
		elapsed = elapsed
	}

	pcall(function()
		store:SetAsync(key, HttpService:JSONEncode(data), 3600)
	end)
end

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

	pcall(function()
		store:SetAsync("layer1-summary", HttpService:JSONEncode(layer1Summary), 3600)
		store:SetAsync("layer2-summary", HttpService:JSONEncode(layer2Summary), 3600)
	end)
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

		-- 保存错误信息到 MemoryStore
		local scannedDirs = {}
		for _, scanInfo in ipairs(scanDirs) do
			table.insert(scannedDirs, scanInfo.name)
		end

		pcall(function()
			store:SetAsync("error-no-files", HttpService:JSONEncode({
				error = "No test files found",
				scannedDirs = scannedDirs,
				hasRbxtsInclude = ReplicatedStorage:FindFirstChild("rbxts_include") ~= nil,
				hasLib = ReplicatedStorage:FindFirstChild("Lib") ~= nil,
				hasTS = ReplicatedStorage:FindFirstChild("TS") ~= nil
			}), 3600)
		end)
	end
end

-- 运行单个文件测试（非阻塞）
local function startFileTest()
	currentFileIndex = currentFileIndex + 1
	
	if currentFileIndex > #allTestFiles then
		return false
	end

	local file = allTestFiles[currentFileIndex]
	print(string.format("[Layer1] 测试 [%d/%d]: %s", currentFileIndex, #allTestFiles, file.Name))

	currentFileStartTime[currentFileIndex] = os.clock()

	pcall(function()
		return TestEZ.TestBootstrap:run({file}, TextReporter)
	end)
	return true
end


-- ==================== 第二层：测试用例级测试 ====================

-- 初始化第二层
local function initLayer2()

	if(#layer1Timeout==0) then
		return
	end

	print(string.format("\n[Layer2] 开始解析 %d 个超时文件", #layer2Queue))

	for _, file in ipairs(layer1Timeout) do
		local success, source = pcall(function()
			return file.Source
		end)

		if success and source then
			local itNames = extractItNames(source)
			print(string.format("[Layer2] 文件 %s: 找到 %d 个 it 测试", file.Name, #itNames))

			for _, itName in ipairs(itNames) do
				table.insert(layer2Queue, {
					file = file.Name,
					filePath = file:GetFullName(),
					fileModule = file,
					itName = itName
				})
			end
		end
	end

	print(string.format("[Layer2] 总共 %d 个 it 测试待测试\n", #layer2Queue))
end

-- 运行单个 it 测试（非阻塞）
local function startItTest()
	if currentItIndex > #layer2Queue then
		return false
	end

	local item = layer2Queue[currentItIndex]
	print(string.format("[Layer2] 测试 [%d/%d]: %s > %s",
		currentItIndex, #layer2Queue, item.file, item.itName))

	currentItStartTime = os.clock()
	currentItCompleted = false
	currentItResult = nil

	-- 异步运行测试（使用 pattern）
	currentItTask = task.spawn(function()
		local success, results = pcall(function()
			-- TestEZ 支持 pattern 参数
			return TestEZ.TestBootstrap:run({item.fileModule}, TextReporter, item.itName)
		end)

		if success and results.failureCount == 0 then
			currentItResult = "passed"
		else
			currentItResult = "failed"
		end

		currentItCompleted = true
	end)

	return true
end

-- 检查 it 测试状态
local function checkItTest()

	if(currentItStartTime == nil) then
		currentItStartTime  = os.clock()	
	end

	local elapsed = os.clock() - currentItStartTime

	-- 检查超时（10 秒）
	if elapsed >= 10 then
		local item = layer2Queue[currentItIndex]
		table.insert(layer2Timeout, item)
		saveLayer2Result(currentItIndex, item, "timeout", elapsed)
		print(string.format("[Layer2] ✗ 超时: %s > %s (%.1fs)", item.file, item.itName, elapsed))

		currentItIndex = currentItIndex + 1
		return startItTest()
	end

	-- 检查是否完成
	if currentItCompleted then
		local item = layer2Queue[currentItIndex]

		if currentItResult == "passed" then
			table.insert(layer2Passed, item)
			saveLayer2Result(currentItIndex, item, "passed", elapsed)
			print(string.format("[Layer2] ✓ 通过: %s > %s (%.1fs)", item.file, item.itName, elapsed))
		else
			table.insert(layer2Timeout, item)
			saveLayer2Result(currentItIndex, item, "timeout", elapsed)
			print(string.format("[Layer2] ✗ 失败/超时: %s > %s (%.1fs)", item.file, item.itName, elapsed))
		end

		currentItIndex = currentItIndex + 1
		return startItTest()
	end

	return true
end

-- ==================== 主循环 ====================

-- 初始化第一层
initLayer1()

-- 如果没有测试文件，立即进入完成状态
if #allTestFiles == 0 then
	print("[WARN] 没有测试文件，立即完成")
	saveSummary()
	return "Two-layer test completed (no files found). Results saved to MemoryStore: " .. sessionId
end

-- Heartbeat 主循环
local connection
connection = RunService.Heartbeat:Connect(function()
	local elapsed = os.clock() - globalStartTime

	if phase == "LAYER1" then
		-- 第一层：文件级测试
		if elapsed >= layer1TimeLimit then
			print(string.format("\n[Layer1] 时间限制已到 (%.1fs)，进入第二层", elapsed))
			phase = "LAYER2"
			saveSummary()
			initLayer2()
			if #layer2Queue > 0 then
				startItTest()
			else
				print("[Layer2] 没有超时文件，直接完成")
				phase = "DONE"
				connection:Disconnect()
				saveSummary()
			end
		else
			
			local continuing = startFileTest()
			-- 所有测试已经完成了
			if not continuing then
				phase = "LAYER2"
				saveSummary()
				initLayer2()
				if #layer2Queue > 0 then
					print(string.format("\n[Layer1] 所有文件测试完成 (%.1fs)，进入第二层, %d 个 it 测试待测试", elapsed, #layer2Queue))
					startItTest()
				else
					print("[Layer2] 没有超时文件，直接完成")
					phase = "DONE"
					connection:Disconnect()
					saveSummary()
				end
			end
		end

	elseif phase == "LAYER2" then
		-- 第二层：it 级测试
		if elapsed >= layer2TimeLimit then
			print(string.format("\n[Layer2] 总时间限制已到 (%.1fs)，结束测试", elapsed))
			phase = "DONE"
			connection:Disconnect()
			saveSummary()
		else
			local continuing = checkItTest()
			if not continuing then
				print(string.format("\n[Layer2] 所有 it 测试完成 (%.1fs)，结束测试", elapsed))
				phase = "DONE"
				connection:Disconnect()
				saveSummary()
			end
		end
	end
end)

-- 等待测试完成
print("[MAIN] 等待测试完成...")
local maxWaitTime = 100 -- 最多等待100秒
local waited = 0

while phase ~= "DONE" and waited < maxWaitTime do
	task.wait(0.5)
	waited = waited + 0.5
end

if phase == "DONE" then
	print(string.format("[MAIN] 测试完成! 总用时: %.1fs", os.clock() - globalStartTime))
else
	print(string.format("[MAIN] 测试超时! 等待了 %d 秒", maxWaitTime))
	-- 强制断开连接
	if connection then
		pcall(function() connection:Disconnect() end)
	end
	saveSummary()
end

-- 返回占位符（实际结果在 MemoryStore 中）
return "Two-layer test completed. Results saved to MemoryStore: " .. sessionId
