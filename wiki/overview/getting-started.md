# Getting Started

This guide covers prerequisites, installation, and basic usage of my-ai-tools.

## Prerequisites

### All Platforms

- **Bun or Node.js LTS** — Runtime for scripts
- **Git** — Version control
- **Python 3.9+** — Required for MemPalace AI memory system
  ```bash
  pip install mempalace
  ```

### Windows-Specific

- **Git for Windows** — Includes Git Bash
- **PowerShell 5.1+** — For PowerShell installer
- **jq** — Auto-installed via winget if available

## Installation

### Option 1: One-Line Installer (Recommended)

```bash
curl -fsSL https://ai-tools.itman.fyi/install.sh | bash
```

**Options:**
```bash
# Preview changes without making them
curl -fsSL https://ai-tools.itman.fyi/install.sh | bash -s -- --dry-run

# Backup existing configs before installing
curl -fsSL https://ai-tools.itman.fyi/install.sh | bash -s -- --backup

# Skip backup prompt
curl -fsSL https://ai-tools.itman.fyi/install.sh | bash -s -- --no-backup
```

### Option 2: Manual Installation

```bash
git clone https://github.com/jellydn/my-ai-tools.git
cd my-ai-tools
./cli.sh
```

### Option 3: Windows PowerShell

```powershell
irm https://ai-tools.itman.fyi/install.ps1 | iex
```

## Basic Usage

### Install Configurations

```bash
# Preview changes
./cli.sh --dry-run

# Execute installation
./cli.sh
```

### Export Current Configurations

```bash
# Preview changes
./generate.sh --dry-run

# Execute export
./generate.sh
```

## Configuration Files

After installation, configs are placed in:

| Tool | Location |
|------|----------|
| Claude Code | `~/.claude/` |
| OpenCode | `~/.config/opencode/` |
| Amp | `~/.config/amp/` |
| CCS | `~/.ccs/` |
| Gemini CLI | `~/.gemini/` |
| Codex CLI | `~/.codex/` |

## Verifying Installation

1. Check that config files were created in your home directory
2. Test the CLI by running `claude` or your preferred AI tool
3. Verify MCP servers are registered: `claude mcp list`
