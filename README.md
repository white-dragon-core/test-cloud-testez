# Roblox Cloud TestEZ 测试工具

在 Roblox Cloud 环境中运行 TestEZ 测试的轻量级工具 - 内置 TestEZ，无需外部依赖。

## 🎯 核心特性

✅ **内置 TestEZ** - 无需 Wally 或 @rbxts/testez，TestEZ 源码内置在 `TestService/test-cloud-testez/testez/`
✅ **改进的错误处理** - require() 错误显示详细的位置信息 (`→ Failed at: <location>`)
✅ **零外部测试依赖** - 仅使用 Node.js 内置模块
✅ **快速执行** - ~8-15 秒完整测试流程
✅ **详细报告** - YAML 格式，易于阅读和版本控制
✅ **自动测试发现** - 递归扫描 `.spec` 文件
✅ **支持双项目** - TypeScript 和 Lua 项目通用

## 📦 安装

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

TestEZ 源码内置在项目中: `TestService/test-cloud-testez/testez/`

- ✅ 无需 `wally install`
- ✅ 无需 `@rbxts/testez` npm 包
- ✅ 包含自定义改进（require() 错误处理）

## 🚀 快速开始

### 运行所有测试

```bash
npm test
```

### 运行特定测试

```bash
npm test -- StringUtils
```

### 详细输出模式

```bash
npm test -- -V
# 或更详细
npm test -- -VV
```

### 自定义选项

```bash
# 跳过构建步骤
npm test -- --skip-build

# 自定义超时时间（秒）
npm test -- -t 180

# 指定测试根路径
npm test -- --roots ServerScriptService/Server

# 显示帮助信息
npm test -- -h
```

## 📋 命令选项

| 选项 | 描述 | 默认值 |
|------|------|--------|
| `-V, --verbose` | 详细输出模式（可多次使用：-VV 最详细） | - |
| `-t, --timeout <sec>` | 任务执行超时时间（秒） | 120 |
| `-r, --rbxl <path>` | 指定 rbxl 文件路径 | test-place.rbxl |
| `--roots <path>` | 测试根路径，用 `;` 分隔 | ServerScriptService;ReplicatedStorage |
| `--glob <match>` | 在根路径中匹配测试文件 | - |
| `--skip-build` | 跳过 Rojo 构建步骤 | false |
| `-h, --help` | 显示帮助信息 | - |
| `-v, --version` | 显示版本信息 | - |

## 📝 测试结果

测试结果保存在 `.test-result/` 目录:

- **YAML 格式** - 易于人工阅读和 Git diff
- **自动清理** - 保留最近 2 次结果
- **堆栈跟踪过滤** - 自动过滤 TestEZ 内部代码，只显示用户代码
- **捕获输出** - 包含所有 `_G.print()` 和 `_G.warn()` 输出

### 结果文件结构

```yaml
timestamp: '2025-11-18T04:00:00.000Z'
success: true
totalTests: 58
passed: 58
failed: 0
skipped: 0

errors: []

printMessages:
  - message: '🧪 Starting tests...'
    type: print
    timestamp: 1763437508
```

## 💡 编写测试

### 基本测试结构

```lua
-- MyModule.spec.lua
return function()
    local MyModule = require(script.Parent.MyModule)

    describe("MyModule", function()
        it("should do something", function()
            local result = MyModule.doSomething()
            expect(result).to.equal(expected)
        end)
    end)
end
```

### 打印输出

在云测试环境中，使用 `_G.print()` 输出调试信息:

```lua
return function()
    _G.print("🧪 Starting tests...")  -- ✅ 会被捕获

    describe("MyModule", function()
        it("should work", function()
            _G.print("Testing something")  -- ✅ 会被捕获
            expect(true).to.equal(true)
        end)
    end)

    _G.print("✅ Tests completed")
end
```

**注意**: 调试完成后立即移除 `_G.print()`，避免影响性能。

### TestEZ 可用匹配器

TestEZ 只提供 5 个核心匹配器:

1. **`.to.equal(value)`** - 检查值是否相等
2. **`.to.be.near(value, limit?)`** - 检查数值是否接近（浮点数）
3. **`.to.throw(msg?)`** - 检查函数是否抛出错误
4. **`.to.be.a(type)`** - 检查值类型
5. **`.to.be.ok()`** - 检查值是否为 truthy

**数值比较**（没有 `.greaterThan()`）:
```lua
expect(score > 100).to.equal(true)   -- ✅ 大于
expect(level < 10).to.equal(true)    -- ✅ 小于
expect(value >= 0).to.equal(true)    -- ✅ 大于等于
```

## 🔧 改进的功能

### 1. 改进的 require() 错误处理

当测试中的 `require()` 发生错误时，会显示详细的位置信息:

**改进前**:
```
Requested module experienced an error while loading
ServerScriptService.Server.MyTest.spec:42
```

**改进后**:
```
Requested module experienced an error while loading
  → Failed at: ServerScriptService.Server.MyTest.spec:42
ServerScriptService.Server.MyTest.spec:42
TaskScript:361
```

详见: [TESTEZ_REQUIRE_ERROR_FIX.md](./TESTEZ_REQUIRE_ERROR_FIX.md)

### 2. 内置 TestEZ

TestEZ 源码内置在 `TestService/test-cloud-testez/testez/`，带来以下优势:

- ✅ **完全控制** - 可以自由修改 TestEZ 源码
- ✅ **无外部依赖** - 不需要 Wally 或 @rbxts/testez
- ✅ **简化构建** - 一个 `npm run build` 即可
- ✅ **保留修改** - 包含我们的自定义改进
- ✅ **版本固定** - 不会因包更新而意外破坏

详见: [TESTEZ_MIGRATION.md](./TESTEZ_MIGRATION.md)

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

### Q: 如何过滤测试文件？
**A**: 传递测试名称作为参数：`npm test -- MyModule`（不区分大小写）

### Q: 如何调试超时问题？
**A**: 使用 `-t` 参数增加超时时间：`npm test -- -t 300`（300 秒）

### Q: 支持哪些项目类型？
**A**: 支持 TypeScript（roblox-ts）和 Lua 项目。自动检测项目类型。

## 📚 文档

- [TESTEZ_REQUIRE_ERROR_FIX.md](./TESTEZ_REQUIRE_ERROR_FIX.md) - require() 错误处理改进
- [TESTEZ_MIGRATION.md](./TESTEZ_MIGRATION.md) - TestEZ 迁移文档（从 Wally 到内置）
- [CLAUDE.md](./CLAUDE.md) - Claude Code 使用说明

## 🔗 相关资源

- [TestEZ 官方文档](https://roblox.github.io/testez/)
- [Luau 语言参考](https://luau-lang.org/)
- [Roblox Open Cloud API](https://create.roblox.com/docs/cloud/open-cloud)
- [Rojo 文档](https://rojo.space/)

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

**由 White Dragon 开发** | Version 0.3.6
