# Testing Patterns

**Analysis Date:** 2026-07-04

---

## Test Framework

### Runner

- **Bats** (Bash Automated Testing System) — `bats-core` via Homebrew (`brew install bats-core`) or apt (`sudo apt-get install bats`)
- No config file needed; test files use `*.bats` extension
- TAP-compliant output

### Assertions

- Bats built-ins only: `[ condition ]`, `[[ expression ]]`, `run <command>`, `@test "name" { ... }`
- No external assertion library
- `$status` — exit code of last `run` command
- `$output` — combined stdout+stderr of last `run`
- ANSI color codes stripped in assertions: `sed -E 's/\x1B\[[0-9;]*m//g'`

### Run Commands

```bash
bats tests/                      # all tests
bats tests/lib_common.bats       # single file
bats tests/pr_*.bats             # glob pattern (config-gating PR tests)
bats -t tests/cli.bats           # TAP format (no pretty output)

# CI (GitHub Actions)
bats tests/pr_*.bats tests/generate.bats tests/sh_reexec.bats

# In microsandbox (avoid macOS getcwd issues)
msb run -m 512M -v "$(pwd):/project:ro" ubuntu -- \
  bash -c 'apt-get update -qq && apt-get install -y -qq bats jq && cd /project && bats tests/'

# Syntax validation only (no bats install needed)
bash -n cli.sh generate.sh lib/install.sh
```

---

## Test File Organization

```
tests/
├── helpers.bash                # Shared helper: require_jq(), REPO_ROOT
├── cli.bats                    # CLI arg parsing, BASH_SOURCE guard, main() sourcing
├── generate.bats               # copy_single(), execute_quoted(), DRY_RUN, path-with-spaces
├── install.bats                # install.sh self-containment checks
├── lib_common.bats             # execute, validate_json, validate_yaml, logging, path helpers
├── sh_reexec.bats              # lib/require_bash.sh guard — sh invocation → bash re-exec
├── recommend_skills.bats       # recommend-skills.json schema + README.md consistency
├── pr_antigravity.bats         # Antigravity CLI settings.json gating
├── pr_claude.bats              # Claude Code settings.json hook definitions
├── pr_cline.bats               # Cline configs gating
├── pr_codiff.bats              # Codiff scaffolding gating
├── pr_copilot.bats             # Copilot MCP config gating
├── pr_ctx.bats                 # ctx tool scaffolding + MCP registration gating
├── pr_grok.bats                # Grok CLI configs gating
├── pr_kimi_code.bats           # Kimi Code CLI configs gating
├── pr_kiro.bats                # Kiro CLI configs gating
├── pr_pi_models.bats           # Pi models config gating
├── pr_pi_settings.bats         # Pi settings config gating
├── pr_pre_commit.bats          # .pre-commit-config.yaml structure gating
├── pr_qodercli.bats            # Qoder CLI configs gating
├── pr_readme.bats              # README.md documentation consistency
├── cursor_configs.bats         # Cursor configs validation
└── pr_ai_launcher.bats         # AI launcher configs gating
```

### Naming Conventions

- `pr_<feature>.bats` — "pull-request gating" tests that enforce config consistency when adding/removing tools
- `<library>.bats` — unit/integration tests for a specific source file
- `helpers.bash` — shared test utilities loaded via `load helpers`
- Test names: descriptive English with spaces:
  ```bash
  @test "backup_configs creates backup directory"
  @test "configs/claude/settings.json StopFailure hook command references orca agent-hooks"
  ```

---

## Test Structure

### Anatomy

```bash
#!/usr/bin/env bats

load helpers                                    # optional

REPO_ROOT="$BATS_TEST_DIRNAME/.."               # repo root for config file paths

setup() {                                       # runs before each test
    source "$REPO_ROOT/lib/common.sh"
    source "$REPO_ROOT/lib/install.sh"
    source "$REPO_ROOT/cli.sh"
    export DRY_RUN=false
    export YES_TO_ALL=false
}

teardown() {                                    # optional cleanup
    rm -rf "$HOME"
    rm -rf "$_TEMP_SCRIPT_DIR"
    export HOME="$ORIG_HOME"
}

@test "descriptive name stating expected behavior" {
    # Arrange
    export DRY_RUN=true

    # Act
    run execute_quoted echo "hello world"

    # Assert
    [ "$status" -eq 0 ]
    local clean_output
    clean_output="$(printf '%s' "$output" | sed -E 's/\x1B\[[0-9;]*m//g')"
    [[ "$clean_output" == *"[DRY RUN]"* ]]
}
```

### Key Patterns

| Pattern                                        | Purpose                                     |
| ---------------------------------------------- | ------------------------------------------- |
| `run <command>`                                | Execute and capture `$status` + `$output`   |
| `[ "$status" -eq 0 ]`                          | Assert success exit                         |
| `[ "$status" -eq 1 ]`                          | Assert failure exit                         |
| `[ "$status" -eq 0 ] \|\| [ "$status" -eq 1 ]` | Accept either outcome                       |
| `[[ "$output" == *"substring"* ]]`             | Assert output contains text                 |
| `[ -f "$file" ]`                               | Assert file existence                       |
| `[ -n "$output" ]`                             | Assert non-empty output                     |
| `grep -E 'pattern' "$file"`                    | Grep-based content assertion                |
| `skip "reason"`                                | Conditionally skip test                     |
| `export DRY_RUN=true`                          | Put script in dry-run mode for safe testing |

---

## Mocking Strategy

**No mocking framework.** Instead:

1. **Environment variable injection** — `DRY_RUN`, `YES_TO_ALL`, `VERBOSE`, `BACKUP`, `PROMPT_BACKUP`, `SCRIPT_DIR`, `HOME`
2. **PATH manipulation** — remove tools from PATH to simulate "not installed":
   ```bash
   ORIGINAL_PATH="$PATH"
   PATH=$(echo "$PATH" | tr ':' '\n' | grep -v '/jq' | tr '\n' ':')
   run preflight_check
   PATH="$ORIGINAL_PATH"
   ```
3. **Temp HOME directories** — isolate file system side effects:
   ```bash
   ORIG_HOME="$HOME"
   HOME="$(mktemp -d)"
   # ... test ...
   rm -rf "$HOME"
   HOME="$ORIG_HOME"
   ```
4. **Temp SCRIPT_DIR** — `SCRIPT_DIR="$(mktemp -d)"` with `_TEMP_SCRIPT_DIR` sentinel for teardown (prevents `rm -rf` of actual repo)
5. **Stub binaries** — fake scripts in temp directories:
   ```bash
   cat > "$fake_bin_dir/python3" <<'EOF'
   #!/bin/sh
   exit 1
   EOF
   chmod +x "$fake_bin_dir/python3"
   ```

### What NOT to Mock

- Core shell built-ins (`echo`, `test`, `printf`, `[`)
- The functions under test themselves
- `jq` for JSON-based config tests (skip if missing instead)

---

## Test Types

### Unit Tests (`lib_common.bats`, `generate.bats`)

- **Scope**: individual functions in `lib/common.sh`, `generate.sh`
- **Functions tested**: `execute()`, `execute_quoted()`, `log_info/success/warning/error`, `validate_json`, `validate_yaml`, `validate_config_with_schema`, `normalize_path`, `get_temp_dir`, `detect_tool`, `cleanup_old_backups`, `run_parallel`, `copy_single`
- **Approach**: source the library, set up temp files, call function, assert

### Config Gating Tests (`pr_*.bats`)

- **Scope**: config file existence, JSON/TOML validity, specific key values, MCP server registration consistency across all tool configs
- **Examples**:
  - `pr_codiff.bats` — verifies `install_codiff()` exists in `lib/install.sh`, `copy_codiff_configs()` exists in `cli.sh`, `generate_codiff_configs()` exists in `generate.sh`, `configs/codiff/codiff.jsonc` has expected keys, `.changeset/` has codiff entry, README mentions Codiff
  - `pr_ctx.bats` — verifies ctx MCP server registered in **every** tool's MCP config (claude, cursor, cline, factory, kimi-code, commandcode, kiro, copilot, qodercli, pi, antigravity, opencode, kilo, codex, grok)
  - `pr_antigravity.bats` — verifies specific `settings.json` values (model, permissions.allow/deny)
- **Approach**: `jq` queries against config files, `grep` against source files, structural assertions

### README Consistency Tests (`pr_readme.bats`, `recommend_skills.bats`)

- **Scope**: README.md sections match actual config structure, recommend-skills.json matches README install commands
- **Approach**: grep for expected strings in README, jq queries against JSON

### Re-exec Guard Tests (`sh_reexec.bats`)

- **Scope**: verify `lib/require_bash.sh` correctly re-execs under bash when invoked via `sh`
- **Approach**: run `sh generate.sh --dry-run`, assert output contains expected banner (proves bash took over)

### Installation Script Tests (`install.bats`)

- **Scope**: verify `install.sh` is self-contained (has inlined logging, does NOT source `lib/common.sh`)
- **Approach**: grep for function definitions, absence of source statements, `bash -n` syntax check

---

## Fixtures & Cleanup

- **No fixture directory** — test data created inline and cleaned up
- `$$` (PID) used for unique names: `/tmp/test-backup-$$`, `/tmp/my-ai-tools-detect-tool.json`
- `mktemp -d` for temp directories
- Cleanup: always `rm -rf` / `rm -f` in test body or `teardown()`
- **Critical**: `generate.bats` uses `_TEMP_SCRIPT_DIR` sentinel because `generate.sh` overrides `SCRIPT_DIR` to repo root — teardown must NOT use `$SCRIPT_DIR` or it will delete the repository

---

## Coverage

- No formal coverage tool or target
- Focus on: dry-run path (all destructive ops gated), JSON/TOML config validity, cross-tool MCP consistency, sourcing guards, function existence for new tool scaffolding
- Coverage baseline: every `pr_*.bats` file gates one tool's complete scaffolding

---

## CI/CD

### GitHub Actions (`.github/workflows/test.yml`)

```yaml
name: Tests
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
jobs:
  bats:
    name: Config Validation Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - run: sudo apt-get update && sudo apt-get install -y bats jq
      - run: bats tests/pr_*.bats tests/generate.bats tests/sh_reexec.bats
```

### Pre-commit Hooks (`.pre-commit-config.yaml`)

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v6.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
  - repo: https://github.com/oxc-project/mirrors-oxfmt
    rev: v0.51.0
    hooks:
      - id: oxfmt
```

### Local Quality Gates

```bash
bash -n cli.sh generate.sh         # syntax validation
biome check .                       # TS/JS/JSON formatting
pre-commit run --all-files          # trailing whitespace, YAML check, oxfmt
bats tests/                         # functional tests
```

---

## Writing New Tests (Checklist)

1. **New tool scaffolding** → create `tests/pr_<tool>.bats` with:
   - Config file existence (`[ -f "$REPO_ROOT/configs/<tool>/settings.json" ]`)
   - `install_<tool>()` defined in `lib/install.sh`
   - `copy_<tool>_configs()` defined in `cli.sh` + called from `copy_configurations()`
   - `generate_<tool>_configs()` defined in `generate.sh` + called from `main()`
   - `cli.sh` banner advertises tool
   - `cli.sh backup_configs()` includes tool's config dir
   - `README.md` mentions tool
   - `.changeset/` has entry
2. **MCP server addition** → verify registration in every tool's MCP config
3. **Config value change** → add explicit jq assertions for the new value
4. **README sync** → verify README install command + table row match
5. **Pre-commit** → verify `.pre-commit-config.yaml` structure

---

_Last updated: 2026-07-04_
