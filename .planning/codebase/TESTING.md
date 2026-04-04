# Testing Guide

This document outlines the testing framework, structure, and patterns used in this codebase.

## Table of Contents

- [Testing Framework](#testing-framework)
- [Shell Script Testing](#shell-script-testing)
- [TypeScript Testing](#typescript-testing)
- [Test Organization](#test-organization)
- [Running Tests](#running-tests)
- [Best Practices](#best-practices)

---

## Testing Framework

### Shell Scripts: Bats

The project uses [Bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System) for shell script testing.

- Source: `https://github.com/bats-core/bats-core`
- Installation: `brew install bats-core` or via package manager

### TypeScript: Bun Test

TypeScript tests use Bun's built-in test runner for projects in the hooks directory.

---

## Shell Script Testing

### Test File Structure

```bash
#!/usr/bin/env bats

setup() {
    # Load dependencies and setup test environment
    load "$SCRIPT_DIR/lib/common.sh"
    export DRY_RUN=false
}

teardown() {
    # Cleanup after each test
    rm -rf "$HOME/.claude.test.$$"
}

@test "test description" {
    # Test implementation
    run some_function
    [ "$status" -eq 0 ]
}
```

### Test Conventions

1. **Shebang**: `#!/usr/bin/env bats`
2. **Setup/Teardown**: Use `setup()` and `teardown()` functions
3. **Test naming**: Use `kebab-case` with descriptive names
4. **Assertions**: Use Bats built-in assertions

### Common Test Patterns

**Testing function existence:**
```bash
@test "function exists" {
    type some_function &>/dev/null
    [ "$status" -eq 0 ]
}
```

**Testing dry-run mode:**
```bash
@test "execute respects dry-run mode" {
    export DRY_RUN=true
    run execute "rm -rf /tmp/test"
    [ "$status" -eq 0 ]
    [[ "$output" == "[DRY RUN]"* ]]
}
```

**Testing error conditions:**
```bash
@test "validate_json returns 1 for invalid JSON" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    echo '{invalid json}' > /tmp/test_invalid.json
    run validate_json /tmp/test_invalid.json
    [ "$status" -eq 1 ]
    rm -f /tmp/test_invalid.json
}
```

**Testing output formatting:**
```bash
@test "log_info outputs with blue color prefix" {
    run log_info "test message"
    [ "$status" -eq 0 ]
    [[ "$output" == "ℹ"* ]]
}
```

### Special Variables

- `$BATS_TEST_DIRNAME`: Directory containing the test file
- `$BATS_TEST_DESCRIPTION`: Current test name
- `$output`: Captured stdout from last command
- `$status`: Exit status of last command

### Skipping Tests

Use `skip` for conditional test execution:
```bash
if ! command -v jq &>/dev/null; then
    skip "jq not installed"
fi
```

---

## TypeScript Testing

### Test Structure

Tests follow standard Bun test patterns:
```typescript
import { describe, it, expect } from 'bun:test'

describe('module', () => {
  it('should return expected output', () => {
    const result = someFunction(input)
    expect(result).toBe(expected)
  })
})
```

### Running TypeScript Tests

```bash
bun test
```

---

## Test Organization

### Directory Structure

```
tests/
├── cli.bats           # Tests for cli.sh
├── install.bats       # Tests for install.sh
└── lib_common.bats    # Tests for lib/common.sh
```

### Test Grouping

Tests are grouped by the script/module they test:
- `lib_common.bats` → Tests for shared utilities
- `cli.bats` → Tests for main CLI commands

---

## Running Tests

### Shell Script Syntax Validation

```bash
# Check single script
bash -n cli.sh

# Check multiple scripts
bash -n cli.sh generate.sh

# Full check
bash -n cli.sh generate.sh install.sh && echo "All scripts valid"
```

Exit codes:
- `0` - Syntax is valid
- `1` - Syntax error found

### Bats Tests

```bash
# Run all tests
bats tests/

# Run specific test file
bats tests/cli.bats

# Run specific test
bats tests/cli.bats --filter-tag "backup"
```

### CI/Non-Interactive Mode

For automated validation, use syntax checking:
```bash
bash -n cli.sh generate.sh && echo "All scripts valid"
```

---

## Best Practices

### Test Coverage

1. **Happy path tests**: Verify basic functionality
2. **Error handling tests**: Test failure conditions
3. **Edge cases**: Test boundary conditions (empty input, special characters)
4. **Dry-run tests**: Verify preview mode doesn't execute

### Test Isolation

- Each test should be independent
- Use `teardown()` to clean up resources
- Avoid shared state between tests
- Use temporary files with unique suffixes (`$$` for process ID)

### Assertion Patterns

```bash
# Exit code
[ "$status" -eq 0 ]

# Output contains string
[[ "$output" == *"expected"* ]]

# Output matches pattern
[[ "$output" == [DRY RUN]* ]]

# Boolean conditions
[ -f "$filepath" ]
[ -d "$dirpath" ]
[ -n "$variable" ]
```

### Debugging Failed Tests

1. Print debug info with `echo` or `log_info`
2. Check `$output` for captured output
3. Check `$status` for exit codes
4. Verify setup/teardown cleanup

### Continuous Integration

Add to CI pipeline:
```yaml
- name: Lint Shell Scripts
  run: bash -n cli.sh generate.sh

- name: Run Bats Tests
  run: bats tests/
```

---

## Example: Full Test File

```bash
#!/usr/bin/env bats
# Test suite for lib/common.sh utilities

setup() {
    load "$SCRIPT_DIR/lib/common.sh"
    export DRY_RUN=false
}

teardown() {
    rm -f /tmp/test_*.json
}

@test "execute logs in dry-run mode" {
    export DRY_RUN=true
    run execute "echo test"
    [ "$status" -eq 0 ]
    [[ "$output" == "[DRY RUN]"* ]]
}

@test "execute runs command in normal mode" {
    export DRY_RUN=false
    run execute "echo hello"
    [ "$status" -eq 0 ]
    [ "$output" == "hello" ]
}

@test "validate_json returns 0 for valid JSON" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    echo '{"key": "value"}' > /tmp/test_valid.json
    run validate_json /tmp/test_valid.json
    [ "$status" -eq 0 ]
}
```
