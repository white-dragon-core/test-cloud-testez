# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a testing tool for running TestEZ tests in Roblox Cloud environment. It **directly uses Roblox Open Cloud APIs** without external dependencies, providing a lightweight and maintainable testing solution.

## Core Architecture

### API Module (`scripts/rbx-cloud-api.js`)

独立的Roblox Cloud API封装模块，提供以下功能：

- **publishPlace**: 上传Place文件到Roblox Cloud
- **executeLuau**: 在Cloud环境执行Luau脚本（支持timeout参数，范围1-300秒）
- **getTask**: 获取任务执行状态
- **pollTaskUntilComplete**: 轮询等待任务完成（支持timeout、初始延迟、轮询间隔配置）
- **parseTaskPath**: 从API响应路径中提取IDs

使用Node.js内置的`https`模块，无需任何外部API客户端。

**环境变量支持**:
- 优先使用新名称：ROBLOX_API_KEY, UNIVERSE_ID, TEST_PLACE_ID
- 向后兼容旧名称：RBXCLOUD_API_KEY, RBXCLOUD_UNIVERSE_ID, RBXCLOUD_PLACE_ID
- 使用 dotenv 从 `.env.roblox` 自动加载（静默模式）

### Test Runner (`scripts/test-in-roblox-cloud.js`)

主测试执行工具，完整的测试流程：

1. **Rojo Build**: 构建项目到`test-place.rbxl`
2. **Upload**: 使用API上传到Roblox Cloud
3. **Execute**: 提交测试脚本到Cloud执行
4. **Poll & Report**: 轮询获取结果并生成报告

### Cloud Test Script (`scripts/cloud-test.lua`)

在Roblox Cloud中执行的测试脚本，核心功能：

1. **环境检测**: 设置`_G.__isInCloud__`标志，供TypeScript代码检测云端环境
2. **输出捕获**: 重写全局`print/warn`函数（在require TestEZ之前），捕获所有测试输出
3. **最小化Reporter**: 使用 SilentReporter 减少运行时开销
4. **项目类型支持**:
   - TypeScript项目: `ReplicatedStorage.rbxts_include`（优先使用 `@white-dragon-bevy` 包提高性能）
   - Lua项目: `ReplicatedStorage.Lib`
5. **语法检查**: 执行测试前预检查所有测试文件，提前发现语法错误
6. **文件名过滤**: 递归扫描匹配`.spec`文件（不区分大小写）
7. **错误处理**: 使用 xpcall 捕获完整堆栈跟踪，自动过滤 TestEZ 内部代码
8. **JSON结果**: 返回包含统计、错误、堆栈跟踪、捕获输出的JSON格式结果

## Toolchain

### Rokit Tool Management

在`rokit.toml`中定义的工具：
- `rojo` (7.4.4): Roblox项目构建工具

**注意**：
- ❌ 不再需要 `wally` - 不使用外部包管理器
- ❌ 不再需要 `rbxcloud` - 已使用自己的 API 实现替代

### TestEZ 管理

**内置 TestEZ**: TestEZ 源码内置在项目中，位于：
```
TestService/test-cloud-testez/testez/
```

**优势**：
- ✅ 无需 `wally install`
- ✅ 无需 `@rbxts/testez` npm 包
- ✅ 完全控制 TestEZ 源码
- ✅ 包含自定义改进（require() 错误处理）
- ✅ 版本固定，不会意外更新破坏

详见: [TESTEZ_MIGRATION.md](./TESTEZ_MIGRATION.md)

### Build System

使用Rojo构建：
```bash
rojo build default.project.json -o test-place.rbxl
```

项目结构（`default.project.json`）：
- `TestService`: 包含测试相关文件，包括 TestEZ 源码
- `ReplicatedStorage/Lib`: Lua源代码（用于测试）
- `ServerScriptService/Server`: 服务器端代码和测试

## Test Execution

### Main Commands

运行所有测试：
```bash
node scripts/test-in-roblox-cloud.js
```

运行特定测试（支持pattern匹配）：
```bash
node scripts/test-in-roblox-cloud.js <pattern>
```

示例：
```bash
node scripts/test-in-roblox-cloud.js StringUtils    # 运行StringUtils相关测试
node scripts/test-in-roblox-cloud.js -V             # Verbose模式
node scripts/test-in-roblox-cloud.js --skip-build   # 跳过构建步骤
```

命令选项：
- `-V, --verbose`: 详细输出（可多次指定增加详细程度，-VV为最详细）
- `-t, --timeout <sec>`: 任务执行超时时间（秒），默认120秒
- `-r, --rbxl <path>`: 指定rbxl文件路径（默认: test-place.rbxl）
- `-j, --jest`: 使用 jest 而非 testez（默认: testez）
- `--roots <path>`: 测试根路径，用 / 分隔（默认: ReplicatedStorage）
- `--glob <match>`: 在根路径中匹配测试文件
- `--skip-build`: 跳过Rojo构建步骤
- `-h, --help`: 显示帮助信息
- `-v, --version`: 显示版本信息

### Test Results

测试结果保存在`.test-result/`目录：
- 自动保存为**YAML格式**（易于人工阅读和Git diff）
- 保留最近2次结果（自动清理旧结果）
- **堆栈跟踪过滤**: 自动过滤掉 TestEZ 包内部的代码，只显示用户代码相关信息
- 捕获所有print/warn输出（`printMessages`字段）
- 分段保存：metadata、summary、errors、printMessages（用空行分隔）

## Environment Configuration

### Required Environment Variables

支持两种环境变量文件（推荐使用 `.env.roblox`）：

1. **`.env.roblox`** - 项目专用配置（推荐）
2. **`.env`** - 本地开发配置（可选，优先级更高）

**配置示例（.env.roblox）**:

```bash
# 推荐使用新的环境变量名（简洁清晰）
ROBLOX_API_KEY=<your-api-key>      # Roblox Open Cloud API Key
UNIVERSE_ID=<universe-id>           # Universe ID
TEST_PLACE_ID=<place-id>            # Test Place ID

# 旧的环境变量名（仍然支持，向后兼容）
# RBXCLOUD_API_KEY=<your-api-key>
# RBXCLOUD_UNIVERSE_ID=<universe-id>
# RBXCLOUD_PLACE_ID=<place-id>

# 代理配置（可选）
# 如果需要通过代理访问 Roblox API，配置以下任一变量
HTTPS_PROXY=http://proxy.example.com:8080    # HTTPS 代理
# HTTP_PROXY=http://proxy.example.com:8080   # HTTP 代理（HTTPS_PROXY 优先）
```

环境变量由`rbx-cloud-api.js`自动加载（使用dotenv，静默模式）。

**加载优先级**:
- 文件优先级: `.env` > `.env.roblox` （`.env` 可以覆盖 `.env.roblox` 中的配置）
- API Key: 新名称 > 旧名称（如果同时定义了两种名称，将使用新名称）
- 代理: HTTPS_PROXY > HTTP_PROXY

**使用场景**:
- `.env.roblox`: 团队共享的默认配置（可以提交到 Git，但包含敏感信息时应排除）
- `.env`: 本地开发专用配置（不提交到 Git），用于覆盖 `.env.roblox` 的配置

### Git Ignore

`.gitignore`忽略：
- `test-place.rbxl`: 构建产物
- `.env*`: 环境配置（包含敏感信息）
- `.test-result/`: 测试结果
- `out/`: roblox-ts 编译输出（TypeScript 项目）

## Test Examples

### Lua Test Files

项目包含示例测试：

**`src/MathUtils.lua` + `src/MathUtils.spec.lua`**
- 数学工具函数测试
- 测试用例：add, subtract, multiply, divide, isEven, isPrime, factorial

**`src/StringUtils.lua` + `src/StringUtils.spec.lua`**
- 字符串工具函数测试
- 测试用例：reverse, startsWith, endsWith, split, trim, titleCase
- 已修复：endsWith处理空字符串的bug

### Writing Tests

TestEZ测试格式：
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

## Technical Details

### API Implementation

直接使用Node.js `https`模块调用Roblox Cloud API：

**上传Place (API v1)**:
```
POST /universes/v1/{universeId}/places/{placeId}/versions?versionType=Saved
Content-Type: application/octet-stream
x-api-key: {apiKey}
```

**执行Luau (API v2)**:
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

**代理支持**:
- 使用 `https-proxy-agent` 支持 HTTP/HTTPS 代理
- 自动从环境变量 `HTTPS_PROXY` 或 `HTTP_PROXY` 读取代理配置
- 支持认证代理：`http://username:password@proxy.example.com:8080`
- 所有 API 请求（上传、执行、查询）都会通过代理

### Cloud API Limitations

1. **只能捕获返回值**: Luau Execution API只捕获脚本的return值
2. **LogService不可用**: Cloud环境中LogService事件不会触发
3. **解决方案**:
   - 重写全局print/warn函数（在require TestEZ之前）并设置到 `_G.print` / `_G.warn`
   - 测试文件中使用 `_G.print()` 来输出可被捕获的消息
   - 使用 SilentReporter 最小化运行时开销
   - 通过JSON返回所有信息（测试统计、错误、堆栈跟踪、捕获输出）
4. **超时配置**: executeLuau支持timeout参数（1-300秒范围），默认300秒

### Print 输出捕获

测试文件中需要使用 `_G.print()` 和 `_G.warn()` 来输出消息：

```lua
return function()
    _G.print("🧪 Starting tests...")

    describe("MyModule", function()
        it("should work", function()
            _G.print("Testing something")
            expect(true).to.equal(true)
        end)
    end)
end
```

捕获的输出会：
- 保存在 `.test-result/*.json` 文件的 `printMessages` 字段
- 在 verbose 模式（`-V`）下显示在控制台

### Test Filtering

- **文件级过滤**: 匹配`.spec`文件名（使用纯文本匹配，不是正则）
- **递归扫描**: 支持嵌套目录结构（包括ModuleScript的子对象）
- **大小写不敏感**: 使用`string.lower()`进行匹配
- **错误提示**: 如果没有匹配的文件，会列出所有可用的测试文件

### 堆栈跟踪过滤

为了提高可读性，堆栈跟踪会自动过滤掉 TestEZ 内部代码：

**过滤规则**:
- 过滤包含 `TestService.test-cloud-testez.testez` 的行（TestEZ 内部代码）
- 只保留用户代码相关的堆栈信息

**过滤位置**:
- `TestService/test-cloud-testez/testez/TestRunner.lua`: TestEZ 内部的错误处理（xpcall error handler）
- `TestService/test-cloud-testez/testez/TestPlan.lua`: TestPlan 执行时的错误处理
- `scripts/cloud-test.lua`: 在Lua端收集错误时过滤
- `scripts/test-in-roblox-cloud.js`: 在JS端保存结果前再次过滤

### 语法检查

在运行测试之前，会对所有测试文件进行预检查：

1. **加载检查**: 使用 `xpcall(require)` 尝试加载每个测试文件
2. **错误定位**: 提取包含行号的错误位置信息
3. **友好提示**: 提供具体的文件路径、行号和修复建议
4. **提前失败**: 如果发现语法错误，立即返回错误信息，不执行测试

## Performance

典型执行时间：
- 完整流程（Build + Upload + Test）: ~8-15秒
- 跳过构建（--skip-build）: ~5-8秒
- 测试执行超时: 默认120秒（可通过`-t`参数配置）
- 轮询配置:
  - 初始等待: 5秒
  - 轮询间隔: 3秒
  - 最大尝试次数: 60次
  - 默认超时: 60秒（在pollTaskUntilComplete中）

**性能优化**:
- TypeScript项目优先扫描 `@white-dragon-bevy` 包（如果存在），避免扫描整个 `rbxts_include`
- 使用 SilentReporter 而非 CustomReporter，减少运行时开销
- 语法预检查避免不必要的测试执行

## Migration Notes

如果你有使用旧版rbxcloud工具的代码：

1. **移除rbxcloud依赖**: 不再需要rokit安装rbxcloud
2. **使用新API模块**: 导入`./rbx-cloud-api.js`
3. **环境变量**: 保持不变，仍使用`.env.roblox`
4. **功能兼容**: 所有原有功能都已实现

## Special Notes

1. **无外部依赖**: 只使用Node.js内置模块（https, fs, path），无需安装额外工具
2. **更好的调试**: 可直接查看HTTP请求/响应（verbose模式）
3. **更快的执行**: 减少了进程调用开销，直接使用Node.js https模块
4. **更易维护**: API逻辑清晰独立在`rbx-cloud-api.js`中
5. **项目类型支持**: 同时支持TypeScript和Lua项目结构
6. **错误过滤**: 自动过滤TestEZ内部代码，只显示用户代码相关的堆栈跟踪
7. **YAML输出**: 使用YAML格式保存测试结果，便于人工阅读和版本控制
8. **语法检查**: 提前发现测试文件中的语法错误，提供清晰的错误定位
9. **向后兼容**: 支持新旧两种环境变量名，平滑迁移
