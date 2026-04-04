# Codebase Conventions

This document outlines the coding conventions, patterns, and best practices used in this codebase.

## Table of Contents

- [Shell Scripts](#shell-scripts)
- [TypeScript/JavaScript](#typescriptjavascript)
- [JSON Configuration](#json-configuration)
- [YAML Configuration](#yaml-configuration)
- [File Naming](#file-naming)
- [Skills](#skills)
- [Hooks](#hooks)

---

## Shell Scripts

### Shebang and Error Handling

```bash
#!/bin/bash
set -e
```

- Use `#!/bin/bash` (POSIX-compliant, not `#!/bin/sh`)
- Always use `set -e` at the top of scripts
- Source dependencies: `source "$SCRIPT_DIR/lib/common.sh"`

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
- Use `$HOME` and relative paths for portability (no absolute paths like `/Users/username/`)
- Use `local` for function-scoped variables:
  ```bash
  local tmp_dir="$HOME/.claude/tmp"
  ```

### Command Execution

Use the `execute()` wrapper for dry-run support:

```bash
execute() {
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] $1"
    else
        eval "$1"
    fi
}
```

### Color Output and Logging

```bash
# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

log_info()   { echo -e "${BLUE}[INFO]${NC} $1" >&2; }
log_success() { echo -e "${GREEN}[OK]${NC} $1" >&2; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
log_error()  { echo -e "${RED}[ERROR]${NC} $1" >&2; }
```

Use emoji prefixes:
- `ℹ` for info
- `✓` for success
- `⚠` for warning
- `✗` for error

### Error Handling Patterns

**Prerequisite checking:**
```bash
if ! command -v jq &>/dev/null; then
    log_error "jq is required"
    exit 1
fi
```

**TMPDIR for cross-device link errors:**
```bash
setup_tmpdir() {
    local tmp_dir="$HOME/.claude/tmp"
    mkdir -p "$tmp_dir" 2>/dev/null || true
    export TMPDIR="$tmp_dir"
}
```

**Temporary files for error capture:**
```bash
local err_file="/tmp/claude-${server_name}.err"
```

**Transaction/rollback support:**
```bash
TRANSACTION_LOG="/tmp/ai-tools-transaction-$$.log"

record_action() {
    local action_type="$1"
    local target="$2"
    local backup_cmd="$3"
    local restore_cmd="$4"
    echo "$action_type|$target|$backup_cmd|$restore_cmd" >> "$TRANSACTION_LOG"
}
```

### Argument Parsing

```bash
for arg in "$@"; do
    case $arg in
    --dry-run)
        DRY_RUN=true
        shift
        ;;
    --backup)
        BACKUP=true
        shift
        ;;
    *)
        echo "Unknown option: $arg"
        exit 1
        ;;
    esac
done
```

---

## TypeScript/JavaScript

### Runtime and Shebang

Use Bun as the runtime:
```typescript
#!/usr/bin/env bun
```

### TypeScript Conventions

- Use TypeScript interfaces for type safety
- Prefer explicit type annotations for function parameters and return types
- Group related types into separate exports

```typescript
export interface TranscriptMessage {
  type: 'summary' | 'user' | 'assistant'
  uuid: string
  timestamp: string
}

export type PreToolUseHandler = (payload: PreToolUsePayload) => Promise<PreToolUseResponse>
```

### Imports

```typescript
import {mkdir, readFile, writeFile} from 'node:fs/promises'
import * as path from 'node:path'
import type {HookPayload} from './lib'
```

- Use `node:` prefix for Node.js built-ins
- Use `type` keyword for type-only imports

### Export Patterns

```typescript
// Named exports for utilities
export function log(...args: unknown[]): void {
  console.log(`[${new Date().toISOString()}]`, ...args)
}

// Default exports for main entry points
export default function runHook(handlers: HookHandlers): void { ... }
```

### Error Handling

```typescript
try {
  const data = await readFile(filepath, 'utf-8')
} catch {
  // File doesn't exist yet
}
```

- Use empty catch blocks only when intentionally ignoring errors
- Prefer specific error handling when needed

---

## JSON Configuration

### Formatting

- Standard JSON formatting (no trailing commas)
- Use `jq` for parsing and validation
- Include schema references where applicable:
  ```json
  {
    "$schema": "https://json.schemastore.org/claude-code-settings.json"
  }
  ```

### Validation

```bash
validate_json() {
    _validate_with_tool "$1" "command -v jq" "jq empty '$filepath'" "JSON"
}
```

---

## YAML Configuration

### Formatting

- 2-space indentation (no tabs)
- Use snake_case for keys

---

## File Naming

| Type | Convention | Example |
|------|------------|---------|
| Configs | lowercase with hyphens | `my-config.json` |
| Commands | `command-name.md` | `extract-pr-comments.md` |
| Agents | `agent-name.md` | `review-agent.md` |
| Skills | `skill-name/` (directory with SKILL.md) | `qmd-knowledge/SKILL.md` |

---

## Skills

### Directory Structure

```
skill-name/
├── SKILL.md           # Main skill definition
├── scripts/           # Helper scripts
│   └── main.sh
├── templates/         # Template files
│   └── template.md
└── references/        # Reference docs
    └── README.md
```

### SKILL.md Frontmatter

```markdown
---
name: tdd
description: Guides through the complete TDD workflow
license: MIT
compatibility: claude, opencode, amp, codex, gemini, cursor
hint: Use when doing test-driven development
user-invocable: true
metadata:
  audience: all
  workflow: testing
---

# Skill Documentation
```

### Required Frontmatter Fields

- `name`: Skill identifier (lowercase, hyphens)
- `description`: Brief description of what the skill does
- `compatibility`: List of compatible tools
- `license`: License identifier (e.g., MIT)
- `hint`: When to invoke this skill
- `user-invocable`: Whether users can invoke directly

---

## Hooks

### Hook Types

- `PreToolUse`: Before a tool is executed
- `PostToolUse`: After a tool executes
- `UserPromptSubmit`: Before user prompt is submitted
- `Stop`: When a session stops
- `SessionStart`: When a session starts
- `Notification`: For notifications
- `PreCompact`: Before compaction

### Hook Definition (settings.json)

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | xargs biome check --write"
          }
        ]
      }
    ]
  }
}
```

### Hook Implementation

```typescript
// In index.ts
const preToolUse: PreToolUseHandler = async (payload) => {
  if (payload.tool_name !== "Bash") {
    return {}
  }

  const command = String(payload.tool_input.command)

  if (command.includes("rm -rf /")) {
    return {
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: "Dangerous command detected",
      },
    }
  }

  return {}
}
```
