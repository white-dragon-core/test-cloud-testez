# Roblox TestEZ 测试工具

一个轻量级的测试工具，支持在 Roblox Cloud 和 Roblox Studio 中运行 TestEZ 测试。

## 概述

本工具提供两种测试方式：

### 🌐 Cloud 测试

通过 Roblox Open Cloud API 在云端环境执行测试，无需打开 Roblox Studio。

**适用场景**：
- 持续集成/持续部署 (CI/CD)
- 自动化测试
- 快速验证代码变更
- 无图形界面的测试环境

**特性**：
- ✅ 零外部依赖（仅使用 Node.js 内置模块）
- ✅ 直接 API 调用（无需 rbxcloud 工具）
- ✅ 快速执行（~8-15 秒完整流程）
- ✅ 详细的测试结果和堆栈跟踪
- ✅ 灵活的测试过滤
- ✅ 支持 TypeScript 和 Lua 项目

📖 **详细文档**: [Cloud 测试指南](docs/cloud-testing.md)

### 🎮 Studio 测试

在 Roblox Studio 内部直接运行测试，提供交互式测试环境。

**适用场景**：
- 本地开发和调试
- 快速迭代测试
- 交互式测试环境
- 可视化调试

**特性**：
- ✅ 即时反馈
- ✅ 可视化调试
- ✅ 自动测试发现
- ✅ 支持断点调试
- ✅ Timeout 调试工具

📖 **详细文档**: [Studio 测试指南](docs/studio-testing.md)

## 快速开始

### 安装依赖

```bash
# 安装 Rokit 工具 (rojo, wally)
rokit install

# 安装 Roblox 包
wally install
```

### Cloud 测试

```bash
# 配置环境变量（复制 .env.example 到 .env.roblox 并填入你的凭据）
cp .env.example .env.roblox

# 运行所有测试
node scripts/test-in-roblox-cloud.js

# 运行特定测试
node scripts/test-in-roblox-cloud.js "StringUtils"

# 详细输出
node scripts/test-in-roblox-cloud.js -V
```

### Studio 测试

```bash
# 启动 Rojo 服务器
rojo serve default.project.json

# 在 Roblox Studio 中:
# 1. 连接到 Rojo 插件
# 2. 按 F5 (Run) 或 F8 (Play)
# 3. 在 Output 窗口查看测试结果
```

## 主要特性

- ✅ **双环境支持**: 同时支持 Cloud 和 Studio 测试
- ✅ **零外部依赖**: 仅使用 Node.js 内置模块
- ✅ **快速执行**: Cloud 测试 ~8-15 秒
- ✅ **丰富输出**: 详细的测试结果和堆栈跟踪
- ✅ **灵活过滤**: 基于 pattern 的测试选择
- ✅ **TypeScript & Lua**: 支持两种项目类型
- ✅ **多根路径**: 同时扫描多个目录
- ✅ **自动发现**: Studio 中自动测试发现
- ✅ **Timeout 调试**: 两层超时定位工具

## 环境配置（Cloud 测试）

创建 `.env.roblox` 文件：

```bash
# 推荐使用新的环境变量名
ROBLOX_API_KEY=your_api_key_here
UNIVERSE_ID=your_universe_id
TEST_PLACE_ID=your_place_id
```

**获取凭据**：
- **API Key**: [Roblox Creator Dashboard → Credentials](https://create.roblox.com/credentials)
  - 需要权限: `universe-places.write`, `universe-luau-execution.run`
- **Universe ID**: 在游戏设置中查找
- **Place ID**: 在 Place 设置中查找

## 使用示例

### Cloud 测试示例

```bash
# 运行所有测试
npm test

# 使用 verbose 模式
npm run test:verbose

# 跳过构建步骤
npm run test:skip-build

# 自定义扫描路径
node scripts/test-in-roblox-cloud.js --roots "ServerScriptService/Tests,ReplicatedStorage/Lib"

# 增加超时时间
node scripts/test-in-roblox-cloud.js -t 300
```

### 编写测试

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

## 项目结构

```
test-cloud-testez/
├── docs/                          # 详细文档
│   ├── cloud-testing.md          # Cloud 测试指南
│   └── studio-testing.md         # Studio 测试指南
├── scripts/                       # 测试脚本
│   ├── rbx-cloud-api.js          # Roblox Cloud API 封装
│   ├── test-in-roblox-cloud.js   # Cloud 测试主工具
│   └── cloud-test.lua            # Cloud 测试执行脚本
├── TestService/                   # Studio 测试脚本
│   └── test-cloud-testez/
│       ├── start.server.lua      # Studio 测试入口
│       └── two-step-find-timeout.server.lua  # Timeout 调试工具
├── src/                           # 示例代码和测试
├── default.project.json           # Rojo 项目配置
├── wally.toml                     # Wally 依赖配置
└── rokit.toml                     # Rokit 工具配置
```

## 测试工作流程

### Cloud 测试流程

1. **Build** - 使用 Rojo 构建 Place 文件
2. **Upload** - 上传到 Roblox Cloud (API v1)
3. **Execute** - 在 Cloud 中执行测试脚本 (API v2)
4. **Results** - 轮询并显示测试结果

### Studio 测试流程

1. **Connect** - Rojo 同步项目到 Studio
2. **Run** - 在 Studio 中运行测试
3. **Results** - 在 Output 窗口查看结果

## 文档

- 📖 [Cloud 测试指南](docs/cloud-testing.md) - Cloud 测试的完整文档
- 📖 [Studio 测试指南](docs/studio-testing.md) - Studio 测试的完整文档

## 示例测试

项目包含示例测试在 `src/`：

- **MathUtils** - 数学工具函数（add, subtract, multiply, divide, isEven, isPrime, factorial）
- **StringUtils** - 字符串工具函数（reverse, startsWith, endsWith, split, trim, titleCase）

## 故障排除

### Cloud 测试

- 找不到测试 → 确认文件名包含 `.spec`
- 上传失败 → 检查 API Key 权限和 ID 配置
- 任务超时 → 使用 `-t` 参数增加超时时间

详见 [Cloud 测试指南 - 故障排除](docs/cloud-testing.md#故障排除)

### Studio 测试

- 测试未运行 → 确保在 Run Mode (F5 或 F8)
- 找不到 TestEZ → 运行 `wally install` 并同步 Rojo
- 测试超时 → 使用 Timeout 调试工具定位问题

详见 [Studio 测试指南 - 故障排除](docs/studio-testing.md#故障排除)

## 性能

- **Cloud 测试**: ~8-15 秒（完整流程），~5-8 秒（跳过构建）
- **Studio 测试**: 即时反馈

## NPM 脚本

```bash
npm test                  # 运行所有测试
npm run test:verbose      # 详细输出模式
npm run test:skip-build   # 跳过构建步骤
npm run build             # 仅构建 Place 文件
```

## License

本项目用于演示和教育目的。
