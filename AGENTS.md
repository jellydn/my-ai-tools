# 🤖 Agent Instructions

## 🏗️ What This Is

Monorepo for **my-ai-tools** — configuration management for AI coding assistants: Claude Code, OpenCode, Amp, CCS, Gemini CLI, Antigravity CLI, Pi, Codex CLI, Kilo CLI, CommandCode, Cursor, Factory Droid, Cline, Grok CLI.

Exports configurations to `~/.claude/`, `~/.config/opencode/`, `~/.npm-global/`, `~/.factory/`, `~/.pi/`, etc.

**Reference**: [docs website](https://ai-tools.itman.fyi) | [Testing Guide](./TESTING.md)

## 🔧 Essential Commands

```bash
# Shell scripts (root)
bash -n cli.sh generate.sh       # Validate syntax

# Docker/ci would run these:
./cli.sh --dry-run               # Preview install
./cli.sh                        # Install to home
./generate.sh --dry-run          # Preview export
./generate.sh                    # Export changes

# Testing
bash -n cli.sh generate.sh
```

## 👤 Agent Guidelines

### Workflow Order

```bash
./cli.sh --dry-run   → Review changes
git diff            → Verify modifications
./cli.sh            # Install if approved
git diff            # Final check before committing
```

### Test Pattern Checklist

- ✅ Shell scripts pass `bash -n` syntax check
- ✅ Tested with `--dry-run` first
- ✅ No absolute paths in configs
- ✅ Colors/logging functions used consistently
- ✅ Error handling (`set -e` and guard clauses)
- ✅ Documentation updated if workflow changed
- ✅ Git operations follow safety guidelines

## 🎨 Style Patterns

### Shell Scripts

| Pattern           | Convention                                                                                             |
| ----------------- | ------------------------------------------------------------------------------------------------------ |
| Shebang           | `#!/bin/bash`                                                                                          |
| Re-exec guard     | Source `lib/require_bash.sh` before any `lib/common.sh` source (see file for canonical implementation) |
| Error handling    | `set -e` at top (placed _after_ the re-exec guard)                                                     |
| Guard clauses     | Return early on preconditions                                                                          |
| Variable quoting  | Always quote: `"$variable"`                                                                            |
| Paths             | Use `$HOME`, relative - **no absolute paths**                                                          |
| Command execution | Use `execute()` wrapper for dry-run support                                                            |
| Local variables   | Use `local` for function-scoped                                                                        |

### Color Output

```bash
RED='\033[0;31m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; BLUE='\033[0;34m'
NC='\033[0m'

log_info()   { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()  { echo -e "${RED}[ERROR]${NC} $1" >&2; }
```

### JSON Configuration

- Standard formatting (no trailing commas)
- Use `jq` for validation: `jq . settings.json`
- Claude Code: `settings.json`, `mcp-servers.json`
- OpenCode/Amp: `settings.json`
- CCS: `config.yaml`, `delegation-sessions.json`

### YAML Configuration

- 2-space indentation (no tabs)
- CCS: `config.yaml` for main config
- Hooks: YAML-based definition files

## 📂 Directory Structure

```text
cli.sh, generate.sh              # Root scripts
configs/<tool>/                 # Source configs
  claude/                      # Claude Code configs
  opencode/                    # OpenCode configs
  amp/                         # Amp configs
  ccs/                         # CCS configs
  ai-launcher/                 # AI Launcher config
  gemini/
  antigravity-cli/             # Staged from cli.sh migration
  pi/
  codex/                       # Codex configs
  commandcode/
  cursor/
  kilo/
  cline/
  factory/
  orca/
  grok/                        # Grok CLI configs
  copilot/                     # Copilot configs
skills/                         # Local marketplace plugins
```

## 🔑 Key Conventions

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

### Backup (cli.sh only)

- Auto-cleanup keeps last 5 backups
- Location: `$HOME/ai-tools-backup-{timestamp}`
- Interactive prompts in non-dry-run mode

### Prerequisites

- **Required**: Bash 3.0+ — `cli.sh` and `generate.sh` use bash-only syntax (process substitution, arrays, `${var//pat/repl}`). Both entry-point scripts `source` [`lib/require_bash.sh`](./lib/require_bash.sh) as their first non-shebang line; that shim is POSIX-compatible and auto-detects `sh`/`dash` invocation (including macOS where `/bin/sh` IS bash in POSIX mode) and transparently re-launches under `bash`. See [Shell Scripts](#shell-scripts) for the guard pattern.
- **Required**: Git, Bun (preferred over Node.js)
- **Required**: `jq` for JSON parsing
- **Optional**: biome for JS/TS formatting

### Git Guidelines

- Refer to [`configs/git-guidelines.md`](./configs/git-guidelines.md)
- Safe operations: Read, safe commits, branch management
- Avoid: Force push, history rewriting, destructive resets

## 📝 README Sections to Reference

### Bash Scripts

- Root tools: [`cli.sh`](./cli.sh), [`generate.sh`](./generate.sh)

### Platform/Tool Details

When any CLI features prominently, reference:

- Installation commands
- Configuration files (`~/.toolname/`)
- MCP servers (`mcp.json`)
- Custom agents/commands

### Pre-commit Checklist

(Based on patterns above, with Git safety)

## ✅ Pre-commit Checklist

- [ ] Shell scripts pass `bash -n` syntax check
- [ ] Tested with `--dry-run`
- [ ] No absolute paths in configs
- [ ] Colors and logging functions used consistently
- [ ] Error handling with `set -e` and guard clauses
- [ ] Documentation updated if workflow changed
- [ ] Git operations follow safety guidelines
