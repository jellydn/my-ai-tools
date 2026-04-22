# Testing Patterns

**Analysis Date:** 2026-04-22

## Test Framework

**Runner:**
- **Bats** (Bash Automated Testing System) - TAP-compliant testing for Bash
- Version: Latest available via npm/brew
- Config: No config file, test files use `*.bats` extension

**Assertion Library:**
- Bats built-in assertions: `[`, `[[`, `run`, `@test`
- No external assertion library used

**Run Commands:**
```bash
# Run all tests
bats tests/

# Run specific test file
bats tests/cli.bats

# Run with verbose output
bats -t tests/lib_common.bats
```

## Test File Organization

**Location:**
- Pattern: `tests/<feature>.bats` - co-located in `tests/` directory
- Separate from source but parallel naming (e.g., `lib_common.bats` tests `lib/common.sh`)

**Naming:**
- Files: `*.bats` extension
- Test names: Descriptive with spaces (e.g., `@test "backup_configs creates backup directory"`)

**Structure:**
```
tests/
├── cli.bats              # CLI script tests (60 lines)
├── install.bats          # Installer tests (40 lines)
└── lib_common.bats       # Common library tests (150+ lines)
```

## Test Structure

**Suite Organization:**
```bash
#!/usr/bin/env bats

# Optional: setup function runs before each test
setup() {
    load "$SCRIPT_DIR/lib/common.sh"
    export DRY_RUN=false
    export SCRIPT_DIR
}

@test "description of what this test verifies" {
    # Arrange
    export DRY_RUN=true

    # Act
    run execute "rm -rf /tmp/nonexistent-test-file-$$"

    # Assert
    [ "$status" -eq 0 ]
    [[ "$output" == "[DRY RUN]"* ]]
}
```

**Patterns:**
- `setup()` - Run before each test (optional)
- `run` - Execute command and capture output/status
- `$status` - Exit code of last `run` command
- `$output` - Stdout/stderr of last `run` command
- `[ condition ]` - Standard test assertion

## Mocking

**Framework:** None - manual mocking via environment variables and temporary files

**Patterns:**
```bash
# Mock by manipulating PATH
@test "preflight_check fails on missing jq" {
    # Save original PATH
    ORIGINAL_PATH="$PATH"

    # Temporarily remove jq from PATH
    PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '/jq' | tr '\n' ':')

    run preflight_check

    # Restore PATH
    PATH="$ORIGINAL_PATH"

    # Either jq is installed (test passes) or we get an error
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}
```

**What to Mock:**
- External tool availability (via PATH manipulation)
- Environment variables (DRY_RUN, BACKUP, etc.)
- File system state (temp directories, test files)

**What NOT to Mock:**
- Core shell built-ins (echo, test, etc.)
- The functions under test themselves

## Fixtures and Factories

**Test Data:**
- Inline creation in tests (no separate fixtures directory)
- Example:
```bash
mkdir -p "$HOME/.claude.test.$$"
echo '{"test": true}' > "$HOME/.claude.test.$$/settings.json"
```

**Cleanup:**
- Always cleanup in setup/teardown or at end of test
- Use `$$` (PID) for unique temp identifiers
- Remove files and directories explicitly

**Location:**
- No dedicated fixtures directory
- Test data created inline and cleaned up

## Coverage

**Requirements:**
- No formal coverage target enforced
- Focus on critical paths: backup, dry-run, validation

**View Coverage:**
```bash
# Run all tests to verify functionality
bats tests/
```

## Test Types

**Unit Tests:**
- Scope: Individual functions in `lib/common.sh`
- Examples: `execute()`, `preflight_check()`, `backup_configs()`
- Approach: Mock dependencies, verify behavior

**Integration Tests:**
- Scope: CLI behavior and file operations
- Examples: `cli.bats` tests installation flow
- Approach: Test with DRY_RUN=true to avoid side effects

**E2E Tests:**
- Not implemented - would require full AI tool installations

## Common Patterns

**Dry-Run Testing:**
```bash
@test "execute respects dry-run mode for dangerous commands" {
    export DRY_RUN=true

    run execute "rm -rf /tmp/nonexistent-test-file-$$"
    [ "$status" -eq 0 ]
    [[ "$output" == "[DRY RUN]"* ]]
}
```

**Function Existence Testing:**
```bash
@test "install_mcp_server handles installation result" {
    export DRY_RUN=true

    # Test that the function exists
    type install_mcp_server &>/dev/null

    [ "$status" -eq 0 ]
}
```

**Error Testing:**
```bash
# Test that function handles errors gracefully
run install_claude_code 2>&1 || true
[ "$status" -eq 0 ] || [ "$status" -eq 1 ]
```

## Pre-commit Testing

**Hooks:**
- `.pre-commit-config.yaml` runs shellcheck on all `.sh` files
- Example:
```yaml
repos:
  - repo: local
    hooks:
      - id: shellcheck
        name: shellcheck
        entry: shellcheck
        language: system
        types: [shell]
        args: [-e, SC1091]  # Exclude source warning
```

## CI/CD Testing

**GitHub Actions:**
- Tests run on pull requests and pushes
- Validates shell script syntax and functionality

---

*Testing analysis: 2026-04-22*
