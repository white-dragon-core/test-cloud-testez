---
name: roblox-testez-pro
description: Write and manage Roblox unit tests using TestEZ, a BDD-style testing framework. Supports creating test specs with describe/it blocks, assertions with expect, lifecycle hooks (beforeAll/afterEach), and best practices for testing Roblox game code.
---

# Roblox TestEZ Testing Skill

A comprehensive skill for writing and managing Roblox unit tests using TestEZ, a BDD-style testing framework.

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

## Installation

### Via Claude Code

If you've installed this skills repository as a Claude Code plugin:

```
/plugin install example-skills@anthropic-agent-skills
```

Then mention the skill in your conversation:

```
Use the roblox-testez skill to create tests for my player controller
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


## 云测试

在 Roblox Cloud 和 Studio 环境运行 TestEZ 测试。支持 TypeScript/Lua 项目，提供 Cloud API 测试、Studio 本地测试、超时调试等功能。可配置测试路径、环境变量、输出格式。

## 安装
- `npm install test-cloud-testez` 或 `pnpm add test-cloud-testez`

## 指令
- **npx test-cloud-testez**: 使用 `roblox cloud`进行测试, 用于 `ai 开发`和 `ci`, 一般配置为 `npm test`

## Resources
- [studio-testing](./references/testeez-studio-testing.md)
- [cloud-testing](./references/testeez-cloud-testing.md)
