# Agents Guide

## Project
my-ai-tools: Configuration management repository for AI coding tools (Claude Code, OpenCode, Amp, CCS) and their integration with MCP servers and plugins.

## Build/Lint/Test Commands

### Shell Script Validation
```bash
bash -n cli.sh              # Syntax check single script
bash -n generate.sh         # Syntax check single script
bash -n cli.sh generate.sh  # Check all scripts
```

### Installation/Export
```bash
./cli.sh --dry-run         # Preview installation (safe)
./cli.sh                   # Run installation
./generate.sh --dry-run    # Preview export (safe)
./generate.sh              # Run export
```

### Manual Testing
- Always use `--dry-run` first to preview changes
- Verify with `git diff` before committing
- Test in non-interactive mode: `echo "y" | ./cli.sh`

## Code Style Guidelines

### Bash Scripts
- **Shebang**: `#!/bin/bash` (POSIX-compliant, not `#!/bin/sh`)
- **Error handling**: Always use `set -e` at script top
- **Guard clauses**: Check preconditions first, return early
  ```bash
  check_prerequisites() {
      if ! command -v git &>/dev/null; then
          log_error "Git is not installed"
          exit 1
      fi
  }
  ```
- **Variable quoting**: Always quote: `"$variable"`, never unquoted
- **No absolute paths**: Use `$HOME` and relative paths for portability
- **Command execution**: Use `execute()` wrapper for dry-run support
- **Local variables**: Use `local` for function-scoped variables

### Color Output & Logging
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

### Error Handling Patterns
- Use `command -v` for prerequisite checks
- Handle cross-device link errors with TMPDIR:
  ```bash
  setup_tmpdir() {
      local tmp_dir="$HOME/.claude/tmp"
      mkdir -p "$tmp_dir" 2>/dev/null || true
      export TMPDIR="$tmp_dir"
  }
  ```
- Use temporary files for error capture:
  ```bash
  local err_file="/tmp/claude-${server_name}.err"
  ```

### JSON Configuration
- Standard JSON formatting (no trailing commas)
- Use `jq` for parsing/validation: `jq . settings.json`
- Claude Code: `settings.json`, `mcp-servers.json`
- OpenCode/Amp: `settings.json`
- CCS: `config.json`, `delegation-sessions.json`

### YAML Configuration
- 2-space indentation (no tabs)
- CCS: `config.yaml` for main configuration
- Hooks: YAML-based hook definitions

### Markdown Documentation
- **Headers**: Use emoji prefixes for visual hierarchy
  - `🚀` for main sections
  - `📋` for lists/guides
  - `🎨` for style/formatting
  - `🔁` for CI/repetition
- **Code blocks**: Include language tags for syntax highlighting
- **File references**: Use `@` syntax (e.g., `@~/.ai-tools/best-practices.md`)

### File Naming
- **Configs**: Lowercase with hyphens: `my-config.json`
- **Commands**: `command-name.md`
- **Agents**: `agent-name.md`
- **Skills**: `skill-name/` (directory with SKILL.md)
- **Best practices**: `best-practices.md`

## Directory Structure
```
cli.sh, generate.sh          # Root shell scripts
configs/<tool>/              # Source configurations
  claude/                    # Claude Code settings, MCP, commands, agents, skills
  opencode/                  # OpenCode agents, commands, skills
  amp/                       # Amp settings, skills
  ccs/                       # CCS configuration, hooks, cliproxy
  ai-launcher/               # AI Launcher config
.claude-plugin/plugins/      # Local skills for distribution
```

## Key Patterns

### Dry-Run Support
All destructive operations support `--dry-run`:
```bash
execute() {
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] $1"
    else
        eval "$1"
    fi
}
```

### Backup Functionality
- Auto-cleanup: keeps last 5 backups
- Location: `$HOME/ai-tools-backup-{timestamp}`
- Prompts in interactive mode

### Prerequisite Checking
- Git (required)
- Bun (preferred) or Node.js (fallback)
- jq (required for JSON parsing)
- biome (optional, for JS/TS formatting)

## Pre-commit Checklist
- [ ] Shell scripts pass `bash -n` syntax check
- [ ] Tested with `--dry-run`
- [ ] No absolute paths in configs
- [ ] Colors and logging functions used consistently
- [ ] Error handling with `set -e` and guard clauses
- [ ] Documentation updated if workflow changed
