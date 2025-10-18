# Roblox Cloud TestEZ Testing Tool

A lightweight testing tool that runs TestEZ tests in Roblox Cloud environment using direct API calls.

## Quick Start

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

## Features

- ✅ **Zero External Dependencies**: Uses only Node.js built-in modules
- ✅ **Direct API Calls**: No rbxcloud tool required
- ✅ **Fast Execution**: ~8-15 seconds for full workflow
- ✅ **Rich Output**: Detailed test results with stack traces
- ✅ **Flexible Filtering**: Pattern-based test selection
- ✅ **TypeScript & Lua Support**: Works with both project types

## Workflow

The testing workflow consists of 4 steps:

1. **Build** - Use Rojo to build the Place file from source
2. **Upload** - Upload the built Place file to Roblox Cloud (API v1)
3. **Execute** - Run the test script in Roblox Cloud using Luau Execution API (API v2)
4. **Results** - Poll and display test results with detailed logs

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
- `--roots <path>` - Test root paths, separated by / (default: ReplicatedStorage)
- `--glob <match>` - Match test files in roots
- `--skip-build` - Skip the Rojo build step

### Examples

```bash
# Run all tests
node scripts/test-in-roblox-cloud.js

# Run tests containing "StringUtils"
node scripts/test-in-roblox-cloud.js StringUtils

# Verbose output
node scripts/test-in-roblox-cloud.js --verbose

# Skip build, upload and test directly
node scripts/test-in-roblox-cloud.js --skip-build

# Run specific test with verbose logging
node scripts/test-in-roblox-cloud.js "should allow" -V
```

## Environment Configuration

Configure `.env.roblox` with the following variables:

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

支持两种项目类型：
- **TypeScript**: `ReplicatedStorage.rbxts_include`（优先扫描 `@white-dragon-bevy` 包，提高性能）
- **Lua**: `ReplicatedStorage.Lib`

**测试文件要求**:
- 文件名必须包含 `.spec`（例如：`MyModule.spec.lua`）
- 自动递归扫描所有子目录
- 在执行测试前会进行语法检查，提前发现语法错误

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

### Tests not found
- Ensure test files have `.spec` in the name
- Check that test files are in the correct location (`src/` or configured test root)
- Verify `default.project.json` correctly syncs test directories

### Upload failed
- Verify API key has correct permissions
- Check Universe ID and Place ID are correct
- Ensure Place is saved type (not published)

### Task timeout
- Increase max attempts in `rbx-cloud-api.js`
- Check Roblox Cloud service status
- Verify test script doesn't have infinite loops

## License

This project is for demonstration and educational purposes.
