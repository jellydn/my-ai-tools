# Agents Guide

## Project
my-ai-tools: Configuration management repository for AI coding tools (Claude Code, OpenCode, Amp, CCS) and their integration with MCP servers and plugins.

## Build/Run Commands

### Installation Commands
- `./cli.sh` - Install and configure AI tools to home directory
- `./cli.sh --dry-run` - Preview changes without applying them
- `./cli.sh --backup` - Backup existing configs before installation
- `./cli.sh --no-backup` - Skip backup prompt during installation

### Export Commands
- `./generate.sh` - Export current home configs back to repository
- `./generate.sh --dry-run` - Preview export without making changes

### Prerequisites
- Git (required for version control)
- Bun (preferred) or Node.js (for npm scripts)
- jq (required for JSON parsing)
- biome (optional, for JS/TS formatting)

## Code Style Guidelines

### Bash Scripts
- **Shebang**: Use `#!/bin/bash` (POSIX-compliant, not `#!/bin/sh`)
- **Error handling**: Always use `set -e` at script top
- **Color output**: Use predefined variables for consistency:
  ```bash
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'  # No Color
  ```
- **Logging functions**: Use `log_info`, `log_success`, `log_warning`, `log_error`
- **Variable quoting**: Always quote variables: `"$variable"`, never unquoted
- **No absolute paths**: Use `$HOME` and relative paths for portability
- **Command execution**: Use `execute()` wrapper for dry-run support

### JSON Configuration
- Standard JSON formatting (no trailing commas)
- **Claude Code**: `settings.json`, `mcp-servers.json`
- **OpenCode**: `opencode.json`
- **Amp**: `settings.json`
- **CCS**: `config.json`, `delegation-sessions.json`

### YAML Configuration
- Standard YAML formatting (2-space indentation)
- **CCS**: `config.yaml` for main configuration
- **Hooks**: YAML-based hook definitions

### Markdown Documentation
- **Headers**: Use emoji prefixes for visual hierarchy
  - `🚀` for main sections
  - `📋` for lists/guides
  - `🎨` for style/formatting
- **Code blocks**: Copy-paste ready, include language tags
- **File references**: Use `@` syntax for cross-references (e.g., `@~/.ai-tools/best-practices.md`)

### File Naming Conventions
- **Configs**: Lowercase with hyphens: `my-config.json`
- **Commands**: `command-name.md`
- **Agents**: `agent-name.md`
- **Skills**: `skill-name/` (directory with SKILL.md inside)
- **Best practices**: `best-practices.md`

### Error Handling
- Use guard clauses for preconditions, return early:
  ```bash
  check_prerequisites() {
      if ! command -v git &>/dev/null; then
          log_error "Git is not installed"
          exit 1
      fi
  }
  ```
- Use `command -v` for prerequisite checks
- Handle cross-device link errors with TMPDIR setup:
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

### Directory Structure
- **Shell Scripts**: `cli.sh`, `generate.sh` at root
- **Configs**: `configs/<tool>/` structure
  - `claude/` - Claude Code settings, MCP servers, commands, agents, skills
  - `opencode/` - OpenCode agents, commands, skills
  - `amp/` - Amp settings, skills
  - `ccs/` - CCS configuration, hooks, cliproxy
  - `ai-switcher/` - AI switcher configuration
- **Best practices**: `configs/best-practices.md`
- **Knowledge**: `MEMORY.md` for agent context

## Architecture

### Shell Scripts
- **cli.sh**: Main installation orchestration script
- **generate.sh**: Export home configs back to repository
- Both support `--dry-run` for safe previewing

### Config Management
- Source configs stored in `configs/<tool>/`
- Deployed to `$HOME/.claude/`, `$HOME/.config/opencode/`, `$HOME/.config/amp/`, `$HOME/.ccs/`
- Sensitive files excluded from export (e.g., settings.json with API keys)

### MCP Server Integration
- Installed via `claude mcp add --scope user` for global availability
- Common servers: context7, sequential-thinking, qmd
- Installed on-demand via npx

### Plugin System
- Official plugins from `anthropics/claude-plugins-official`
- Community plugins from custom marketplaces
- Local skills from `.claude-plugin/plugins/`

## Key Patterns

### Dry-Run Support
All destructive operations support `--dry-run` flag:
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
- Automatic backup to `$HOME/ai-tools-backup-{timestamp}`
- Prompts user in interactive mode
- Can be forced with `--backup` or skipped with `--no-backup`

### Prerequisite Checking
- Git (required)
- Bun (preferred) or Node.js (fallback)
- jq (for JSON parsing)
- biome (optional, for formatting)

### Plugin Installation Flow
1. Check if CLI tool is installed
2. Add marketplace repo
3. Clear stale cache
4. Install plugin
5. Provide restart instructions

## Testing Guidelines

### Manual Testing
- Always use `--dry-run` first to preview changes
- Verify changes with `git diff` before committing
- Test in non-interactive mode with CI environments

### No Test Framework
This repository has no automated tests. All verification is manual:
- Run `./cli.sh --dry-run` to preview installation
- Run `./generate.sh --dry-run` to preview export
- Review generated files before committing

### Pre-commit Checklist
- [ ] Tested with `--dry-run`
- [ ] No absolute paths in configs
- [ ] Colors and logging functions used consistently
- [ ] Error handling with `set -e` and guard clauses
- [ ] Documentation updated if workflow changed
