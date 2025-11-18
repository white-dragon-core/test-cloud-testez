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

**数值比较**（TestEZ 没有 `.greaterThan()`）：
```lua
expect(score > 100).to.equal(true)   -- ✅ 大于
expect(level < 10).to.equal(true)    -- ✅ 小于
```

详见下方「数值比较的正确写法」部分。

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

### TestEZ 位置

TestEZ 源码位于: `TestService/test-cloud-testez/testez/`

- ✅ 无需 `wally install`
- ✅ 无需 `@rbxts/testez` npm 包
- ✅ 包含自定义改进（require() 错误处理）

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

**重要：TestEZ expect().to 可用接口列表**（防止拼写错误）

TestEZ 官方提供的 expect().to 匹配器（matchers）只有以下 5 个：

1. **`.to.equal(value)`** - 检查值是否相等
   ```lua
   expect(2 + 2).to.equal(4)
   ```

2. **`.to.be.near(value, limit?)`** - 检查数值是否接近（用于浮点数比较）
   ```lua
   expect(0.1 + 0.2).to.be.near(0.3, 0.0001)
   ```

3. **`.to.throw(messageSubstring?)`** - 检查函数是否抛出错误
   ```lua
   expect(function() error("fail") end).to.throw()
   expect(function() error("invalid") end).to.throw("invalid")
   ```

4. **`.to.be.a(typeName)`** 或 **`.to.be.an(typeName)`** - 检查值类型
   ```lua
   expect(42).to.be.a("number")
   expect("hello").to.be.a("string")
   ```

5. **`.to.be.ok()`** - 检查值是否为 truthy（非 nil）
   ```lua
   expect(true).to.be.ok()
   expect(nil).never.to.be.ok()
   ```

**❌ 不存在的接口**（AI 常犯的错误）：
- `.to.largeerThan()` ❌ 不存在（应该是 `expect(a > b).to.equal(true)`）
- `.to.greaterThan()` ❌ 不存在
- `.to.lessThan()` ❌ 不存在
- `.to.contain()` ❌ 不存在
- `.to.include()` ❌ 不存在
- `.to.haveLength()` ❌ 不存在

**⚠️ 注意事项**：
- TestEZ 没有 `.largerThan()`, `.greaterThan()`, `.lessThan()` 等数值比较匹配器
- 需要使用逻辑表达式配合 `.equal()` 进行比较
- 可以使用 `.never` 来否定断言

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

## Resources

- [TestEZ Documentation](https://roblox.github.io/testez/)
- [Luau Language Reference](https://luau-lang.org/)
- [Roblox Testing Best Practices](https://create.roblox.com/docs/scripting/testing)


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
- **捕获输出** - 包含所有 `_G.print()` 输出

## 📝 云测试特性

### 打印输出

❌ **普通 print()** - 在云测试环境下无法输出到日志
✅ **_G.print()** - 可以输出到日志，用于调试

**注意**: 调试完成后立即移除 `_G.print()`，否则可能导致错误。

```lua
return function()
    _G.print("🧪 Starting tests...")  -- ✅ 会被捕获

    describe("MyModule", function()
        it("should work", function()
            _G.print("Testing something")  -- ✅ 会被捕获
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
**A**: 使用 `_G.print()` 而不是普通的 `print()`。调试完成后立即移除。

### Q: require() 错误信息不够详细？
**A**: 已修复！现在会显示具体的错误位置，如 `→ Failed at: ServerScriptService.Server.MyModule:42`

### Q: 测试结果保存在哪里？
**A**: `.test-result/` 目录，YAML 格式，自动保留最近 2 次结果。

### Q: 如何配置测试路径？
**A**: 使用 `--roots` 参数：`npm test -- --roots ServerScriptService/Server`

### Q: 报错: can't get type descriptor for id=nil text=nil
**A**: 删除 `./out/` 目录，重新编译：`npx rbxtsc`

### Q: 报错: Cannot find name 'expect/it/describe/l...'
**A**: 写入 testez.d.ts, 包含定义文件: `/// <reference types="@rbxts/test-cloud-testez/globals" />`

## 📚 Resources

### 文档
- [TestEZ 官方文档](https://roblox.github.io/testez/)
- [Luau 语言参考](https://luau-lang.org/)
- [Roblox 测试最佳实践](https://create.roblox.com/docs/scripting/testing)

### 本项目文档
- [README.md](../../../README.md) - 项目概览
- [CLAUDE.md](../../../CLAUDE.md) - Claude Code 使用说明
- [TESTEZ_REQUIRE_ERROR_FIX.md](../../../TESTEZ_REQUIRE_ERROR_FIX.md) - require() 错误处理改进
- [TESTEZ_MIGRATION.md](../../../TESTEZ_MIGRATION.md) - TestEZ 迁移文档

### 参考资料
- [Studio 测试指南](./references/testeez-studio-testing.md)
- [Cloud 测试指南](./references/tetez-cloud-testing.md)
