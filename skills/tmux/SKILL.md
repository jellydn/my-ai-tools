---
name: tmux
description: "Remote control tmux sessions for interactive CLIs (python, node, gdb, etc.) by sending keystrokes and capturing pane output."
license: MIT
compatibility: opencode, claude, amp, codex, gemini, cursor, pi
hint: Use when you need to control tmux sessions programmatically for interactive terminal applications like REPLs, debuggers, or databases
user-invocable: true
metadata:
  audience: all
  workflow: terminal-automation
---

# 🚀 tmux Skill

Control tmux sessions programmatically to run interactive terminal applications (REPLs, debuggers, databases) without blocking.

---

## 📋 Quickstart (Easy Way)

Use [LogPilot](https://github.com/jellydn/logpilot) for automatic output capture + AI analysis:

```bash
# Install LogPilot
cargo install logpilot

# Watch your tmux session
logpilot watch mysession --pane mysession:0.0

# Ask AI about what's happening
logpilot ask "What errors appeared?"
logpilot summarize --last 5m
```

Add to Claude Code: `claude mcp add --scope user logpilot -- logpilot mcp-server`

---

## 📋 Manual Control (Raw tmux)

Use isolated sockets to avoid conflicts with personal tmux:

```bash
# Setup socket
export SOCKET="${TMPDIR:-/tmp}/ai-tmux-sockets/agent.sock"
mkdir -p "$(dirname "$SOCKET")"

# Create session and run
SESSION=agent-py
tmux -S "$SOCKET" new -d -s "$SESSION"
tmux -S "$SOCKET" send-keys -t "$SESSION" 'python3 -q' Enter

# Capture output manually
tmux -S "$SOCKET" capture-pane -p -J -t "$SESSION" -S -100

# Cleanup
tmux -S "$SOCKET" kill-session -t "$SESSION"
```

### 📋 Core Commands

| Action | Command |
|--------|---------|
| New session | `tmux -S "$SOCKET" new -d -s NAME` |
| Send keys | `tmux -S "$SOCKET" send-keys -t NAME 'cmd' Enter` |
| Send literal | `tmux -S "$SOCKET" send-keys -t NAME -l 'text'` |
| Capture output | `tmux -S "$SOCKET" capture-pane -p -J -t NAME -S -N` |
| List sessions | `tmux -S "$SOCKET" list-sessions` |
| Kill session | `tmux -S "$SOCKET" kill-session -t NAME` |

**Control keys**: `C-c` (SIGINT), `C-d` (EOF), `C-z` (suspend), `Escape`

---

## 📋 Interactive Recipes

### 🔁 Python REPL

```bash
SESSION=agent-py
SOCKET="${TMPDIR:-/tmp}/ai-tmux-sockets/agent.sock"
tmux -S "$SOCKET" new -d -s "$SESSION"
tmux -S "$SOCKET" send-keys -t "$SESSION" 'PYTHON_BASIC_REPL=1 python3 -q' Enter
sleep 1
tmux -S "$SOCKET" send-keys -t "$SESSION" -l 'print(2+2)'
tmux -S "$SOCKET" send-keys -t "$SESSION" Enter
tmux -S "$SOCKET" capture-pane -p -J -t "$SESSION" -S -10
tmux -S "$SOCKET" kill-session -t "$SESSION"
```

### 🔁 GDB Debugger

```bash
SESSION=agent-gdb
SOCKET="${TMPDIR:-/tmp}/ai-tmux-sockets/agent.sock"
tmux -S "$SOCKET" new -d -s "$SESSION"
tmux -S "$SOCKET" send-keys -t "$SESSION" 'gdb --quiet ./program' Enter
tmux -S "$SOCKET" send-keys -t "$SESSION" 'set pagination off' Enter
tmux -S "$SOCKET" send-keys -t "$SESSION" 'run' Enter
# ... later ...
tmux -S "$SOCKET" send-keys -t "$SESSION" C-c
tmux -S "$SOCKET" send-keys -t "$SESSION" 'bt' Enter
tmux -S "$SOCKET" send-keys -t "$SESSION" 'quit' Enter 'y' Enter
```

### Node.js / psql / etc.

Same pattern: `new` → `send-keys` → `capture-pane` → `kill-session`

---

## 📋 LogPilot Reference

| Task | Command |
|------|---------|
| Watch session | `logpilot watch SESSION` |
| Watch pane | `logpilot watch SESSION --pane TARGET` |
| AI summary | `logpilot summarize --last 10m` |
| Ask question | `logpilot ask "Why is it failing?"` |
| With logs | `logpilot ask "Explain" --include-logs` |
| Status | `logpilot status` |

### MCP Setup

```json
{
  "mcpServers": {
    "logpilot": {
      "command": "logpilot",
      "args": ["mcp-server"]
    }
  }
}
```

Or: `claude mcp add --scope user --transport stdio logpilot -- logpilot mcp-server`

---

## 🎨 Best Practices

1. **Use LogPilot** — easiest way to capture and analyze output
2. **Always use `-S "$SOCKET"`** — prevents conflicts with user tmux
3. **Use `-l` flag** — literal text, no shell expansion issues
4. **`PYTHON_BASIC_REPL=1`** — required for interactive Python
5. **Kill sessions when done** — prevents resource leaks
