# Roblox Studio 测试指南

本文档介绍如何在 Roblox Studio 中运行 TestEZ 测试。

## 概述

Studio 测试允许你在 Roblox Studio 内部直接运行测试，无需上传到 Cloud。这适合：
- 本地开发和调试
- 快速迭代测试
- 交互式测试环境
- 可视化调试

## 快速开始

### 安装依赖

```bash
# 安装 Roblox 包
wally install

# 启动 Rojo 服务器
rojo serve default.project.json
```

### 在 Studio 中运行测试

1. 打开 Roblox Studio
2. 连接到 Rojo 插件
3. 按 **F5** (Run) 或 **F8** (Play)
4. 在 Output 窗口查看测试结果

## 安装为包

如果你想在自己的项目中使用这个测试工具：

### 使用 Wally

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

### 手动安装

或者手动将此工具添加到你的项目：

1. 将 `TestService/test-cloud-testez` 目录复制到你的项目
2. 在 `default.project.json` 中配置（见下一节）

## 配置 Studio 测试

### 配置 default.project.json

要在 Roblox Studio 中运行测试，需要在 `default.project.json` 中添加 TestService 配置：

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
}
```

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

在 Studio 测试中，print 输出会自动显示在 Output 窗口：

```lua
return function()
    print("开始测试...")  -- 会显示在 Output 窗口

    describe("MyModule", function()
        it("应该正常工作", function()
            print("测试某些功能")  -- 会显示在 Output 窗口
            expect(true).to.equal(true)
        end)
    end)
end
```

**注意**：在 Studio 中可以直接使用 `print()`，不需要使用 `_G.print()`（Cloud 测试才需要）。

## Timeout 调试工具

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

## 故障排除

### 测试未运行

**可能原因**：
- 不在 Run Mode
- Output 窗口中有错误信息
- Rojo 未正确同步项目结构

**解决方法**：
1. 确保在 **Run Mode** 下（F5 或 F8），测试不会在编辑模式下运行
2. 检查 Output 窗口是否有错误信息
3. 确认 Rojo 已正确同步项目结构

### 找不到 TestEZ

**错误信息**：`❌ 无法找到 TestEZ！请确保已通过 Wally 或 npm 安装 TestEZ`

**解决方法**：
1. 运行 `wally install` 安装依赖
2. 使用 Rojo 同步项目到 Studio
3. 确认 `ReplicatedStorage.Packages` 中存在 TestEZ

### 只测试了部分目录

**可能原因**：
- 某些目录不存在
- `default.project.json` 配置缺失
- Rojo 未同步最新配置

**解决方法**：
- 查看测试日志，确认哪些目录被找到
- 如果某个目录未找到（显示 `✗ 未找到`），请检查：
  1. `default.project.json` 中是否配置了该路径
  2. Rojo 是否已同步最新配置
  3. 目录是否存在于源代码中

### `_G.print` is nil 错误

**已修复**：这个错误已在最新版本修复。

如果仍然遇到，请确保使用最新版本的 `start.server.lua`。

### 测试超时问题

**可能原因**：
- 某个测试文件或测试用例执行时间过长
- 测试中存在无限循环
- 外部依赖响应慢

**解决方法**：
- 使用 [Timeout 调试工具](#timeout-调试工具) 精确定位超时的测试文件和测试用例
- 该工具采用两层细化定位策略，逐帧执行测试避免整体超时
- 查看 Output 窗口中的详细日志，定位具体哪个测试超时

### 语法错误

如果测试文件存在语法错误，测试会失败并在 Output 窗口显示错误：

```
❌ 语法错误: ServerScriptService.TestService.MyModule.spec
```

修复文件中的语法错误后重新运行测试。

## 示例测试

项目包含示例测试在 `src/`：

- **MathUtils** - 数学工具函数测试（add, subtract, multiply, divide, isEven, isPrime, factorial）
- **StringUtils** - 字符串工具函数测试（reverse, startsWith, endsWith, split, trim, titleCase）

## Studio 与 Cloud 测试对比

| 特性 | Studio 测试 | Cloud 测试 |
|------|------------|------------|
| **运行环境** | Roblox Studio 本地 | Roblox Cloud 云端 |
| **速度** | 即时反馈 | ~8-15 秒 |
| **调试** | 可视化调试，断点支持 | 日志输出 |
| **CI/CD** | ❌ 不适合 | ✅ 理想选择 |
| **输出捕获** | 自动显示在 Output 窗口 | 需要 `_G.print()` |
| **设置复杂度** | 简单（只需 Rojo） | 中等（需要 API 凭据） |
| **适用场景** | 本地开发和调试 | 自动化测试和 CI/CD |

## 最佳实践

### 开发工作流

1. **本地开发**：在 Studio 中编写和测试代码
2. **快速验证**：使用 Studio 测试快速验证改动
3. **提交前检查**：使用 Cloud 测试确保在云端环境正常
4. **CI/CD**：在持续集成流程中使用 Cloud 测试

### 测试组织

- 将测试文件与源代码放在同一目录
- 使用 `.spec.lua` 后缀命名测试文件
- 为每个模块创建对应的测试文件
- 使用清晰的 describe 和 it 描述

### 性能优化

- 避免在测试中使用 `wait()` 或 `task.wait()`
- 使用 mock 代替真实的外部依赖
- 将慢速测试分离到单独的文件
- 使用 Timeout 调试工具定位性能瓶颈

### 调试技巧

- 使用 Studio Output 窗口查看详细日志
- 利用 Studio 的断点功能调试复杂逻辑
- 使用 Timeout 调试工具定位超时问题
- 在测试中添加 print 语句帮助理解执行流程
