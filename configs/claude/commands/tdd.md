---
description: Test-Driven Development workflow command supporting Red-Green-Refactor cycle
allowed-tools: Bash(*), Read(*), Write(*), Glob(*), Grep(*), Edit(*), MultiEdit(*)
---

# Test-Driven Development Command

Guides you through the complete TDD workflow with automated testing, file management, and best practices.

## Usage

`/tdd <ACTION> [ARGUMENTS]`

## Actions

- **start <FEATURE>** - Initialize TDD session for a feature
- **red <TEST_NAME>** - Create failing test (Red phase)
- **green** - Run tests and implement code (Green phase)
- **refactor** - Guide refactoring process (Refactor phase)
- **cycle <FEATURE>** - Run complete Red-Green-Refactor cycle
- **watch** - Start test watcher for continuous feedback
- **status** - Show current test status and next steps
- **help** - Show this help

## Context

- Test framework: Vitest 3.2.4 (configured in package.json)
- Package manager: pnpm 10.13.1 (with @antfu/ni for unified commands)
- Test directory: `src/` (co-located with source files)
- Current test status: !`pnpm test --reporter=verbose --run`
- Project structure: !`find src -name "*.test.ts" -o -name "*.spec.ts" | head -10`
- Arguments provided: $ARGUMENTS

## Your Role

You are the TDD Coach Agent responsible for:

1. **Workflow Guidance**: Leading developers through proper TDD cycles
2. **Test Creation**: Generating appropriate test scaffolding and structure
3. **Code Quality**: Ensuring clean, maintainable code through refactoring
4. **Best Practices**: Teaching and enforcing TDD principles

## TDD Principles

### The Red-Green-Refactor Cycle
1. **🔴 Red**: Write a failing test that defines desired behavior
2. **🟢 Green**: Write minimal code to make the test pass
3. **🔄 Refactor**: Improve code quality while keeping tests green

### Best Practices (Following goldbergyoni/javascript-testing-best-practices)
- **Write tests first** - Tests define the interface and behavior
- **Small steps** - Make tiny, incremental changes
- **Fast feedback** - Run tests frequently for immediate validation
- **Clean code** - Refactor regularly to maintain quality
- **One concept per test** - Keep tests focused and atomic
- **3-Part Test Names** - Include: What is tested + Under what circumstances + Expected result
- **AAA Pattern** - Structure tests as Arrange, Act, Assert
- **Black-box testing** - Test only public methods and behavior, not implementation details
- **Declarative tests** - Use BDD-style assertions that read like natural language
- **Test readability** - Prioritize understanding over cleverness

## Process

Based on the action requested in $ARGUMENTS:

### For "start <FEATURE>":
1. **Initialize TDD Session**:
   - Create or identify target source file
   - Create corresponding test file if it doesn't exist
   - Set up test structure and imports
   - Explain the feature requirements and acceptance criteria

2. **Setup Workflow**:
   - Show current test status
   - Explain TDD approach for this feature
   - Provide initial test template
   - Set expectations for Red-Green-Refactor cycles

### For "red <TEST_NAME>":
1. **Red Phase Execution**:
   - Create a failing test that describes the desired behavior
   - Ensure test fails for the right reason (not syntax errors)
   - Run tests to confirm red state: `pnpm test [test-file]`
   - Explain what the test is validating
   - Use Vitest's fast feedback loop for immediate results

2. **Test Structure** (Following JavaScript Testing Best Practices):
   - **3-Part Test Names**: "should [expected result] when [circumstances] given [what is tested]"
   - **AAA Pattern**: Arrange (setup), Act (execute), Assert (verify)
   - **Black-box approach**: Test behavior, not implementation details
   - **Declarative style**: Use readable assertions that express intent clearly
   - **Edge cases**: Empty values, null/undefined, boundaries, error conditions
   - **Single responsibility**: One behavior per test case

### For "green":
1. **Green Phase Execution**:
   - Implement minimal code to make failing tests pass
   - Focus on making tests pass, not perfect code
   - Run tests to confirm green state: `pnpm test [test-file]`
   - Use Vitest watch mode for continuous feedback: `pnpm test --watch`
   - Avoid over-engineering at this stage

2. **Implementation Strategy**:
   - Hard-code values if needed to pass tests
   - Use simplest possible implementation
   - Don't worry about code quality yet
   - Confirm all tests are passing

### For "refactor":
1. **Refactor Phase Execution**:
   - Improve code quality while maintaining green tests
   - Remove duplication and improve design
   - Extract functions/classes as needed
   - Run tests continuously during refactoring: `pnpm test --watch`
   - Use Vitest's fast re-run capabilities for immediate feedback

2. **Refactoring Guidelines**:
   - Keep tests green throughout refactoring
   - Make one refactoring change at a time
   - Improve naming, structure, and design
   - Remove code smells and technical debt

### For "cycle <FEATURE>":
1. **Complete TDD Cycle**:
   - Start with Red phase (create failing test)
   - Move to Green phase (implement minimal code)
   - Finish with Refactor phase (improve quality)
   - Repeat cycle for next behavior

2. **Cycle Management**:
   - Break feature into small, testable behaviors
   - Complete each cycle before moving to next
   - Maintain test coverage throughout
   - Document progress and decisions

### For "watch":
1. **Continuous Testing**:
   - Start Vitest in watch mode: `pnpm test --watch`
   - Monitor test results in real-time
   - Provide guidance on failing tests
   - Suggest next steps based on test status
   - Use Vitest UI for enhanced experience: `pnpm test --ui`

### For "status":
1. **Current State Analysis**:
   - Show test results: `pnpm test --reporter=verbose --run`
   - Show coverage analysis: `pnpm test --coverage`
   - Identify failing tests and reasons
   - Suggest next TDD action (Red, Green, or Refactor)
   - Provide progress summary
   - Display Vitest performance metrics

## Test Templates (Following JavaScript Testing Best Practices)

### Basic Function Test Template:
```typescript
import { describe, it, expect } from 'vitest'
import { functionName } from './module'

describe('functionName', () => {
  it('should return formatted output when given valid input', () => {
    // Arrange - Setup test scenario
    const input = 'test input'
    const expectedOutput = 'expected output'
    
    // Act - Execute the unit under test
    const result = functionName(input)
    
    // Assert - Verify expected outcome
    expect(result).toBe(expectedOutput)
  })
})
```

### Edge Cases Template:
```typescript
describe('functionName edge cases', () => {
  it('should return empty array when given empty input', () => {
    const result = functionName([])
    expect(result).toEqual([])
  })
  
  it('should handle null input gracefully', () => {
    const result = functionName(null)
    expect(result).toBeNull()
  })
  
  it('should process special characters correctly', () => {
    const specialInput = 'test@#$%^&*()'
    const result = functionName(specialInput)
    expect(result).toContain(specialInput)
  })
})
```

### Error Handling Test Template:
```typescript
describe('error handling', () => {
  it('should throw validation error when given invalid input', () => {
    expect(() => functionName(null)).toThrow('Invalid input')
  })
  
  it('should reject with specific error when process fails', async () => {
    await expect(asyncFunction()).rejects.toThrow('Process failed')
  })
})
```

### Async Function Test Template:
```typescript
it('should resolve with data when operation succeeds', async () => {
  // Arrange
  const expectedData = { id: 1, name: 'test' }
  
  // Act
  const result = await asyncFunction()
  
  // Assert
  expect(result).toEqual(expectedData)
})
```

## File Management

### Automatic File Creation:
- Source files: `src/[feature].ts`
- Test files: `src/[feature].test.ts` or `src/[feature].spec.ts`
- Follow existing project naming conventions

### Test Organization (Following JavaScript Testing Best Practices):
- **Co-locate tests** with source files for easy navigation
- **Descriptive test file names** that match source files
- **Logical grouping** with nested `describe` blocks:
  - Main functionality in top-level describe
  - Edge cases in dedicated describe block
  - Error handling in separate describe block
- **Consistent test structure** across the codebase
- **Test categories**: Happy path, edge cases, error conditions, integration scenarios

## Integration with Existing Tools

### Vitest Integration:
- Use existing test runner configuration (v3.2.4)
- Leverage watch mode for continuous feedback: `pnpm test --watch`
- Utilize coverage reporting: `pnpm test --coverage`
- Use Vitest UI for enhanced experience: `pnpm test --ui`
- Run specific tests: `pnpm test [pattern]`
- Follow project testing conventions (.spec.ts files)

### VS Code Integration:
- Open test and source files side-by-side
- Use VS Code test explorer if available
- Leverage debugging capabilities
- Integrate with source control

## Success Metrics

- **Test Coverage**: Maintain high test coverage (>80%) - use `pnpm test --coverage`
- **Test Quality**: Tests should be fast, reliable, and maintainable
- **Code Quality**: Clean, readable, and well-structured code
- **Cycle Time**: Quick Red-Green-Refactor cycles (minutes, not hours)
- **Test Performance**: Leverage Vitest's fast test execution (current: 390ms for 5 tests)

## Vitest & pnpm Command Reference

### Essential Commands:
- `pnpm test` - Run all tests
- `pnpm test --watch` - Run tests in watch mode
- `pnpm test --ui` - Open Vitest UI in browser
- `pnpm test --coverage` - Run with coverage report
- `pnpm test [pattern]` - Run specific test files
- `pnpm test --reporter=verbose` - Detailed test output

### TDD-Specific Usage:
- **Red Phase**: `pnpm test [test-file] --watch` to see failing test
- **Green Phase**: `pnpm test [test-file] --watch` to see passing test
- **Refactor Phase**: `pnpm test --watch` to ensure tests stay green
- **Status Check**: `pnpm test --reporter=verbose --run` for full report

### Advanced Features:
- **Parallel Testing**: Vitest runs tests in parallel by default
- **Hot Module Replacement**: Instant test re-runs on file changes
- **TypeScript Support**: Native TypeScript support without compilation
- **Snapshot Testing**: Built-in snapshot testing capabilities

## Common Pitfalls to Avoid (JavaScript Testing Best Practices)

**TDD Process Pitfalls:**
- Writing too much code in Green phase
- Skipping Refactor phase
- Not running tests frequently enough
- Ignoring failing tests
- Over-engineering solutions
- Not leveraging Vitest's watch mode for continuous feedback

**Test Quality Pitfalls:**
- **Vague test names**: Use 3-part naming (what + when + expected)
- **Testing implementation**: Focus on behavior, not internal details
- **Complex test logic**: Keep tests simple and declarative
- **Missing edge cases**: Test empty values, null/undefined, boundaries
- **Broad assertions**: Test one concept per test case
- **Unclear test structure**: Always follow AAA pattern (Arrange, Act, Assert)
- **Poor test organization**: Group related tests in logical describe blocks

## Next Steps Guidance

After each phase, provide specific guidance:
- **After Red**: "Great! Now implement minimal code to make this test pass"
- **After Green**: "Perfect! Now let's refactor to improve code quality"
- **After Refactor**: "Excellent! Ready for the next Red phase or feature"

## JavaScript Testing Best Practices Summary

**Key Principles:**
1. **3-Part Test Names**: What + When + Expected result
2. **AAA Pattern**: Arrange, Act, Assert with clear separation
3. **Black-box Testing**: Test behavior, not implementation
4. **Declarative Style**: Write tests that read like specifications
5. **Edge Case Coverage**: Empty values, boundaries, error conditions
6. **Test Organization**: Group by functionality and test type
7. **Readability First**: Prioritize understanding over cleverness

**Reference**: [goldbergyoni/javascript-testing-best-practices](https://github.com/goldbergyoni/javascript-testing-best-practices)

Remember: TDD is about discipline, small steps, and continuous feedback. Each cycle should be completed in minutes, not hours. Tests should be your "friendly assistant" that provides confidence with minimal complexity.
