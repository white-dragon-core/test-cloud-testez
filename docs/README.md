# Roblox TestEZ Testing Skill

A comprehensive skill for writing and managing Roblox unit tests using TestEZ, a BDD-style testing framework.

## What is TestEZ?

TestEZ is a testing framework for Roblox that provides a familiar, Jest-like API for writing unit tests in Luau. It supports:

- BDD-style test organization with `describe` and `it` blocks
- Rich assertion library with `expect`
- Lifecycle hooks (`beforeEach`, `afterEach`, `beforeAll`, `afterAll`)
- Test focusing and skipping
- Nested test suites

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

### Manual Installation

Copy the `roblox-testez` folder to your `.claude/skills/` directory.

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

## Resources

- [TestEZ Documentation](https://roblox.github.io/testez/)
- [Luau Language Reference](https://luau-lang.org/)
- [Roblox Testing Best Practices](https://create.roblox.com/docs/scripting/testing)

## License

This skill is part of the Anthropic Agent Skills repository and is licensed under Apache 2.0.
