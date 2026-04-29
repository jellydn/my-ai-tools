# Coding Conventions

**Analysis Date:** 2026-04-22

## Naming Patterns

**Files:**
- Shell scripts: `kebab-case.sh` (e.g., `cli.sh`, `generate.sh`)
- Config files: `kebab-case.json` or lowercase descriptive (e.g., `settings.json`)
- Markdown docs: `UPPERCASE.md` for main docs, `kebab-case.md` for guides
- Skill definitions: `SKILL.md` (always uppercase)
- Agent definitions: `kebab-case.md` (e.g., `code-reviewer.md`)

**Functions (Bash):**
- Pattern: `snake_case` descriptive names
- Examples: `install_claude_code()`, `backup_configs()`, `copy_claude_subdirectory()`
- Prefixes: `install_*`, `backup_*`, `copy_*`, `log_*` indicate purpose

**Variables:**
- Environment/global: `UPPER_CASE` (e.g., `DRY_RUN`, `BACKUP_DIR`, `SCRIPT_DIR`)
- Local: `lower_case` with `local` keyword (e.g., `local tool_name`, `local src_path`)
- Constants: `UPPER_CASE` with descriptive names

**Types (JSON):**
- Schema files use standard JSON with `$schema` references
- Keys: camelCase for settings (e.g., `"defaultMode"`, `"mcpServers"`)

## Code Style

**Formatting:**
- Tool: `shfmt` for shell script formatting
- Tool: `biome` for TypeScript/JavaScript
- Tool: `prettier` for Markdown
- Tool: `ruff` for Python (if present)
- Indent: 2 spaces for JSON/YAML, tabs for shell scripts (shfmt default)

**Linting:**
- Tool: `shellcheck` for bash scripts (enforced in pre-commit)
- Tool: `biome check` for JS/TS
- Pre-commit: `.pre-commit-config.yaml` runs shellcheck

**Shell Script Style:**
- Shebang: `#!/bin/bash` (not `#!/bin/sh` for POSIX compliance)
- Error handling: `set -e` at script top
- Variable quoting: Always quote variables: `"$variable"`, never unquoted
- Command substitution: `$(command)` preferred over backticks

## Import Organization

**Bash Scripts:**
- Order:
  1. Shebang and `set -e`
  2. `SCRIPT_DIR` definition
  3. Source common library: `source "$SCRIPT_DIR/lib/common.sh"`
  4. Global variable declarations
  5. Function definitions
  6. Main execution (often in a `main()` function or at bottom)

**TypeScript (Hooks):**
- Standard ES6 imports
- No specific grouping enforced

## Error Handling

**Patterns:**
- Guard clauses check preconditions first, return early
  ```bash
  check_prerequisites() {
      if ! command -v git &>/dev/null; then
          log_error "Git is not installed"
          exit 1
      fi
  }
  ```
- `set -e` for automatic exit on error
- `trap` for cleanup on script exit
- Transaction logging with rollback capability (`--rollback` flag)
- Temporary files with cleanup: `make_temp_file()`, `rm -f` after use

**Error Capture:**
- Redirect errors to temp files for analysis: `2>"$err_file"`
- Retry logic with exponential backoff for network operations
- Color-coded error output: `log_error()` outputs to stderr in red

## Logging

**Framework:** Custom color-coded functions in `lib/common.sh`

**Patterns:**
```bash
log_info()   { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()  { echo -e "${RED}[ERROR]${NC} $1" >&2; }
```

**When to Log:**
- `log_info`: Major operations starting
- `log_success`: Operations completed successfully
- `log_warning`: Non-fatal issues or skipped items
- `log_error`: Fatal errors (always to stderr)
- Verbose mode available: `VERBOSE=true` for detailed output

## Comments

**When to Comment:**
- Function purpose at definition
- Complex logic or non-obvious behavior
- Cross-platform workarounds
- Environment-specific handling

**Documentation Style:**
- Markdown for all documentation files
- YAML frontmatter for skills with metadata
- JSDoc not used (project is shell-script focused)

**Example Function Comment:**
```bash
# Install MCP server with retry mechanism and better error handling
# Usage: install_mcp_server "server_name" "install_command"
install_mcp_server() {
    local server_name="$1"
    local install_cmd="$2"
    # ...
}
```

## Function Design

**Size:** Functions should be focused and single-purpose (ideally <50 lines)
- Large functions broken into smaller helpers
- Example: `cli.sh` has 20+ focused functions vs one giant main

**Parameters:**
- Use positional parameters with local variables
- Quote all parameters: `local var="$1"`
- Avoid global variables when possible

**Return Values:**
- Use `return` for exit codes (0 = success, non-zero = failure)
- Use `echo` for string output (captured by caller)
- Use `local var=$(function_call)` pattern for data return

## Module Design

**Exports:**
- Bash has no explicit export keyword - all functions are "exported" when sourced
- `common.sh` is sourced by scripts that need its functions

**Barrel Files:**
- Not applicable (shell scripts)
- Common patterns defined in `lib/common.sh` and sourced as needed

## Guard Clauses

**Pattern:** Check preconditions first, return/exit early
```bash
preflight_check() {
    local missing_tools=()
    local required_tools=("awk" "sed" "basename" "cat" "head" "tail" "grep" "date")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
}
```

## Cross-Platform Compatibility

**OS Detection:**
```bash
IS_WINDOWS=false
_detect_os() {
    case "$OSTYPE" in
    msys* | mingw* | cygwin* | win*) return 0 ;;
    esac
    if [ -n "$MSYSTEM" ]; then
        case "$MSYSTEM" in
        MINGW* | MSYS* | CLANG*) return 0 ;;
        esac
    fi
    return 1
}
```

**Path Handling:**
- No absolute paths - use `$HOME` and relative paths
- `normalize_path()` function for Windows/Unix compatibility
- `convert_path()` for Windows/Unix path conversion
- Handle `TMPDIR` cross-device link issues

---

*Convention analysis: 2026-04-22*
