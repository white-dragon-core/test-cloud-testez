---
name: roblox-testez-pro
description: Write and manage Roblox unit tests using TestEZ, a BDD-style testing framework. Supports creating test specs with describe/it blocks, assertions with expect, lifecycle hooks (beforeAll/afterEach), and best practices for testing Roblox game code.
---

# Roblox TestEZ Testing

在 Roblox Cloud 和 Studio 环境运行 TestEZ 测试。支持 TypeScript/Lua 项目，提供 Cloud API 测试、Studio 本地测试、超时调试等功能。可配置测试路径、环境变量、输出格式。

## 安装
- `npm install test-cloud-testez` 或 `pnpm add test-cloud-testez`

## 指令
- **npx test-cloud-testez**: 使用 `roblox cloud`进行测试, 用于 `ai 开发`和 `ci`, 一般配置为 `npm test`

## Resources
- [studio-testing](./references/testeez-studio-testing.md)
- [cloud-testing](./references/testeez-cloud-testing.md)
