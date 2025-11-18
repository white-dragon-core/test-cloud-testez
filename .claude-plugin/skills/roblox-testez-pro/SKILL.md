---
name: test-cloud-testez
description: Write and manage Roblox unit tests using TestEZ in Roblox Cloud. Built-in TestEZ (no external dependencies), improved error handling, supports TypeScript/Lua projects, automatic test discovery, and detailed error reporting.
---

# Roblox Cloud TestEZ Testing Skill

A comprehensive tool for writing and running Roblox unit tests using TestEZ in Roblox Cloud environment.

## 🎯 核心特性

✅ **内置 TestEZ** - TestEZ 源码内置在 `TestService/test-cloud-testez/testez/`，无需外部依赖
✅ **改进的错误处理** - require() 错误提供详细的位置信息
✅ **云端测试** - 直接在 Roblox Cloud 中运行测试，无需 Studio
✅ **Studio测试** - 直接在 Roblox Studio 中按 F8 启动测试.
✅ **自动测试发现** - 递归扫描 `.spec` 文件
✅ **详细报告** - YAML 格式测试结果，易于阅读和版本控制


## What is TestEZ?

TestEZ is a testing framework for Roblox that provides a familiar, Jest-like API for writing unit tests in Luau. It supports:

- BDD-style test organization with `describe` and `it` blocks
- Rich assertion library with `expect`
- Lifecycle hooks (`beforeEach`, `afterEach`, `beforeAll`, `afterAll`)
- Test focusing and skipping
- Nested test suites

## ⚡ TestEZ expect() 快速参考

**可用的匹配器**（只有这 5 个）：
- `expect(x).to.equal(y)` - 相等
- `expect(x).to.be.near(y, limit?)` - 接近（浮点数）
- `expect(fn).to.throw(msg?)` - 抛出错误
- `expect(x).to.be.a("type")` - 类型检查
- `expect(x).to.be.ok()` - truthy 检查

**数值比较**
```lua
expect(score > 100).to.equal(true)   -- ✅ 大于
expect(level < 10).to.equal(true)    -- ✅ 小于
```

## 🔧 扩展 Matchers (ExpectationMatchers)

项目内置了扩展 matchers, 无需引用, 保留 testtez使用习惯, 可以透明调用。

**表比较**:
- `deepEqual(value)` - 深度相等比较（递归比较表内容）
- `members(list)` - 数组包含所有成员（无序）

**字符串检查**:
- `include(substring)` / `contain(substring)` - 包含子字符串/元素
- `match(pattern)` - 匹配 Lua 模式
- `startWith(prefix)` - 以某前缀开始
- `endWith(suffix)` - 以某后缀结束

**数值比较**:
- `greaterThan(value)` / `above(value)` - 大于
- `lessThan(value)` / `below(value)` - 小于
- `greaterThanOrEqual(value)` / `atLeast(value)` - 大于等于
- `lessThanOrEqual(value)` / `atMost(value)` - 小于等于
- `within(min, max)` - 在范围内（含边界）
- `NaN()` - 是 NaN

**长度/大小**:
- `lengthOf(length)` - 字符串或表的长度
- `empty()` - 为空（表或字符串）

**属性/键检查**:
- `property(name, value?)` - 有属性（可选检查值）
- `keys(...)` - 有特定键

**值检查**:
- `oneOf(list)` - 是列表中的一个
- `nilValue()` - 是 nil
- `trueValue()` - 是 true（非 truthy）
- `falseValue()` - 是 false（非 falsy）

**示例**:
```lua
expect({a = 1, b = 2}).to.deepEqual({a = 1, b = 2})
expect("hello world").to.include("world")
expect(10).to.greaterThan(5)
expect({1, 2, 3}).to.lengthOf(3)
expect({name = "test"}).to.property("name", "test")
expect(5).to.within(1, 10)
expect("test.lua").to.endWith(".lua")
```

## 📦 安装与配置

### 环境要求

- Node.js (用于构建和运行测试脚本)
- Roblox Open Cloud API Key
- Rojo (用于构建 place 文件)

### 安装

```bash
npm install test-cloud-testez
# 或
pnpm add test-cloud-testez
```

### 环境配置

创建 `.env.roblox` 文件:

```bash
ROBLOX_API_KEY=<your-api-key>      # Roblox Open Cloud API Key
UNIVERSE_ID=<universe-id>           # Universe ID
TEST_PLACE_ID=<place-id>            # Test Place ID

# 可选：代理配置
HTTPS_PROXY=http://proxy.example.com:8080
```

## Using This Skill

When active, this skill helps Claude:

1. **Write TestEZ test specs** with proper structure and syntax
2. **Organize tests** using describe/it blocks and lifecycle hooks
3. **Create assertions** using TestEZ's expect API
4. **Mock dependencies** and Roblox services for isolated testing
5. **Test async operations** with proper wait handling
6. **Follow best practices** for Roblox game testing

## Examples

This skill includes four comprehensive example files:

### basic.spec.lua
Demonstrates fundamental TestEZ concepts:
- Basic describe/it structure
- Common assertions (equality, type checking, truthiness)
- Error handling and testing exceptions
- Working with Luau data types


### lifecycle.spec.lua
Shows lifecycle hook usage:
- beforeEach/afterEach for test setup and cleanup
- beforeAll/afterAll for expensive resource management
- Nested describe blocks with inherited hooks
- Roblox instance creation and cleanup

### mocking.spec.lua
Covers testing with mocks and test doubles:
- Creating mock objects and spy functions
- Mocking Roblox services (DataStoreService, TweenService)
- Dependency injection patterns
- Testing RemoteEvents and time-dependent code

### async.spec.lua
Handles asynchronous testing:
- Testing callbacks and delays
- Promise-like patterns
- Simulated network requests
- Event-based async code
- Retry logic and timeout handling

## Quick Start

Ask Claude to help you write tests:

```
Create TestEZ tests for my Inventory module that tests:
- Adding items
- Removing items
- Stack limits
- Invalid inputs
```

Or improve existing tests:

```
Review my TestEZ tests and suggest improvements for better coverage
```

## Best Practices

The skill encourages:

- ✅ Descriptive test names that explain what's being tested
- ✅ One assertion per test (single responsibility)
- ✅ Independent tests that don't rely on execution order
- ✅ Proper cleanup with afterEach hooks
- ✅ Mocking external dependencies
- ✅ Testing edge cases and error conditions



## 🚀 运行测试

### 基本命令

```bash
# 运行所有测试
npm test

# 运行特定测试
npm test -- StringUtils

# 详细输出模式
npm test -- -V

# 跳过构建步骤
npm test -- --skip-build

# 自定义超时时间（秒）
npm test -- -t 180
```

### 命令选项

- `-V, --verbose`: 详细输出（可多次使用：-VV 最详细）
- `-t, --timeout <sec>`: 任务执行超时时间（默认 120 秒）
- `-r, --rbxl <path>`: 指定 rbxl 文件路径
- `--roots <path>`: 测试根路径（默认：ServerScriptService;ReplicatedStorage）
- `--skip-build`: 跳过 Rojo 构建步骤
- `-h, --help`: 显示帮助信息

### 测试结果

测试结果保存在 `.test-result/` 目录:
- **YAML 格式** - 易于阅读和 Git diff
- **自动清理** - 保留最近 2 次结果
- **堆栈跟踪过滤** - 自动过滤 TestEZ 内部代码
- **捕获输出** - 包含所有 `print()` 和 `warn()` 输出

## 📝 云测试特性

### 打印输出

✅ **普通 print() 和 warn()** - 使用 LogService.MessageOut 事件自动捕获

**重要**: 禁止任何测试用例输出 `print()` 或 `warn()`, 以免污染测试环境
**注意**: 紧急情况下进行调试, 允许使用 `print()`, 调试完成后立即移除 `print()` 语句.

```lua
return function()
    print("🧪 Starting tests...")  -- ✅ 会被捕获

    describe("MyModule", function()
        it("should work", function()
            print("Testing something")  -- ✅ 会被捕获
            warn("This is a warning")   -- ✅ warn 也会被捕获
            expect(true).to.equal(true)
        end)
    end)
end
```

### 改进的错误处理

当 require() 发生错误时，会显示详细的位置信息:

```
Error: Requested module experienced an error while loading
Stack trace:
  → Failed at: ServerScriptService.Server.MyModule:42
ServerScriptService.Server.MyModule:42
```

详见: [TESTEZ_REQUIRE_ERROR_FIX.md](../../../TESTEZ_REQUIRE_ERROR_FIX.md)

## ❓ 常见问题

### Q: TestEZ 在哪里？需要安装吗？
**A**: TestEZ 源码内置在 `TestService/test-cloud-testez/testez/`，无需安装。不需要 Wally 或 @rbxts/testez。

### Q: 如何在测试中打印调试信息？
**A**: 直接使用 `print()` 和 `warn()` 即可，输出会被自动捕获（使用 LogService.MessageOut）。调试完成后立即移除。

### Q: require() 错误信息不够详细？
**A**: 已修复！现在会显示具体的错误位置，如 `→ Failed at: ServerScriptService.Server.MyModule:42`

### Q: 测试结果保存在哪里？
**A**: `.test-result/` 目录，YAML 格式，自动保留最近 2 次结果。

### Q: 如何配置测试路径？
**A**: 使用 `--roots` 参数：`npm test -- --roots ServerScriptService/Server`

### Q: 报错: can't get type descriptor for id=nil text=nil
**A**: 删除 `./out/` 目录，重新编译：`npx rbxtsc`

### Q: 报错: Cannot find name 'expect/it/describe/l...'
**A**: 写入 testez.d.ts, 包含定义文件: `/// <reference types="@rbxts/test-cloud-testez/index" />`

## 📚 Resources

### 文档
### 本项目文档
- [README.md](../../../README.md) - 项目概览
- [CLAUDE.md](../../../CLAUDE.md) - Claude Code 使用说明
