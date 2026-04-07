# MemPalace Auto-Save Hooks

Auto-save memories across all AI tools. Two patterns:

1. **Native Hooks** — tools with built-in lifecycle hooks (Claude Code, Gemini CLI, Codex CLI, Factory)
2. **Polling Mode** — tools without hooks use periodic background saves (Amp, OpenCode, Pi, Kilo, CCS)

---

## Native Hooks (Recommended)

### Claude Code

Claude Code has the richest hook system. Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/mempal_save_hook.sh"
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/mempal_precompact_hook.sh"
          }
        ]
      }
    ]
  }
}
```

**Available hooks:**
- `Stop` — Session end, periodic checkpoint
- `PreCompact` — Before context compression
- `PreToolUse` — Before any tool execution
- `PostToolUse` — After tool execution
- `UserPromptSubmit` — When user sends message
- `PostToolUseFailure` — On tool errors

### Gemini CLI

Gemini supports agent lifecycle hooks. Add to `~/.gemini/settings.json`:

```json
{
  "hooks": {
    "BeforeTool": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.gemini/hooks/mempal_checkpoint.sh"
          }
        ]
      }
    ],
    "AfterTool": [
      {
        "matcher": "mempalace_*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.gemini/hooks/mempal_after_tool.sh"
          }
        ]
      }
    ]
  }
}
```

**Available hooks:**
- `BeforeAgent` — Before agent starts processing
- `AfterAgent` — After agent completes
- `BeforeTool` — Before tool execution
- `AfterTool` — After tool execution (filter by tool name)

### Codex CLI

Codex CLI supports hooks via `~/.codex/hooks.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.codex/hooks/mempal_session_start.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.codex/hooks/mempal_stop.sh"
          }
        ]
      }
    ]
  }
}
```

**Available hooks:**
- `SessionStart` — When a new Codex session starts
- `Stop` — When a Codex session ends

### Factory Droid

Factory imports Claude Code hooks. Add to `~/.factory/settings.json`:

```json
{
  "importedClaudeHooks": true,
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.factory/hooks/mempal_save_hook.sh"
          }
        ]
      }
    ]
  }
}
```

**Note:** Factory reuses Claude's hook scripts with adjusted paths.

---

## Polling Mode (Fallback)

For tools without native hooks, use background polling.

### Amp, OpenCode, Pi, Kilo, CCS

These tools don't expose lifecycle hooks. Use the polling daemon:

```bash
# Start background mempalace poller
mempalace poller --interval 5m --checkpoint-on-change
```

Or add to your shell profile for automatic start:

```bash
# ~/.bashrc or ~/.zshrc
if command -v mempalace &>/dev/null; then
    mempalace poller --daemon --interval 5m &
fi
```

**Polling options:**
- `--interval 5m` — Check every 5 minutes
- `--checkpoint-on-change` — Save when git state changes
- `--on-session-end` — Save when terminal session ends
- `--daemon` — Run in background

### Tool-Specific Polling Setup

#### Amp

Amp doesn't persist hooks. Use the MCP server with auto-save:

```json
{
  "mcp": {
    "mempalace": {
      "type": "local",
      "command": ["python3", "-m", "mempalace.mcp_server", "--auto-save", "5m"],
      "enabled": true
    }
  }
}
```

#### OpenCode

OpenCode has limited hook support. Use the pre-command hook in `~/.config/opencode/opencode.json`:

```json
{
  "hooks": {
    "pre_command": "python3 -c 'import mempalace; mempalace.quick_checkpoint(\"opencode_cmd\")'"
  }
}
```

#### Pi

Pi doesn't expose hooks. Use the polling daemon approach above or use the generic `mempauto_compact.sh` script.

#### Kilo

Kilo has no hook system. Use polling or the shell wrapper pattern.

#### CCS

CCS is a Claude proxy. Use the same hooks as Claude Code in `~/.ccs/config.yaml`:

```yaml
hooks:
  import_from: ~/.claude/settings.json
  enabled: [Stop, PreCompact]
```

---

## Hook Scripts

### Save Hook (`mempal_save_hook.sh`)

**Triggers:** Every 15 messages (configurable)

**Actions:**
- Saves structured checkpoint with context
  - Working directory
  - Git branch
  - Recent file changes
- Regenerates critical facts layer
- Stores session metadata

**What gets saved:**
- Topics discussed
- Decisions made
- Key quotes
- Code changes

### PreCompact Hook (`mempal_precompact_hook.sh`)

**Triggers:** Before context compression

**Actions:**
- Emergency save of critical state
- Flags memories as high priority
- Quick facts layer update
- Prevents data loss during compression

### Gemini Checkpoint Hook (`mempal_checkpoint.sh`)

**For Gemini CLI specifically:**

```bash
#!/bin/bash
# Quick checkpoint for Gemini BeforeTool/AfterTool hooks

python3 -c "
import mempalace
import os
mempalace.quick_checkpoint(
    source='gemini',
    context={'dir': os.getcwd(), 'tool': os.getenv('GEMINI_CURRENT_TOOL', 'unknown')}
)
" 2>/dev/null || true
```

---

## Installation

### 1. Native Hook Tools (Claude, Gemini, Codex, Factory)

```bash
# Copy hooks to tool directory
cp configs/claude/hooks/mempal_*.sh ~/.claude/hooks/
cp configs/gemini/hooks/mempal_*.sh ~/.gemini/hooks/
cp configs/codex/hooks/mempal_*.sh ~/.codex/hooks/
cp configs/factory/hooks/mempal_*.sh ~/.factory/hooks/

chmod +x ~/.claude/hooks/mempal_*.sh
chmod +x ~/.gemini/hooks/mempal_*.sh
chmod +x ~/.codex/hooks/mempal_*.sh
chmod +x ~/.factory/hooks/mempal_*.sh

# Copy hooks.json for Codex
cp configs/codex/hooks.json ~/.codex/

### 2. Polling Mode Tools (Amp, OpenCode, Pi, Kilo, CCS)

```bash
# Start polling daemon
mempalace poller --daemon --interval 5m

# Or add to shell profile for auto-start
echo 'mempalace poller --daemon --interval 5m &' >> ~/.bashrc
```

### 3. Verify Installation

```bash
# Test native hooks
~/.claude/hooks/mempal_save_hook.sh

# Test polling
mempalace status

# Check mempalace is installed
pip3 install mempalace
```

---

## Generic Auto-Compact Script

For tools without native PreCompact support, use the generic auto-compact script:

### `mempauto_compact.sh`

Located at `configs/mempalace/hooks/mempauto_compact.sh`, this script provides:
- Periodic checkpoint for polling-mode tools
- Command wrapper integration
- Signal handling for manual triggers

### Usage

**Manual trigger:**
```bash
bash ~/.mempalace/hooks/mempauto_compact.sh "pre_command"
```

**Command wrapper (for Pi, Kilo):**
```bash
# ~/.bashrc
pi() {
    bash ~/.mempalace/hooks/mempauto_compact.sh "pre"
    command pi "$@"
    bash ~/.mempalace/hooks/mempauto_compact.sh "post"
}
```

**Cron/scheduled task:**
```bash
# Auto-compact every 5 minutes
*/5 * * * * bash ~/.mempalace/hooks/mempauto_compact.sh "scheduled"
```

**Signal trigger:**
```bash
# Send SIGUSR1 to trigger auto-compact
kill -USR1 $(pgrep -f mempauto_compact) 2>/dev/null || true
```

### Environment Variables

- `MEMPALACE_DIR` - Override default `~/.mempalace`
- `MEMPALACE_LOG_LEVEL` - Set to `debug` for verbose output
- `AI_SESSION_ID` - Session identifier for context tracking

---

## Customization

### Adjust Save Frequency

**Native hooks:**
```bash
# Edit THRESHOLD in the hook script
THRESHOLD=15  # Claude Stop hook
```

**Polling:**
```bash
# Use --interval flag
mempalace poller --interval 10m  # 10 minutes
mempalace poller --interval 100  # 100 messages (for supported tools)
```

### Add Custom Memory Types

Extend any hook script:

```python
python3 -c "
import mempalace
mempalace.save_custom(
    category='deployment',
    content='Deployed to production',
    priority='high'
)
" 2>/dev/null || true
```

### Silent Operation

All hooks are designed to fail silently — they won't interrupt your workflow.

---

## Integration with Specialist Agents

Route saves to appropriate agent diaries:

```python
# In save hook - route to specialist agents
import mempalace
import os

current_dir = os.getcwd()
if "/security" in current_dir or "auth" in current_dir:
    mempalace.diary_write("security", "checkpoint", f"dir:{current_dir}")
elif "/docs" in current_dir:
    mempalace.diary_write("docs", "checkpoint", f"dir:{current_dir}")
else:
    mempalace.diary_write("reviewer", "checkpoint", f"dir:{current_dir}")
```

---

## Troubleshooting

### Hooks Not Firing

1. Check hook paths in settings file
2. Verify scripts are executable: `chmod +x ~/.*/hooks/mempal_*.sh`
3. Test manually: `~/.claude/hooks/mempal_save_hook.sh`
4. Check tool's hook system is enabled

### Polling Not Working

1. Verify mempalace daemon is running: `ps aux | grep mempalace`
2. Check interval setting: `mempalace config get poller.interval`
3. Restart daemon: `mempalace poller restart`

### Mempalace Not Found

```bash
# Install mempalace
pip3 install mempalace

# Verify installation
python3 -c "import mempalace; print('OK')"
```

### Tool-Specific Issues

**Claude Code:** Check `~/.claude/settings.json` syntax with `jq .`

**Gemini CLI:** Verify hook path with `gemini config validate`

**Factory:** Ensure `importedClaudeHooks: true` is set

**Polling tools:** Check daemon logs at `~/.mempalace/logs/poller.log`

---

## Summary Table

| Tool | Hook Type | Auto-Compact | Setup File | Hook Triggers |
|------|-------------|--------------|------------|---------------|
| Claude Code | Native | ✅ PreCompact | `~/.claude/settings.json` | Stop, PreCompact, PreToolUse, PostToolUse |
| Gemini CLI | Native | ✅ BeforeTool | `~/.gemini/settings.json` | BeforeAgent, AfterAgent, BeforeTool, AfterTool |
| Factory | Imported | ✅ Stop | `~/.factory/settings.json` | Stop, PreToolUse, PostToolUse (from Claude) |
| CCS | Imported | ✅ PreCompact | `~/.ccs/config.yaml` | Stop, PreCompact (from Claude) |
| Amp | Polling | ⚠️ Manual | `~/.amp/settings.json` | Use `mempauto_compact.sh` wrapper |
| Codex | Native | ✅ SessionStart/Stop | `~/.codex/hooks.json` | Session lifecycle hooks |
| OpenCode | Limited | ⚠️ Manual | `~/.config/opencode/opencode.json` | Use polling or wrapper |
| Pi | Polling | ⚠️ Manual | Shell wrapper | Pre/post command with `mempauto_compact.sh` |
| Kilo | Polling | ⚠️ Manual | Shell wrapper | Pre/post command with `mempauto_compact.sh` |
