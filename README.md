# Roblox Cloud TestEZ Testing Tool

A lightweight testing tool that runs TestEZ tests in Roblox Cloud environment using direct API calls.

## Quick Start

### For Cloud Testing

```bash
# Install Rokit tools (rojo, wally)
rokit install

# Install Roblox packages
wally install

# Configure environment variables in .env.roblox
# (See Environment Configuration section below)

# Run all tests
node scripts/test-in-roblox-cloud.js

# Run specific tests with pattern
node scripts/test-in-roblox-cloud.js "StringUtils"

# Verbose output
node scripts/test-in-roblox-cloud.js -V
```

### For Studio Testing

```bash
# Install dependencies
wally install

# Start Rojo server
rojo serve default.project.json

# In Roblox Studio:
# 1. Connect to Rojo plugin
# 2. Press F5 (Run) or F8 (Play)
# 3. View test results in Output window
```

See [Studio Testing Configuration](#studio-testing-configuration) for detailed setup instructions.

## Features

- ✅ **Zero External Dependencies**: Uses only Node.js built-in modules
- ✅ **Direct API Calls**: No rbxcloud tool required
- ✅ **Fast Execution**: ~8-15 seconds for full workflow
- ✅ **Rich Output**: Detailed test results with stack traces
- ✅ **Flexible Filtering**: Pattern-based test selection
- ✅ **TypeScript & Lua Support**: Works with both project types
- ✅ **Multiple Root Paths**: Scan tests from multiple directories simultaneously
- ✅ **Studio Testing**: Run tests directly in Roblox Studio with automatic test discovery
- ✅ **Timeout Debugging**: Two-layer timeout locator to pinpoint slow tests at file and test-case level

## Workflow

The testing workflow consists of 4 steps:

1. **Build** - Use Rojo to build the Place file from source
2. **Upload** - Upload the built Place file to Roblox Cloud (API v1)
3. **Execute** - Run the test script in Roblox Cloud using Luau Execution API (API v2)
4. **Results** - Poll and display test results with detailed logs

## Installation as Package

### Using Wally

如果你想在自己的项目中使用这个测试工具，可以通过 Wally 安装：

1. **添加依赖到 `wally.toml`**：

```toml
[dev-dependencies]
test-cloud-testez = "your-username/test-cloud-testez@version"
```

2. **安装依赖**：

```bash
wally install
```

3. **配置 `default.project.json`**（见下一节）

### Manual Installation

或者手动将此工具添加到你的项目：

1. 将 `TestService/test-cloud-testez` 目录复制到你的项目
2. 在 `default.project.json` 中配置（见下一节）

## Studio Testing Configuration

要在 Roblox Studio 中运行测试，需要在 `default.project.json` 中添加 TestService 配置：

### 配置 default.project.json

```json
{
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
    
      "TestService": {
        "$className": "TestService",
        "test-cloud-testez": {
            "$path": "node_modules/test-cloud-testez/TestService/test-cloud-testez"
        }
    }
  }
}
```

**关键配置说明：**

1. **添加 TestService 节点**：
   ```json
   "TestService": {
     "$className": "TestService",
     "test-cloud-testez": {
       "$path": "Packages/test-cloud-testez"
     }
   }
   ```

2. **同步到 Studio**：
   ```bash
   # 启动 Rojo 服务器
   rojo serve default.project.json
   ```

   然后在 Roblox Studio 中连接 Rojo 插件。

### 在 Studio 中运行测试

1. 确保已通过 Rojo 同步项目
2. 在 Studio 中点击 **Run** (F5) 或 **Play** (F8)
3. 测试会自动运行，结果显示在 Output 窗口

### 配置测试目标

有两种方式配置在 Studio 中运行的测试：

#### 方式 1：使用 test-target（精确控制）

在 `TestService.test-cloud-testez` 下有一个 `test-target` (ObjectValue)：

1. 在 Studio 中选择 `TestService.test-cloud-testez.test-target`
2. 在属性面板中设置 `Value` 属性
3. 可以指向：
   - **单个 ModuleScript**：只测试该文件
   - **Folder 或目录**：测试整个目录
   - 例如：`ReplicatedStorage.Lib`、`ServerScriptService.Server`

**行为：** 设置后，只测试 `test-target` 指向的目标，不测试其他目录。

#### 方式 2：使用默认目录（自动扫描）

不设置 `test-target.Value`（保持为 nil），测试工具会自动扫描以下目录，**所有存在的目录都会被测试**：

- `ReplicatedStorage.rbxts_include`
- `ReplicatedStorage.Lib`
- `ServerScriptService.Server`

**行为：**
- 扫描所有候选目录，存在的都会被包含进测试
- 例如：如果同时存在 `Lib` 和 `Server`，两个目录都会被测试
- 会在日志中显示哪些目录被找到（`✓`）和哪些未找到（`✗`）

### Studio 测试日志

运行测试时会显示详细日志：

```
📦 使用 Wally 项目的 TestEZ
📍 扫描默认测试目录...
  ✗ 未找到: ReplicatedStorage.rbxts_include
  ✓ 找到: ReplicatedStorage.Lib
  ✓ 找到: ServerScriptService.Server
📍 将测试 2 个默认目录
```

或者使用 test-target 时：

```
📦 使用 Wally 项目的 TestEZ
📍 使用 test-target 指定的目标: ReplicatedStorage.Lib
```

## Timeout Debugging Tool

### two-step-find-timeout.server.lua

当测试在 Studio 或 Cloud 环境中出现超时问题时，使用此调试工具可以精确定位导致超时的测试文件和测试用例。

#### 工作原理

采用**细化定位**策略：
- 每帧（Heartbeat）运行一个测试文件（ModuleScript）
- 快速定位哪个测试文件导致超时
- 记录通过和超时的文件列表

#### 使用场景

- ✅ 调试超时问题：定位具体哪个测试文件或测试用例超时
- ✅ 性能分析：了解每个测试的执行时间
- ✅ 大型测试套件：避免整体超时，通过增量方式执行

#### 工作流程

```
启动脚本
  ↓
自动加载 TestEZ (支持 Wally/roblox-ts)
  ↓
递归扫描测试文件 (*.spec.lua)
  ↓
  逐帧运行每个文件
  ├─ 通过 → 记录到 layer1Passed
  └─ 超时 → 记录到 layer1Timeout

```

#### 扫描目录

与 `start.server.lua` 保持一致，脚本会自动扫描以下默认目录，**所有存在的目录都会被测试**：

- `ReplicatedStorage.rbxts_include`
- `ReplicatedStorage.Lib`
- `ServerScriptService.Server`

脚本会显示每个目录的扫描结果（`✓ 找到` 或 `✗ 未找到`）。

#### 配置方式

1. **在 default.project.json 中添加**：

```json
{
  "TestService": {
    "$className": "TestService",
    "timeout-debugger": {
      "$path": "TestService/test-cloud-testez/two-step-find-timeout.server.lua"
    }
  }
}
```

2. **在 Studio 中使用**：
   - 同步 Rojo 项目
   - 运行测试（F5 或 F8）
   - 观察 Output 窗口的详细日志

#### 输出示例

```
[INIT] 脚本开始执行...
[INIT] ✓ TestEZ 加载成功
[Layer1] 开始初始化...
[Layer1] 扫描默认测试目录...
  ✓ 找到: ReplicatedStorage.rbxts_include
  ✗ 未找到: ReplicatedStorage.Lib
  ✓ 找到: ServerScriptService.Server
[Layer1] 将扫描 2 个目录
[Layer1] 扫描目录: ReplicatedStorage.rbxts_include
[Layer1] 在 ReplicatedStorage.rbxts_include 中找到 15 个测试文件
[Layer1] 扫描目录: ServerScriptService.Server
[Layer1] 在 ServerScriptService.Server 中找到 10 个测试文件
[Layer1] 总共找到 25 个测试文件
[Layer1] 测试 [1/25]: StringUtils.spec
[Layer1] 测试 [2/25]: MathUtils.spec
[Layer1] 测试 [3/25]: ServerUtils.spec
[Layer1] 测试失败: timeout after 5 seconds  ← 发现超时文件
```

#### 特性

- ✅ **逐帧执行**：避免长时间阻塞导致整体超时
- ✅ **Session 跟踪**：支持 Session ID 注入，用于 Cloud 测试追踪
- ✅ **智能加载**：自动检测并加载 Wally 或 roblox-ts 的 TestEZ
- ✅ **详细日志**：每个步骤都有清晰的日志输出
- ✅ **错误处理**：包含完整的错误捕获和报告

#### 注意事项

- 此工具主要用于**调试目的**，不建议用于常规测试运行
- 逐帧执行会显著增加总测试时间，适合定位问题而非日常使用
- 对于大型测试套件，建议先使用普通测试工具，只在出现超时时才使用此工具
- 扫描逻辑与 `start.server.lua` 完全一致，确保调试环境与正常测试环境相同

## test-in-roblox-cloud Tool

### Usage

```bash
node scripts/test-in-roblox-cloud.js [pattern] [options]
```

### Arguments

- `<pattern>` - Test name filter pattern (matches test files containing this string)

### Options

- `-V, --verbose` - Verbose output (can be specified multiple times for more detail)
- `-h, --help` - Show help message
- `-v, --version` - Show version information
- `-t, --timeout <sec>` - Task execution timeout in seconds (default: 120)
- `-r, --rbxl <path>` - Specify rbxl file path (default: test-place.rbxl)
- `-j, --jest` - Use jest instead of testez (default: testez)
- `--roots <path>` - Test root paths, separated by , (default: ServerScriptService,ReplicatedStorage). Use / for path hierarchy (e.g., ServerScriptService/Server)
- `--glob <match>` - Match test files in roots
- `--skip-build` - Skip the Rojo build step

### Examples

```bash
# Run all tests (scans ServerScriptService and ReplicatedStorage by default)
node scripts/test-in-roblox-cloud.js

# Run tests containing "StringUtils"
node scripts/test-in-roblox-cloud.js StringUtils

# Verbose output
node scripts/test-in-roblox-cloud.js --verbose

# Skip build, upload and test directly
node scripts/test-in-roblox-cloud.js --skip-build

# Run specific test with verbose logging
node scripts/test-in-roblox-cloud.js "should allow" -V

# Scan only ReplicatedStorage
node scripts/test-in-roblox-cloud.js --roots ReplicatedStorage

# Scan custom paths (multiple roots separated by ,)
node scripts/test-in-roblox-cloud.js --roots "ServerScriptService/Tests,ReplicatedStorage/Lib"

# Scan nested directory
node scripts/test-in-roblox-cloud.js --roots ReplicatedStorage/MyTests/Modules

# Multiple nested paths
node scripts/test-in-roblox-cloud.js --roots "ServerScriptService/Server,ReplicatedStorage/Lib"
```

## Environment Configuration

### Setup

1. **Copy the example file**:
   ```bash
   cp .env.example .env.roblox
   ```

2. **Configure `.env.roblox` with your values**:

```bash
# 推荐使用新的环境变量名（简洁清晰）
ROBLOX_API_KEY=your_api_key_here
UNIVERSE_ID=your_universe_id
TEST_PLACE_ID=your_place_id

# 旧的环境变量名（仍然支持，向后兼容）
# RBXCLOUD_API_KEY=your_api_key_here
# RBXCLOUD_UNIVERSE_ID=your_universe_id
# RBXCLOUD_PLACE_ID=your_place_id
```

### Getting Your Credentials

- **API Key**: Get from [Roblox Creator Dashboard → Credentials](https://create.roblox.com/credentials)
  - Required permissions: `universe-places.write`, `universe-luau-execution.run`
- **Universe ID**: Find in your game's settings
- **Place ID**: Find in the place's settings

**Important**:
- Environment variables are automatically loaded from `.env.roblox` by the `rbx-cloud-api.js` module
- 代码同时支持新旧两种环境变量名，优先使用新名称
- 如果同时定义了新旧名称，将使用新名称

## Architecture

### Core Modules

**`scripts/rbx-cloud-api.js`** - Roblox Cloud API封装
- `publishPlace()` - 上传Place文件
- `executeLuau()` - 执行Luau脚本
- `getTask()` - 获取任务状态
- `pollTaskUntilComplete()` - 轮询等待完成
- `parseTaskPath()` - 解析响应路径

**`scripts/test-in-roblox-cloud.js`** - 主测试工具
- CLI参数解析
- 完整的测试流程编排
- 结果格式化和保存

**`scripts/cloud-test.lua`** - Cloud执行脚本
- 环境检测和输出捕获
- 使用 SilentReporter 最小化开销
- 语法检查和错误处理
- JSON结果返回

### Project Structure Support

**多根路径支持**:
- 默认扫描 `ServerScriptService` 和 `ReplicatedStorage` 两个路径
- 支持自定义多个根路径（使用 `--roots` 参数）
- 路径导航支持 Service 和嵌套子对象

**项目类型自动检测**:
当扫描 `ReplicatedStorage` 时，会自动检测项目类型：
- **TypeScript**: `ReplicatedStorage.rbxts_include`（优先扫描 `@white-dragon-bevy` 包，提高性能）
- **Lua**: `ReplicatedStorage.Lib`
- 如果未找到特定子目录，使用 `ReplicatedStorage` 本身作为测试目录

**测试文件要求**:
- 文件名必须包含 `.spec`（例如：`MyModule.spec.lua`）
- 自动递归扫描所有子目录
- 在执行测试前会进行语法检查，提前发现语法错误

**路径分隔符**:
- `,` 用于分隔多个根路径（例如：`--roots "ServerScriptService,ReplicatedStorage"`）
- `/` 用于分隔路径层级（例如：`--roots "ReplicatedStorage/Lib/Tests"`）
- 内部使用 `;` 分隔多个路径传递给 Lua 脚本

## NPM Scripts

```bash
npm test              # Run all tests
npm run test:verbose  # Run tests with verbose output
npm run test:skip-build   # Run tests without building
npm run build         # Build Place file only
```

**Note**: This project has no npm dependencies. All scripts use Node.js built-in modules only.

## Test Results

Test results are saved in `.test-result/` directory:
- Timestamped YAML files (易于阅读和版本控制)
- Only the last 2 results are kept
- Includes test statistics, errors with filtered stack traces, and captured output

Example output (YAML format):
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

**注意**:
- 堆栈跟踪会自动过滤掉 TestEZ 内部代码，只显示用户代码的相关信息
- 使用 YAML 格式便于人工阅读和 Git diff

## API Documentation

### Roblox Cloud APIs Used

**Place Publishing (v1)**:
```
POST /universes/v1/{universeId}/places/{placeId}/versions?versionType=Saved
```

**Luau Execution (v2)**:
```
POST /cloud/v2/universes/{universeId}/places/{placeId}/versions/{versionId}/luau-execution-session-tasks
```

**Task Status (v2)**:
```
GET /cloud/v2/universes/{universeId}/places/{placeId}/versions/{versionId}/luau-execution-sessions/{sessionId}/tasks/{taskId}
```

All APIs require `x-api-key` header with your Roblox Open Cloud API key.

## Writing Tests

TestEZ test format:

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

Test files must have `.spec` in their name (e.g., `MyModule.spec.lua`).

### Capturing Print Output

To capture print/warn output from your tests, use `_G.print()` and `_G.warn()`:

```lua
return function()
    _G.print("Starting tests...")  -- Will be captured

    describe("MyModule", function()
        it("should work", function()
            _G.print("Testing something")  -- Will be captured
            expect(true).to.equal(true)
        end)
    end)
end
```

Captured output appears in:
- Test results JSON file (`.test-result/*.json` in `printMessages` field)
- Console output when using `-V` (verbose) flag

**Note**: Use `_G.print()` instead of `print()` to ensure output is captured in Cloud environment.

## Example Tests

The project includes example tests in `src/`:

- **MathUtils** - Math utility functions (add, subtract, multiply, divide, isEven, isPrime, factorial)
- **StringUtils** - String utility functions (reverse, startsWith, endsWith, split, trim, titleCase)

## Performance

Typical execution times:
- Full workflow (Build + Upload + Test): ~8-15 seconds
- Skip build (--skip-build): ~5-8 seconds
- Test execution only: ~3-5 seconds

## Troubleshooting

### Studio Testing Issues

**测试未运行**
1. 确保在 **Run Mode** 下（F5 或 F8），测试不会在编辑模式下运行
2. 检查 Output 窗口是否有错误信息
3. 确认 Rojo 已正确同步项目结构

**找不到 TestEZ**
- 错误信息：`❌ 无法找到 TestEZ！请确保已通过 Wally 或 npm 安装 TestEZ`
- 解决方法：
  1. 运行 `wally install` 安装依赖
  2. 使用 Rojo 同步项目到 Studio
  3. 确认 `ReplicatedStorage.Packages` 中存在 TestEZ

**只测试了部分目录**
- 查看测试日志，确认哪些目录被找到
- 如果某个目录未找到（显示 `✗ 未找到`），请检查：
  1. `default.project.json` 中是否配置了该路径
  2. Rojo 是否已同步最新配置
  3. 目录是否存在于源代码中

**`_G.print` is nil 错误**
- 这个错误已在最新版本修复
- 如果仍然遇到，请确保使用最新版本的 `start.server.lua`

**测试超时问题**
- 如果测试在 Studio 或 Cloud 中超时，无法定位具体原因
- 使用 [Timeout Debugging Tool](#timeout-debugging-tool) 精确定位超时的测试文件和测试用例
- 该工具采用两层细化定位策略，逐帧执行测试避免整体超时

### Cloud Testing Issues

**Tests not found**
- Ensure test files have `.spec` in the name
- Check that test files are in the correct location (`src/` or configured test root)
- Verify `default.project.json` correctly syncs test directories

**Upload failed**
- Verify API key has correct permissions
- Check Universe ID and Place ID are correct
- Ensure Place is saved type (not published)

**Task timeout**
- Increase max attempts in `rbx-cloud-api.js`
- Check Roblox Cloud service status
- Verify test script doesn't have infinite loops

## License

This project is for demonstration and educational purposes.
