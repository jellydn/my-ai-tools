# Testing

**Analysis Date:** 2026-04-07

## Test Framework

**Primary: BATS (Bash Automated Testing System)**
- Test files: `tests/*.bats`
- Location: `/Users/huynhdung/src/tries/2026-04-07-jellydn-my-ai-tools-pr179/tests/`
- Framework: https://github.com/bats-core/bats-core

## Test Structure

### Test Files

| File | Purpose | Test Count |
|------|---------|------------|
| `tests/cli.bats` | CLI script functions | ~6 tests |
| `tests/lib_common.bats` | Library utilities | ~20 tests |
| `tests/install.bats` | Installation functions | ~4 tests |

### Test Organization

```
tests/
├── cli.bats          # Main CLI tests
├── lib_common.bats   # Common library tests
└── install.bats      # Installation tests
```

## Test Patterns

### Setup Pattern
```bash
setup() {
    source "$BATS_TEST_DIRNAME/../lib/common.sh"
    export DRY_RUN=false
}
```

### Basic Test Structure
```bash
@test "test description" {
    # Arrange
    export DRY_RUN=true

    # Act
    run execute "echo test"

    # Assert
    [ "$status" -eq 0 ]
    [[ "$output" == *"[DRY RUN]"* ]]
}
```

### Conditional Skipping
```bash
@test "validate_json returns 0 for valid JSON" {
    if ! command -v jq &>/dev/null; then
        skip "jq not installed"
    fi
    # ... test code
}
```

## Key Test Areas

### Dry-Run Mode Testing
- Tests verify `[DRY RUN]` appears in output
- Commands don't actually execute
- Safe for CI/testing environments

```bash
@test "execute respects dry-run mode" {
    export DRY_RUN=true
    run execute "rm -rf /tmp/test-file"
    [ "$status" -eq 0 ]
    [[ "$output" == *"[DRY RUN]"* ]]
}
```

### JSON Validation Testing
- Valid JSON returns 0
- Invalid JSON returns 1
- Requires jq to be installed

```bash
@test "validate_json returns 0 for valid JSON" {
    echo '{"key": "value"}' > /tmp/test.json
    run validate_json /tmp/test.json
    [ "$status" -eq 0 ]
}
```

### Backup Functionality Testing
- Tests cleanup_old_backups with dry-run
- Verifies backup retention logic

### Function Existence Testing
- Many tests verify functions exist: `type function_name &>/dev/null`
- Ensures API compatibility

## Running Tests

### Manual Testing
```bash
# Install bats if needed
npm install -g bats

# Run all tests
bats tests/

# Run specific test file
bats tests/cli.bats

# Run with verbose output
bats --verbose-run tests/
```

### Syntax Validation (Common Practice)
```bash
# Check shell script syntax
bash -n cli.sh
bash -n generate.sh
bash -n install.sh

# Check all scripts
bash -n cli.sh generate.sh install.sh lib/common.sh
```

### JSON Validation
```bash
# Validate all JSON configs
for f in configs/*/*.json; do
    jq . "$f" > /dev/null && echo "✓ $f" || echo "✗ $f"
done
```

## Test Coverage Areas

### Covered
- ✅ Dry-run mode behavior
- ✅ JSON validation (via jq)
- ✅ Function existence
- ✅ Backup operations (dry-run)
- ✅ Color output stripping

### Not Covered (Manual Testing)
- ⚠️ Actual MCP server installation (requires network)
- ⚠️ Git operations (requires repo state)
- ⚠️ File copying (modifies user home)
- ⚠️ Tool detection (depends on installed tools)

## Pre-commit Hooks (Related)

From `.pre-commit-config.yaml`:
```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
```

These provide static analysis similar to tests.

## CI/CD Testing

Tests run in GitHub Actions (`.github/workflows/`):
- Shell script validation
- JSON/TOML/YAML syntax checking
- Pre-commit hook validation

## Test Gaps & Recommendations

### Current Gaps
1. No integration tests for actual MCP server registration
2. No tests for tool detection logic
3. No cross-platform testing (macOS/Linux/Windows)
4. No schema validation tests for tool configs

### Recommended Additions
1. Mock-based MCP server tests
2. Schema validation tests using jsonschema
3. GitHub Actions matrix for OS testing
4. Dry-run integration tests

---

*Testing analysis: 2026-04-07*
