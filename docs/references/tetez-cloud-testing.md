# Roblox Cloud 测试指南

本文档介绍如何在 Roblox Cloud 环境中运行 TestEZ 测试。

## 概述

Cloud 测试通过 Roblox Open Cloud API 在云端环境执行测试，无需打开 Roblox Studio。这适合：
- 持续集成/持续部署 (CI/CD) 流程
- 自动化测试
- 快速验证代码变更
- 无需图形界面的测试环境

## 快速开始

### 安装依赖

```bash
# 安装 Rokit 工具 (rojo, wally)
rokit install

# 安装 Roblox 包
wally install
```

### 配置环境变量

创建 `.env.roblox` 文件（从 `.env.example` 复制）：

```bash
cp .env.example .env.roblox
```

编辑 `.env.roblox`，填入你的凭据：

```bash
# 推荐使用新的环境变量名（简洁清晰）
ROBLOX_API_KEY=your_api_key_here
UNIVERSE_ID=your_universe_id
TEST_PLACE_ID=your_place_id
```

**获取凭据**：
- **API Key**: 从 [Roblox Creator Dashboard → Credentials](https://create.roblox.com/credentials) 获取
  - 需要权限: `universe-places.write`, `universe-luau-execution.run`
- **Universe ID**: 在游戏设置中查找
- **Place ID**: 在 Place 设置中查找

### 运行测试

```bash
# 运行所有测试
node scripts/test-in-roblox-cloud.js

# 使用 pattern 匹配特定测试
node scripts/test-in-roblox-cloud.js "StringUtils"

# 详细输出模式
node scripts/test-in-roblox-cloud.js -V

# 跳过构建，直接测试
node scripts/test-in-roblox-cloud.js --skip-build
```

## 测试工作流程

Cloud 测试包含 4 个步骤：

1. **Build** - 使用 Rojo 从源代码构建 Place 文件
2. **Upload** - 上传构建好的 Place 文件到 Roblox Cloud (API v1)
3. **Execute** - 在 Roblox Cloud 中使用 Luau Execution API 运行测试脚本 (API v2)
4. **Results** - 轮询并显示详细的测试结果

## test-in-roblox-cloud 工具

### 命令语法

```bash
node scripts/test-in-roblox-cloud.js [pattern] [options]
```

### 参数说明

#### 位置参数

- `<pattern>` - 测试名称过滤 pattern（匹配包含此字符串的测试文件）

#### 选项参数

- `-V, --verbose` - 详细输出（可多次指定以增加详细程度，`-VV` 为最详细）
- `-h, --help` - 显示帮助信息
- `-v, --version` - 显示版本信息
- `-t, --timeout <sec>` - 任务执行超时时间（秒），默认：120
- `-r, --rbxl <path>` - 指定 rbxl 文件路径，默认：`test-place.rbxl`
- `-j, --jest` - 使用 jest 而非 testez，默认：testez
- `--roots <path>` - 测试根路径，用 `,` 分隔，默认：`ServerScriptService,ReplicatedStorage`。使用 `/` 表示路径层级（如 `ServerScriptService/Server`）
- `--glob <match>` - 在根路径中匹配测试文件
- `--skip-build` - 跳过 Rojo 构建步骤

### 使用示例

```bash
# 运行所有测试（默认扫描 ServerScriptService 和 ReplicatedStorage）
node scripts/test-in-roblox-cloud.js

# 运行包含 "StringUtils" 的测试
node scripts/test-in-roblox-cloud.js StringUtils

# 详细输出
node scripts/test-in-roblox-cloud.js --verbose

# 跳过构建，直接上传和测试
node scripts/test-in-roblox-cloud.js --skip-build

# 运行特定测试并显示详细日志
node scripts/test-in-roblox-cloud.js "should allow" -V

# 只扫描 ReplicatedStorage
node scripts/test-in-roblox-cloud.js --roots ReplicatedStorage

# 扫描自定义路径（多个根路径用 , 分隔）
node scripts/test-in-roblox-cloud.js --roots "ServerScriptService/Tests,ReplicatedStorage/Lib"

# 扫描嵌套目录
node scripts/test-in-roblox-cloud.js --roots ReplicatedStorage/MyTests/Modules

# 多个嵌套路径
node scripts/test-in-roblox-cloud.js --roots "ServerScriptService/Server,ReplicatedStorage/Lib"
```

### NPM 脚本快捷方式

```bash
npm test                  # 运行所有测试
npm run test:verbose      # 运行测试并显示详细输出
npm run test:skip-build   # 运行测试但跳过构建
npm run build             # 仅构建 Place 文件
```

**注意**：本项目没有 npm 依赖，所有脚本仅使用 Node.js 内置模块。

## 环境配置

### 环境变量

代码支持新旧两种环境变量名，优先使用新名称：

**推荐使用（新名称）**：
```bash
ROBLOX_API_KEY=your_api_key_here
UNIVERSE_ID=your_universe_id
TEST_PLACE_ID=your_place_id
```

**向后兼容（旧名称）**：
```bash
RBXCLOUD_API_KEY=your_api_key_here
RBXCLOUD_UNIVERSE_ID=your_universe_id
RBXCLOUD_PLACE_ID=your_place_id
```

如果同时定义了新旧名称，将使用新名称。

环境变量由 `scripts/rbx-cloud-api.js` 自动从 `.env.roblox` 加载（使用 dotenv，静默模式）。

## 架构说明

### 核心模块

#### `scripts/rbx-cloud-api.js`

独立的 Roblox Cloud API 封装模块，提供以下功能：

- **publishPlace()** - 上传 Place 文件到 Roblox Cloud
- **executeLuau()** - 在 Cloud 环境执行 Luau 脚本（支持 timeout 参数，范围 1-300 秒）
- **getTask()** - 获取任务执行状态
- **pollTaskUntilComplete()** - 轮询等待任务完成（支持 timeout、初始延迟、轮询间隔配置）
- **parseTaskPath()** - 从 API 响应路径中提取 IDs

使用 Node.js 内置的 `https` 模块，无需任何外部 API 客户端。

#### `scripts/test-in-roblox-cloud.js`

主测试执行工具，提供：

- CLI 参数解析
- 完整的测试流程编排
- 结果格式化和保存

#### `scripts/cloud-test.lua`

在 Roblox Cloud 中执行的测试脚本，核心功能：

1. **环境检测**: 设置 `_G.__isInCloud__` 标志，供 TypeScript 代码检测云端环境
2. **输出捕获**: 重写全局 `print/warn` 函数（在 require TestEZ 之前），捕获所有测试输出
3. **最小化 Reporter**: 使用 SilentReporter 减少运行时开销
4. **项目类型支持**:
   - TypeScript 项目: `ReplicatedStorage.rbxts_include`（优先使用 `@white-dragon-bevy` 包提高性能）
   - Lua 项目: `ReplicatedStorage.Lib`
5. **语法检查**: 执行测试前预检查所有测试文件，提前发现语法错误
6. **文件名过滤**: 递归扫描匹配 `.spec` 文件（不区分大小写）
7. **错误处理**: 使用 xpcall 捕获完整堆栈跟踪，自动过滤 TestEZ 内部代码
8. **JSON 结果**: 返回包含统计、错误、堆栈跟踪、捕获输出的 JSON 格式结果

### API 实现

直接使用 Node.js `https` 模块调用 Roblox Cloud API：

**上传 Place (API v1)**:
```
POST /universes/v1/{universeId}/places/{placeId}/versions?versionType=Saved
Content-Type: application/octet-stream
x-api-key: {apiKey}
```

**执行 Luau (API v2)**:
```
POST /cloud/v2/universes/{universeId}/places/{placeId}/versions/{versionId}/luau-execution-session-tasks
Content-Type: application/json
x-api-key: {apiKey}
```

**获取任务状态 (API v2)**:
```
GET /cloud/v2/universes/{universeId}/places/{placeId}/versions/{versionId}/luau-execution-sessions/{sessionId}/tasks/{taskId}
x-api-key: {apiKey}
```

### 项目结构支持

#### 多根路径支持

- 默认扫描 `ServerScriptService` 和 `ReplicatedStorage` 两个路径
- 支持自定义多个根路径（使用 `--roots` 参数）
- 路径导航支持 Service 和嵌套子对象

#### 项目类型自动检测

当扫描 `ReplicatedStorage` 时，会自动检测项目类型：

- **TypeScript**: `ReplicatedStorage.rbxts_include`（优先扫描 `@white-dragon-bevy` 包，提高性能）
- **Lua**: `ReplicatedStorage.Lib`
- 如果未找到特定子目录，使用 `ReplicatedStorage` 本身作为测试目录

#### 测试文件要求

- 文件名必须包含 `.spec`（例如：`MyModule.spec.lua`）
- 自动递归扫描所有子目录
- 在执行测试前会进行语法检查，提前发现语法错误

#### 路径分隔符

- `,` 用于分隔多个根路径（例如：`--roots "ServerScriptService,ReplicatedStorage"`）
- `/` 用于分隔路径层级（例如：`--roots "ReplicatedStorage/Lib/Tests"`）
- 内部使用 `;` 分隔多个路径传递给 Lua 脚本

## 测试结果

测试结果保存在 `.test-result/` 目录：

- 时间戳命名的 YAML 文件（易于人工阅读和版本控制）
- 只保留最近 2 次结果
- 包含测试统计、过滤后的堆栈跟踪错误、捕获的输出

### 结果示例 (YAML 格式)

```yaml
timestamp: '2025-10-17T13:18:06.000Z'
important: Results from Roblox Cloud test execution. read stacktrace files in out/ (roblox-ts generation)

success: true
totalTests: 34
passed: 34
failed: 0
skipped: 0

errors: []

printMessages: []
```

**注意**：
- 堆栈跟踪会自动过滤掉 TestEZ 内部代码，只显示用户代码的相关信息
- 使用 YAML 格式便于人工阅读和 Git diff

### 堆栈跟踪过滤

为了提高可读性，堆栈跟踪会自动过滤掉 TestEZ 内部代码：

**过滤规则**:
- TypeScript 项目: 过滤包含 `node_modules.@rbxts.testez.src` 的行
- Lua 项目: 过滤包含 `Packages._Index.roblox_testez` 的行
- 只保留用户代码相关的堆栈信息

**过滤位置**:
- `cloud-test.lua`: 在 Lua 端过滤（收集错误时）
- `test-in-roblox-cloud.js`: 在 JS 端再次过滤（保存结果前）

## 编写测试

### TestEZ 测试格式

```lua
return function()
    local MyModule = require(script.Parent.MyModule)

    describe("MyModule.myFunction", function()
        it("should do something", function()
            expect(MyModule.myFunction()).to.equal(expected)
        end)
    end)
end
```

测试文件名必须包含 `.spec`（例如 `MyModule.spec.lua`）。

### 捕获 Print 输出

要从测试中捕获 print/warn 输出，使用 `_G.print()` 和 `_G.warn()`：

```lua
return function()
    _G.print("开始测试...")  -- 将被捕获

    describe("MyModule", function()
        it("应该正常工作", function()
            _G.print("测试某些功能")  -- 将被捕获
            expect(true).to.equal(true)
        end)
    end)
end
```

捕获的输出会显示在：
- 测试结果 JSON 文件（`.test-result/*.json` 的 `printMessages` 字段）
- 使用 `-V`（verbose）标志时的控制台输出

**注意**：使用 `_G.print()` 而非 `print()` 以确保在 Cloud 环境中捕获输出。

### 语法检查

在运行测试之前，会对所有测试文件进行预检查：

1. **加载检查**: 使用 `xpcall(require)` 尝试加载每个测试文件
2. **错误定位**: 提取包含行号的错误位置信息
3. **友好提示**: 提供具体的文件路径、行号和修复建议
4. **提前失败**: 如果发现语法错误，立即返回错误信息，不执行测试

## Cloud API 限制

1. **只能捕获返回值**: Luau Execution API 只捕获脚本的 return 值
2. **LogService 不可用**: Cloud 环境中 LogService 事件不会触发
3. **解决方案**:
   - 重写全局 print/warn 函数（在 require TestEZ 之前）并设置到 `_G.print` / `_G.warn`
   - 测试文件中使用 `_G.print()` 来输出可被捕获的消息
   - 使用 SilentReporter 最小化运行时开销
   - 通过 JSON 返回所有信息（测试统计、错误、堆栈跟踪、捕获输出）
4. **超时配置**: executeLuau 支持 timeout 参数（1-300 秒范围），默认 300 秒

## 性能

典型执行时间：
- 完整流程（Build + Upload + Test）: ~8-15 秒
- 跳过构建（--skip-build）: ~5-8 秒
- 测试执行: ~3-5 秒
- 测试执行超时: 默认 120 秒（可通过 `-t` 参数配置）

轮询配置：
- 初始等待: 5 秒
- 轮询间隔: 3 秒
- 最大尝试次数: 60 次
- 默认超时: 60 秒（在 pollTaskUntilComplete 中）

**性能优化**:
- TypeScript 项目优先扫描 `@white-dragon-bevy` 包（如果存在），避免扫描整个 `rbxts_include`
- 使用 SilentReporter 而非 CustomReporter，减少运行时开销
- 语法预检查避免不必要的测试执行

## 故障排除

### 找不到测试

**可能原因**：
- 测试文件名中没有 `.spec`
- 测试文件不在正确的位置（`src/` 或配置的测试根路径）
- `default.project.json` 未正确同步测试目录

**解决方法**：
- 确认测试文件名包含 `.spec`（如 `MyModule.spec.lua`）
- 检查 `default.project.json` 中的路径配置
- 验证测试文件在正确的目录中

### 上传失败

**可能原因**：
- API Key 权限不正确
- Universe ID 或 Place ID 错误
- Place 类型不是 Saved（而是 Published）

**解决方法**：
- 验证 API Key 具有正确的权限（`universe-places.write`, `universe-luau-execution.run`）
- 检查 Universe ID 和 Place ID 是否正确
- 确保 Place 是保存类型（Saved），而非发布类型（Published）

### 任务超时

**可能原因**：
- 测试执行时间过长
- Roblox Cloud 服务状态异常
- 测试脚本中存在无限循环

**解决方法**：
- 使用 `-t` 参数增加超时时间（如 `-t 300`）
- 在 `rbx-cloud-api.js` 中增加最大尝试次数
- 检查 Roblox Cloud 服务状态
- 验证测试脚本中没有无限循环
- 使用 [Timeout Debugging Tool](../README.md#timeout-debugging-tool) 定位超时的测试

### 语法错误

如果测试文件存在语法错误，工具会在执行前检测并报告：

```
❌ 语法错误在 ReplicatedStorage.Lib.MyModule.spec:42
ServerScriptService.TestService.cloud-test:195: attempt to call a nil value
```

修复文件中的语法错误后重新运行测试。

## 示例测试

项目包含示例测试在 `src/`：

- **MathUtils** - 数学工具函数测试（add, subtract, multiply, divide, isEven, isPrime, factorial）
- **StringUtils** - 字符串工具函数测试（reverse, startsWith, endsWith, split, trim, titleCase）

## 特性对比

相比传统 rbxcloud 工具：

- ✅ **无外部依赖**: 只使用 Node.js 内置模块（https, fs, path），无需安装额外工具
- ✅ **更好的调试**: 可直接查看 HTTP 请求/响应（verbose 模式）
- ✅ **更快的执行**: 减少了进程调用开销，直接使用 Node.js https 模块
- ✅ **更易维护**: API 逻辑清晰独立在 `rbx-cloud-api.js` 中
- ✅ **项目类型支持**: 同时支持 TypeScript 和 Lua 项目结构
- ✅ **错误过滤**: 自动过滤 TestEZ 内部代码，只显示用户代码相关的堆栈跟踪
- ✅ **YAML 输出**: 使用 YAML 格式保存测试结果，便于人工阅读和版本控制
- ✅ **语法检查**: 提前发现测试文件中的语法错误，提供清晰的错误定位
- ✅ **向后兼容**: 支持新旧两种环境变量名，平滑迁移
