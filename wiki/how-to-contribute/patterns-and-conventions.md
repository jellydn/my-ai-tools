# Patterns and Conventions

Coding patterns and conventions used in this repository.

## Shell Scripts

### Shebang and Error Handling

```bash
#!/bin/bash
set -e
```

Always use `#!/bin/bash` (POSIX-compliant) and enable `set -e` for error handling.

### Guard Clauses

Check preconditions first and return early:

```bash
check_prerequisites() {
    if ! command -v git &>/dev/null; then
        log_error "Git is not installed"
        exit 1
    fi
}
```

### Variable Handling

- Always quote variables: `"$variable"`, never unquoted
- Use `local` for function-scoped variables
- Use `$HOME` and relative paths (no absolute paths)

### Color Output

```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()   { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()  { echo -e "${RED}[ERROR]${NC} $1" >&2; }
```

### Dry-Run Support

```bash
execute() {
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] $1"
    else
        eval "$1"
    fi
}
```

## Configuration Files

### JSON

- Standard JSON formatting (no trailing commas)
- Use `jq` for parsing/validation
- Claude Code: `settings.json`, `mcp-servers.json`
- OpenCode/Amp: `opencode.json`, `settings.json`

### YAML

- 2-space indentation (no tabs)
- CCS: `config.yaml` for main configuration

### File Naming

- Configs: lowercase with hyphens: `my-config.json`
- Commands: `command-name.md`
- Agents: `agent-name.md`
- Skills: `skill-name/` (directory with SKILL.md)

## Directory Structure

```
cli.sh, generate.sh          # Root shell scripts
configs/<tool>/              # Source configurations
  claude/                    # Claude Code settings, MCP, commands, agents, skills
  opencode/                  # OpenCode agents, commands, skills
  amp/                       # Amp settings, skills
  ccs/                       # CCS configuration, hooks, cliproxy
skills/                      # Local skills for distribution
```

## Git Practices

See [configs/git-guidelines.md](../../configs/git-guidelines.md) for:
- Allowed operations (read, safe commits, branch management)
- Operations to avoid (force push, history rewriting)
- Best practices (pager, version compatibility, commit hygiene)
