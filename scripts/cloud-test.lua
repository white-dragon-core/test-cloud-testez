--[[
	Roblox Cloud 测试执行脚本

	功能说明：
	1. 在 Roblox Cloud 环境中运行 TestEZ 测试
	2. 使用 SilentReporter 最小化运行时开销
	3. 使用 LogService.MessageOut 捕捉测试执行期间的所有输出
	4. 将测试结果（统计、错误、print消息）编码为 JSON 返回

	为什么使用 LogService？
	- Roblox Cloud Luau Execution API 只捕获脚本的 return 值
	- LogService.MessageOut 可以捕获所有 print/warn 输出（包括测试模块内的）
	- 无需重写全局 print 函数，测试代码可以直接使用 print()

	模板变量：
	- TEST_NAME_PATTERN: 由 JS 脚本注入的测试名称过滤模式（在代码中使用占位符）
	- ROOTS: 测试目录路径（用 ';' 分隔多个路径）
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
if RunService:IsStudio() and not RunService:IsRunMode() then
	return
end

-- 在测试执行前设置全局标志,供 TypeScript 代码检测云端测试环境
_G.__isInCloud__ = true

-- 创建数组来存储 print 输出
local capturedPrintMessages = {}

-- 使用 LogService 捕获所有 print/warn 输出
local LogService = game:GetService("LogService")

-- 连接 MessageOut 事件来捕获所有日志消息
local connection = LogService.MessageOut:Connect(function(message, messageType)
	table.insert(capturedPrintMessages, {
		message = message,
		type = messageType.Name,  -- "MessageOutput", "MessageInfo", "MessageWarning", "MessageError"
		timestamp = os.time()
	})
end)

-- 引入 HttpService（用于 JSON 编码）
local HttpService = game:GetService("HttpService")

-- 从脚本注入获取 roots 路径（多个路径用 ';' 分隔）
local rootsPath = "{{ROOTS}}"
if rootsPath == "" then
	rootsPath = "ServerScriptService;ReplicatedStorage"  -- 默认值
end

-- 辅助函数：分割字符串
local function split(str, sep)
	local parts = {}
	for part in string.gmatch(str, "([^" .. sep .. "]+)") do
		table.insert(parts, part)
	end
	return parts
end

-- 辅助函数：根据路径导航到目标对象
local function navigatePath(pathString)
	local parts = split(pathString, '/')
	local current = game

	for _, part in ipairs(parts) do
		-- 尝试作为 Service
		local success, service = pcall(function()
			return game:GetService(part)
		end)

		if success and service then
			current = service
		else
			-- 否则作为子对象查找
			current = current:FindFirstChild(part)
			if not current then
				return nil, "Path not found: " .. pathString .. " (failed at: " .. part .. ")"
			end
		end
	end

	return current
end

-- 测试目标目录
-- 使用 roots 参数导航到目标目录（支持多个路径，用 ';' 分隔）
local rootPaths = split(rootsPath, ';')
local targetDirs = {}

for _, pathStr in ipairs(rootPaths) do
	local targetDir, navError = navigatePath(pathStr)
	if not targetDir then
		error("Failed to navigate to test directory '" .. pathStr .. "': " .. tostring(navError))
	end

	-- 如果目标目录是 ReplicatedStorage，则尝试自动检测项目类型
	-- 这样保持向后兼容性
	if targetDir == game:GetService("ReplicatedStorage") then
		-- Check if we have rbxts_include or use Lib for Lua projects
		if targetDir:FindFirstChild("rbxts_include") then
			-- TypeScript/roblox-ts project
			-- 优先使用 @white-dragon-bevy 包（如果存在）
			local nodeModules = targetDir.rbxts_include:FindFirstChild("node_modules")
			if nodeModules and nodeModules:FindFirstChild("@white-dragon-bevy") then
				targetDir = nodeModules["@white-dragon-bevy"]
			else
				-- 如果没有找到特定包，使用 rbxts_include（但会扫描所有文件，可能较慢）
				targetDir = targetDir.rbxts_include
			end
		elseif targetDir:FindFirstChild("Lib") then
			-- Lua project
			targetDir = targetDir.Lib
		end
		-- 如果都没有找到，就使用 ReplicatedStorage 本身作为测试目录
	end

	table.insert(targetDirs, targetDir)
end

-- 引入 testez - 从 TestService 加载
local TestEZ
local testezLoadSuccess, testezLoadError = pcall(function()

	TestEZ = require(game.ReplicatedStorage.rbxts_include.node_modules["@rbxts"]["test-cloud-testez"])

end)

if not testezLoadSuccess then
	error("Failed to load TestEZ: " .. tostring(testezLoadError))
end

-- 从脚本注入获取测试名称过滤模式
local testNamePattern = "{{TEST_NAME_PATTERN}}"
if testNamePattern == "" then
	testNamePattern = nil
end

-- 创建静默 Reporter - 不输出任何内容，只返回结果
local SilentReporter = {}
function SilentReporter.report(results)
	-- 什么都不做，只是返回
end

-- 始终使用 SilentReporter 以最小化开销
local reporter = SilentReporter

-- 递归扫描测试文件的函数
local function scanTestFiles(parent)
	local testFiles = {}

	for _, child in ipairs(parent:GetChildren()) do
		-- 检查是否是测试文件（ModuleScript 且名称包含 .spec）
		if child:IsA("ModuleScript") and child.Name:lower():find("%.spec") then
			table.insert(testFiles, child)
		end

		-- 递归扫描所有对象的子对象（包括 ModuleScript）
		-- 因为 Roblox 中 ModuleScript 也可以包含子对象（例如带 init.lua 的目录）
		local success, children = pcall(function() return child:GetChildren() end)
		if success and #children > 0 then
			local subFiles = scanTestFiles(child)
			for _, file in ipairs(subFiles) do
				table.insert(testFiles, file)
			end
		end
	end

	return testFiles
end

-- 文件名匹配函数（不区分大小写）
local function matchesPattern(fileName, pattern)
	-- 使用不区分大小写的纯文本匹配
	return fileName:lower():find(pattern:lower(), 1, true) ~= nil
end

-- 根据 pattern 决定要测试的目标
local testTargets
local testOptions

-- 扫描所有目标目录中的测试文件
local allTestFiles = {}
for _, targetDir in ipairs(targetDirs) do
	local filesInDir = scanTestFiles(targetDir)
	for _, file in ipairs(filesInDir) do
		table.insert(allTestFiles, file)
	end
end

if testNamePattern then
	-- 扫描并过滤测试文件
	testTargets = {}
	for _, testFile in ipairs(allTestFiles) do
		if matchesPattern(testFile.Name, testNamePattern) then
			table.insert(testTargets, testFile)
		end
	end

	-- 如果没有匹配的文件，返回友好提示（带完整列表）
	if #testTargets == 0 then
		-- 构建完整文件列表用于错误信息
		local testFilesList = {}
		for _, testFile in ipairs(allTestFiles) do
			table.insert(testFilesList, testFile:GetFullName())
		end

		local output = {
			success = false,
			totalTests = 0,
			passed = 0,
			failed = 0,
			skipped = 0,
			errors = {{
				testName = "Pattern matching",
				message = ("No test files found matching pattern: '%s'"):format(testNamePattern),
				trace = ("Total test files available: %d\nFiles:\n%s"):format(
					#allTestFiles,
					table.concat(testFilesList, "\n")
				)
			}},
			printMessages = capturedPrintMessages
		}
		return HttpService:JSONEncode(output)
	end

	testOptions = {}
else
	-- 无 pattern 时直接运行所有目录
	testTargets = targetDirs
	testOptions = {}
end

-- 预检查：尝试加载每个测试文件，捕获语法错误
for _, testFile in ipairs(allTestFiles) do
	local loadSuccess, loadError = xpcall(function()
		require(testFile)
	end, debug.traceback)

	if not loadSuccess then
		local errorMsg = tostring(loadError)

		-- 从错误消息中提取详细信息
		local errorLines = {}
		for line in errorMsg:gmatch("[^\r\n]+") do
			table.insert(errorLines, line)
		end

		-- 提取第一个包含行号的堆栈行
		local errorLocation = ""
		for _, line in ipairs(errorLines) do
			-- 查找包含文件路径和行号的行（格式: "  Path:LineNumber"）
			if line:find(testFile.Name) and line:find(":%d+") then
				errorLocation = line:match("^%s*(.+)$") or line -- 去掉前导空格
				break
			end
		end

		local output = {
			success = false,
			totalTests = 0,
			passed = 0,
			failed = 1,
			skipped = 0,
			errors = {{
				testName = "Syntax Check: " .. testFile:GetFullName(),
				message = "Syntax error in test file\n" ..
				          "File: " .. testFile:GetFullName() .. "\n" ..
				          (errorLocation ~= "" and ("Location: " .. errorLocation .. "\n") or "") ..
				          "Hint: Check for incomplete statements, missing quotes, or unclosed blocks",
				trace = errorMsg
			}},
			printMessages = capturedPrintMessages
		}
		return HttpService:JSONEncode(output)
	end
end

-- 运行测试并收集结果（print/warn 已被重写，会自动捕获）
-- 使用 xpcall 包裹以捕获测试文件的语法错误等致命错误，并获取完整堆栈跟踪
local runSuccess, results = xpcall(function()
	return TestEZ.TestBootstrap:run(testTargets, reporter, testOptions)
end, debug.traceback)

-- 如果测试运行本身失败（例如测试文件有语法错误），返回错误信息
if not runSuccess then
	local errorMessage = tostring(results)

	-- 先从完整错误信息中提取文件位置（在过滤之前）
	local errorFile = "Unknown"
	local errorLine = ""

	-- 查找第一个包含我们代码的堆栈行（不是 TestEZ 内部的）
	for line in errorMessage:gmatch("[^\r\n]+") do
		-- 跳过错误消息本身
		if line:find("ReplicatedStorage") or line:find("ServerScriptService") or line:find("TaskScript") then
			-- 不是 TestEZ 包内部的代码
			if not (line:find("node_modules%.@rbxts%.testez%.src") or line:find("Packages%._Index%.roblox_testez")) then
				errorFile = line
				break
			end
		end
	end

	-- 尝试从错误信息中分离消息和堆栈跟踪
	local message = ""
	local trace = ""
	local lines = {}
	for line in errorMessage:gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end

	if #lines > 0 then
		message = lines[1]
		if #lines > 1 then
			-- 提取堆栈跟踪，过滤 TestEZ 内部代码
			for i = 2, #lines do
				local line = lines[i]
				local shouldFilter = line:find("node_modules%.@rbxts%.testez%.src") or
				                     line:find("Packages%._Index%.roblox_testez")
				if not shouldFilter then
					if trace ~= "" then
						trace = trace .. "\n"
					end
					trace = trace .. line
				end
			end
		end
	else
		message = errorMessage
	end

	-- 构建更详细的错误消息
	local detailedMessage = message
	if message:find("Requested module experienced an error while loading") or
	   message:find("error while loading") then
		detailedMessage = "Syntax error in test file\n" ..
		                  "Location: " .. errorFile .. "\n" ..
		                  "Hint: Check for incomplete statements, missing quotes, or unclosed blocks"
	end

	local output = {
		success = false,
		totalTests = 0,
		passed = 0,
		failed = 1,
		skipped = 0,
		errors = {{
			testName = "Test Execution (Fatal Error)",
			message = detailedMessage,
			trace = trace ~= "" and trace or ("Full error:\n" .. errorMessage)
		}},
		printMessages = capturedPrintMessages
	}
	return HttpService:JSONEncode(output)
end

-- 从 results 手动收集错误信息(包含测试名称)
-- 使用 Map 存储错误,优先保留有测试名称的版本
local errorMap = {}
local errors = {}

-- 遍历所有节点收集错误及其测试名称
local function collectErrors(node, parentPath)
	local currentPath = parentPath
	if node.planNode and node.planNode.phrase then
		currentPath = parentPath == "" and node.planNode.phrase or (parentPath .. " > " .. node.planNode.phrase)
	end

	-- 如果当前节点有错误,收集它们
	if node.errors and #node.errors > 0 then
		for _, errorMessage in ipairs(node.errors) do
			local msgStr = tostring(errorMessage)
			local testName = currentPath ~= "" and currentPath or "Unknown"

			-- 分离错误消息和堆栈跟踪
			-- 第一行通常是错误消息,其余是堆栈跟踪
			local message = ""
			local trace = ""
			local lines = {}
			for line in msgStr:gmatch("[^\r\n]+") do
				table.insert(lines, line)
			end

			if #lines > 0 then
				message = lines[1]
				if #lines > 1 then
					-- 将剩余行作为堆栈跟踪，过滤掉 TestEZ 包内部的所有代码
					for i = 2, #lines do
						local line = lines[i]
						-- 过滤掉 TestEZ 包内部的行
						-- TypeScript: node_modules.@rbxts.testez.src
						-- Lua: Packages._Index.roblox_testez
						local shouldFilter = line:find("node_modules%.@rbxts%.testez%.src") or
						                     line:find("Packages%._Index%.roblox_testez")

						if not shouldFilter then
							if trace ~= "" then
								trace = trace .. "\n"
							end
							trace = trace .. line
						end
					end
				end
			else
				message = msgStr
			end

			-- 如果是新错误,或者当前版本有测试名称而之前的没有,则更新
			if not errorMap[msgStr] or (testName ~= "Unknown" and errorMap[msgStr].testName == "Unknown") then
				errorMap[msgStr] = {
					testName = testName,
					message = message,
					trace = trace
				}
			end
		end
	end

	-- 递归处理子节点
	if node.children then
		for _, child in ipairs(node.children) do
			collectErrors(child, currentPath)
		end
	end
end

collectErrors(results, "")

-- 将 Map 转换为数组
for _, errorData in pairs(errorMap) do
	table.insert(errors, errorData)
end

-- 统计 planning 错误（模块加载失败等，未计入 failureCount）
-- Planning 错误的特征：消息中包含 "Error during planning"
local planningErrorCount = 0
for _, error in ipairs(errors) do
	if error.message and error.message:find("Error during planning") then
		planningErrorCount = planningErrorCount + 1
	end
end

-- 等待一些帧，让 LogService 有时间触发所有待处理的事件
-- LogService.MessageOut 可能在下一帧才触发
for i = 1, 10 do
	task.wait()
end

-- 断开 LogService 连接
if connection then
	connection:Disconnect()
end

-- 返回测试结果
-- success 应该同时检查 failureCount 和所有错误
-- 将 planning 错误也计入 failed 和 totalTests，使统计更直观：
-- - 语法错误/加载错误应该算作测试失败
-- - Pass rate 应该反映真实的成功率
local output = {
	success = results.failureCount == 0 and planningErrorCount == 0,
	totalTests = results.successCount + results.failureCount + planningErrorCount,
	passed = results.successCount,
	failed = results.failureCount + planningErrorCount,
	skipped = results.skippedCount or 0,
	errors = errors,
	printMessages = capturedPrintMessages
}

-- 返回 JSON 格式
return HttpService:JSONEncode(output)
