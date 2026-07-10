# Coding Conventions

**Analysis Date:** 2026-07-10

---

## Language & Stack

This is a **shell-script monorepo** (Bash 3.0+) with supporting JSON/TOML/Markdown configs. No TypeScript, JavaScript, or compiled code. Three shell libraries power everything:

| File                  | Purpose                                                             |
| --------------------- | ------------------------------------------------------------------- |
| `lib/require_bash.sh` | POSIX-compatible re-exec guard — always sourced **first**           |
| `lib/common.sh`       | Shared utilities: logging, dry-run, path helpers, validation, retry |
| `lib/install.sh`      | Tool-specific installers (Claude Code, OpenCode, Codex, etc.)       |

Two entry-point scripts: `cli.sh` (install configs → `$HOME`) and `generate.sh` (export configs ← `$HOME`).

---

## Naming Patterns

### Files

- **Shell scripts**: `kebab-case.sh` or short lowercase (`cli.sh`, `generate.sh`)
- **Config files**: descriptive names: `settings.json`, `mcp-servers.json`, `mcp-registry.json`
- **Markdown docs**: `UPPERCASE.md` for top-level (`AGENTS.md`, `README.md`, `MEMORY.md`, `GEMINI.md`); `kebab-case.md` for guides (`best-practices.md`, `git-guidelines.md`)
- **Skill definitions**: `SKILL.md` (always uppercase filename inside `skills/<skill-name>/`)
- **Agent definitions**: `kebab-case.md` inside tool `agents/` directories
- **Test files**: `tests/<feature>.bats` — `pr_*.bats` for config-gating PRs, descriptive names for `lib_*.bats`, `cli.bats`

### Functions (Bash)

- **Convention**: `snake_case` with semantic prefixes
- **Installers**: `install_<tool>_now()`, `install_<tool>()`, `handle_<feature>_installation_if_needed()`
- **Config copiers**: `copy_<tool>_configs()`, `copy_config_file()`, `copy_config_dir()`, `copy_configurations()`
- **Generators**: `generate_<tool>_configs()`
- **Internal helpers**: prefixed with `_` (`_detect_os()`, `_verify_package_manager()`, `_detect_script_runner()`, `_run_<tool>_install()`)
- **Logging**: `log_info`, `log_success`, `log_warning`, `log_error`
- **Validation**: `validate_config()`, `validate_json()`, `validate_yaml()`, `validate_config_with_schema()`

### Variables

- **Environment/global**: `UPPER_CASE` — `DRY_RUN`, `BACKUP_DIR`, `SCRIPT_DIR`, `YES_TO_ALL`, `VERBOSE`, `IS_WINDOWS`, `TRANSACTION_ACTIVE`
- **Function-local**: `lower_case` with `local` keyword — `local tool_name`, `local src_path`, `local err_file`
- **Private-ish locals**: prefixed `_` — `_filename`, `_uname_s`, `_pids_file`
- **Test exports**: tests re-export these globals to control behavior: `export DRY_RUN=false`, `export YES_TO_ALL=false`

---

## Code Style

### EditorConfig & Biome

```ini
# .editorconfig
[*.{ts,tsx,js,jsx}]    indent_style = tab, quote_type = double
[*.json]                indent_style = tab
[*.sh]                  indent_style = tab
[*.{yaml,yml}]          indent_style = space, indent_size = 2
[*.{md,mdx}]            indent_style = tab, trim_trailing_whitespace = false
[*]                     charset = utf-8, end_of_line = lf, insert_final_newline = true
```

```json
// biome.json
{
	"formatter": { "indentStyle": "tab", "indentWidth": 1, "lineWidth": 120 },
	"javascript": { "formatter": { "quoteStyle": "double" } },
	"json": { "formatter": { "indentStyle": "tab", "indentWidth": 1 } }
}
```

### Shell Script Style

- **Shebang**: `#!/bin/bash` on entry-point scripts; `#!/usr/bin/env bats` on test files
- **Re-exec guard**: Every entry-point script **must** source `lib/require_bash.sh` before `lib/common.sh`. This is non-negotiable — `lib/common.sh` uses bash-only syntax (process substitution, arrays, `${var//pat/repl}`) that crashes under `sh`/`dash`.
- **`set -e`** goes **after** the re-exec guard, not before it
- **Always quote** variables: `"$variable"`, `"$@"`
- **Use `printf`** instead of `echo -e` for portability: `printf '%b\n' "${BLUE}ℹ ${NC}$1" >&2`
- **Use `local`** for all function-scoped variables
- **Avoid bash arrays** in code paths that might be sourced under `dash`; use `set --` and positional params or temp files instead
- **Process substitution** (`<(...)`): prefer temp files + `while read` for POSIX safety in `detect_tool` and similar helpers
- **`[[` vs `[`**: `[[` is bash-only — use it freely in `cli.sh`/`generate.sh`/`lib/` (all guarded by `require_bash.sh`)

### TOML Config Style

- **Identifiers**: `snake_case` with dots for nesting — `[mcp_servers.ctx]`, `command = "ctx"`
- **Tool configs**: `config.toml` files for Codex, Kimi Code, Grok, Conductor, ctx

### JSON Config Style

- **Top-level keys**: `camelCase` — `mcpServers`, `permissions`, `statusLine`
- **`$schema`** references used where available for validation

---

## Import / Source Organization

### Entry-point scripts (`cli.sh`, `generate.sh`)

```
1. #!/bin/bash
2. . "$(dirname "${BASH_SOURCE:-$0}")/lib/require_bash.sh"    ← MUST BE FIRST
3. set -e
4. SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
5. source "$SCRIPT_DIR/lib/common.sh"
6. source "$SCRIPT_DIR/lib/install.sh"                        ← cli.sh only
7. [[ "${BASH_SOURCE[0]}" == "${0}" ]] → parse args + main()
```

### Test files

```bash
#!/usr/bin/env bats
load helpers                    # if sharing skip helpers
source "$BATS_TEST_DIRNAME/../lib/common.sh"
source "$BATS_TEST_DIRNAME/../lib/install.sh"
source "$BATS_TEST_DIRNAME/../cli.sh"
export DRY_RUN=false            # always reset after sourcing
```

---

## Error Handling

### Patterns

1. **Guard clauses** — check preconditions first, return/exit early:
   ```bash
   if [ ! -f "$source_file" ]; then return 1; fi
   if ! command -v jq &>/dev/null; then skip "jq not installed"; fi
   ```

2. **`set -e`** on entry scripts; tests run in subshells via `run` so they don't inherit it

3. **`execute()` / `execute_quoted()`** — all side-effecting commands must use these wrappers (never raw). `execute()` uses `eval` for simple commands; `execute_quoted()` passes `"$@"` directly for path-safe execution

4. **Dry-run** — `DRY_RUN=true` gates all destructive operations. Tested via exported env var

5. **Transaction log** — `start_transaction()`, `record_action()`, `rollback_transaction()`, `end_transaction()` provide rollback via `--rollback` flag

6. **Retry with backoff** — `install_mcp_server()` retries up to 3× with exponential sleep on network errors

7. **Error capture** — `2>"$err_file"` then `grep` for known patterns (`already`, `connection`, `timed?out`)

8. **Non-interactive fallback** — `is_non_interactive()` detects CI/piped stdin; sets `YES_TO_ALL=true` automatically

### Exit codes

- `0` = success
- `1` = error / missing / failed
- Functions return 0 on dry-run or skip, 1 on real failure only

---

## Logging

All logging goes to **stderr** to avoid interfering with command substitution. Defined in `lib/common.sh`:

```bash
log_info()    { printf '%b\n' "${BLUE}ℹ ${NC}$1" >&2; }
log_success() { printf '%b\n' "${GREEN}✓${NC} $1" >&2; }
log_warning() { printf '%b\n' "${YELLOW}⚠${NC} $1" >&2; }
log_error()   { printf '%b\n' "${RED}✗${NC} $1" >&2; }
```

- `log_info` — major operations, detection results, status updates
- `log_success` — completion, successful copies/installs
- `log_warning` — deprecation notices, skipped tools, missing optional deps
- `log_error` — fatal conditions, validation failures, missing prerequisites
- ANSI color codes stripped in test assertions with `sed -E 's/\x1B\[[0-9;]*m//g'`

---

## Function Design

- **Single-purpose**: Most functions do exactly one thing (copy one tool's configs, install one tool)
- **Consistent parameter conventions**: `local var="$1"`, `local var="${1:-default}"`
- **Interactive prompt pattern**: `YES_TO_ALL=true` → auto-accept; `[ -t 0 ]` → `prompt_yn`; else → skip/log
- **`_run_<tool>_install()`** inner functions used with `run_installer()` for consistent prompt/auto/non-interactive behavior
- **Comment header** on every function: `# Usage:` line describing parameters and return value
- **POSIX fallbacks**: When bash arrays would work, use temp files or `set --` for dash compatibility where needed

---

## Guard Clauses (Idioms)

```bash
# Tool detection guard
if [ "$status" = "missing" ]; then
    log_info "Tool not detected - skipping config installation"
    return 0
fi

# Preflight missing tools
if [ ${#missing_tools[@]} -gt 0 ]; then
    log_error "Missing required tools: ${missing_tools[*]}"
    exit 1
fi

# Test prerequisite skip
if ! command -v jq &>/dev/null; then
    skip "jq not installed"
fi

# BASH_SOURCE guard (arg parsing only when executed, not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # parse args, call main
fi
```

---

## Path Handling

- **No absolute paths** in configs or scripts — always use `$HOME`, `$SCRIPT_DIR`, relative paths
- `normalize_path()` — forward slashes, collapse duplicates, preserve URLs/UNC paths
- `expand_path()` — resolve `~` to `$HOME`
- `safe_copy_dir()` — rsync preferred; fallback manual copy excluding `node_modules`, `*.sqlite`, cache dirs
- `make_temp_file()` / `make_temp_dir()` — `${TMPDIR}/prefix-$(date +%s)-$$.ext`

---

## Documentation Conventions

- **`AGENTS.md`**: root-level agent instructions for this repository (CI commands, merge checklist, testing guide)
- **`GEMINI.md`**: same content synced for Gemini CLI compatibility
- **`MEMORY.md`**: persistent compounding knowledge base
- **`CONTRIBUTING.md`**: how to add tools, skills, agents, hooks; style guide
- **`TESTING.md`**: BATS quickstart, CI/non-interactive mode, pre-commit hooks
- **Tool-level docs**: each `configs/<tool>/AGENTS.md` contains tool-specific instructions

---

_Last updated: 2026-07-10_
