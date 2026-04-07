# Coding Conventions

**Analysis Date:** 2026-04-07

## Shell Script Conventions

### Style Guidelines (from AGENTS.md)

**Shebang:**
```bash
#!/bin/bash  # POSIX-compliant, NOT #!/bin/sh
```

**Error Handling:**
```bash
set -e  # Always at script top

# Guard clauses - check preconditions first
if ! command -v git &>/dev/null; then
    log_error "Git is not installed"
    exit 1
fi
```

**Variable Quoting:**
```bash
# Always quote variables
"$variable"

# Never unquoted
# WRONG: $variable
```

**Local Variables:**
```bash
my_function() {
    local var_name="value"  # Use local for function scope
}
```

**No Absolute Paths:**
```bash
# Use $HOME and relative paths
"$HOME/.claude/settings.json"
# NOT /Users/name/.claude/settings.json
```

**Command Execution:**
```bash
# Use execute() wrapper for dry-run support
execute() {
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] $1"
    else
        eval "$1"
    fi
}
```

### Logging Pattern

```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

log_info()   { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()  { echo -e "${RED}[ERROR]${NC} $1" >&2; }
```

## JSON Configuration Conventions

### Formatting
- Standard JSON formatting (no trailing commas)
- Use `jq` for parsing/validation: `jq . settings.json`
- 2-space indentation

### Structure Patterns

**Claude Code:**
```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": ["mcp__mempalace__mempalace_status"]
  },
  "hooks": {
    "Stop": [{"matcher": "", "hooks": []}]
  }
}
```

**MCP Server Pattern:**
```json
{
  "mcpServers": {
    "mempalace": {
      "command": "python3",
      "args": ["-m", "mempalace.mcp_server"]
    }
  }
}
```

## YAML Conventions

- 2-space indentation (no tabs)
- CCS: `config.yaml` for main configuration

## TOML Conventions

- Codex: `[mcp_servers.mempalace]` for MCP sections
- snake_case for keys

## Error Handling Patterns

### Cross-Device Link Errors
```bash
setup_tmpdir() {
    local tmp_dir="$HOME/.claude/tmp"
    mkdir -p "$tmp_dir" 2>/dev/null || true
    export TMPDIR="$tmp_dir"
}
```

### Temporary Files
```bash
local err_file="/tmp/claude-${server_name}.err"
```

### Prerequisite Checking
```bash
if ! command -v jq &>/dev/null; then
    log_error "jq is required but not installed"
    exit 1
fi
```

## Documentation Conventions

### Markdown Headers
- `🚀` for main sections
- `📋` for lists/guides
- `🎨` for style/formatting
- `🔁` for CI/repetition

### Code Blocks
- Include language tags: ```bash, ```json, ```toml

### File References
- Use `@` syntax: `@~/.ai-tools/best-practices.md`

## File Naming

- **Configs**: Lowercase with hyphens: `my-config.json`
- **Commands**: `command-name.md`
- **Agents**: `agent-name.md`
- **Skills**: `skill-name/` (directory with SKILL.md)

## Pre-commit Patterns

From `.pre-commit-config.yaml`:
- `trailing-whitespace` - Remove trailing spaces
- `end-of-file-fixer` - Ensure newline at EOF
- `check-yaml` - Validate YAML syntax
- `check-added-large-files` - Prevent large file commits

## MCP Tool Naming

- Pattern: `mcp__<server>__<tool>`
- Example: `mcp__mempalace__mempalace_status`
- Permissions use full tool names

---

*Conventions analysis: 2026-04-07*
