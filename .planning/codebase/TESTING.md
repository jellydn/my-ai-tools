# Testing

**Analysis Date:** 2026-07-10

---

## Framework

| Aspect | Detail |
|--------|--------|
| **Framework** | [bats-core](https://github.com/bats-core/bats-core) — Bash Automated Testing System |
| **Install** | `brew install bats-core` (macOS), `apt-get install bats` (Linux) |
| **Test runner** | `bats tests/` (all), `bats tests/cli.bats` (single file) |
| **CI** | `.github/workflows/test.yml` — runs `bash -n` + `bats tests/` + `biome check .` |

---

## Test Structure

### Directory Layout

```
tests/
├── helpers.bash          # Shared test helpers (loaded via `load helpers`)
├── cli.bats              # Core CLI workflow tests
├── lib_common.bats       # Library unit tests (lib/common.sh)
├── generate.bats         # Generate script tests
├── install.bats          # Installation tests
├── sh_reexec.bats        # Shell re-exec guard tests
├── pr_*.bats             # Per-tool config-gating PR tests (16 files)
└── recommend_skills.bats # Skill recommendation tests (47 tests — largest)
```

### Test Counts

| File | Tests |
|------|-------|
| `recommend_skills.bats` | 47 |
| `pr_ctx.bats` | 31 |
| `pr_cline.bats` | 29 |
| `pr_kiro.bats` | 25 |
| `pr_claude.bats` | 20 |
| `pr_grok.bats` | 19 |
| `pr_kimi_code.bats` | 17 |
| `pr_copilot.bats` | 15 |
| `cli.bats` | 15 |
| Others | 5–14 each |

Total: ~280 tests across 23 files.

---

## Test Patterns

### Setup Pattern

Every test file follows this setup:

```bash
#!/usr/bin/env bats

setup() {
    # Source libraries
    source "$BATS_TEST_DIRNAME/../lib/common.sh"
    source "$BATS_TEST_DIRNAME/../lib/install.sh"
    source "$BATS_TEST_DIRNAME/../cli.sh"

    # Export control variables (always reset after sourcing)
    export DRY_RUN=false
    export YES_TO_ALL=false
    export SCRIPT_DIR="$BATS_TEST_DIRNAME/.."
}
```

### Test Naming

- Descriptive names: `@test "should detect claude code CLI when installed"`
- Pattern: `should <expected behavior> when <condition>`
- No generic names like `test1` or `works`

### Assertion Patterns

```bash
# Exit code assertions
run some_function
[ "$status" -eq 0 ]

# Output assertions
[ "${lines[0]}" = "Expected output" ]

# Regex assertions
[[ "$output" =~ "expected pattern" ]]

# Multi-line assertions
[ "${#lines[@]}" -eq 3 ]
[ "${lines[1]}" = "line two" ]
```

### Tool-Specific Test Patterns

PR tests (`pr_*.bats`) test config installation end-to-end:

```bash
# Create temp home with pre-existing tool config dirs
H=$(mktemp -d)
mkdir -p "$H/.claude" "$H/.config/opencode"

# Source scripts against the temp home, call copy functions
( export HOME="$H" DRY_RUN=false YES_TO_ALL=false
  source ./cli.sh
  copy_claude_configs )

# Assert files landed correctly
[ -f "$H/.claude/settings.json" ]
```

---

## Test Helpers (`tests/helpers.bash`)

| Helper | Purpose |
|--------|---------|
| `skip_if_missing` | Skip test if a required tool is not installed |
| Shared setup | Common environment variable exports |

---

## CI Testing

### GitHub Actions (`test.yml`)

```yaml
# Runs on push and PR
# Steps:
# 1. Checkout
# 2. Setup bun
# 3. bash -n cli.sh generate.sh lib/*.sh   # Syntax validation
# 4. bats tests/                            # Functional tests
# 5. biome check .                          # Code formatting
```

### Pre-commit Hooks

```yaml
# .pre-commit-config.yaml
- trailing-whitespace    # Remove trailing whitespace
- end-of-file-fixer      # Ensure files end with newline
- check-yaml             # Validate YAML syntax
- check-added-large-files # Prevent large file commits
- oxfmt                  # Format TypeScript/JavaScript
```

---

## Test Culture

- **All new features should have tests** — CONTRIBUTING.md: "Test changes with `./cli.sh --dry-run` first"
- **Tests reset global state**: `export DRY_RUN=false` after every `source`
- **Tests use temp directories**: Never mutate the real `$HOME`
- **Color output stripped in assertions**: `sed -E 's/\x1B\[[0-9;]*m//g'`
- **Tests run in isolation**: Each `@test` block is a subshell

---

## Testing the App Safely

Never run `./cli.sh` directly during development — use temp homes:

```bash
H=$(mktemp -d)
mkdir -p "$H/.claude" "$H/.config/opencode" "$H/.codex"
( export HOME="$H" DRY_RUN=false YES_TO_ALL=false
  source ./cli.sh
  copy_configurations )
find "$H" -type f   # verify configs landed
```

Or use `./cli.sh --dry-run` for a side-effect-free preview.

---

## microsandbox Testing

For macOS users, bats tests can fail due to `getcwd` restrictions. Use microsandbox:

```bash
msb run -m 512M -v "$(pwd):/project:ro" ubuntu -- \
  bash -c 'apt-get update -qq && apt-get install -y -qq bats && cd /project && bats tests/'
```

The `:ro` mount keeps the project read-only inside the sandbox, preventing accidental writes.

_Last updated: 2026-07-10_
