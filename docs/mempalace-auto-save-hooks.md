# MemPalace Auto-Save Hooks for Claude Code

Two hooks for Claude Code that automatically save memories during work:

1. **Save Hook** — every 15 messages, triggers a structured save
2. **PreCompact Hook** — fires before context compression

## Hook Configuration

Add to your Claude Code `settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/mempal_save_hook.sh"
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
            "command": "~/.claude/hooks/mempal_precompact_hook.sh"
          }
        ]
      }
    ]
  }
}
```

## Hook Details

### Save Hook (`mempal_save_hook.sh`)

**Triggers:** Every 15 messages (configurable threshold)

**Actions:**
- Saves structured checkpoint with context
  - Working directory
  - Git branch
  - Recent file changes
- Regenerates critical facts layer
- Stores session metadata for retrieval

**What gets saved:**
- Topics discussed
- Decisions made
- Key quotes
- Code changes

### PreCompact Hook (`mempal_precompact_hook.sh`)

**Triggers:** Before context compression / when window is about to shrink

**Actions:**
- Emergency save of critical state
- Flags memories as high priority for persistence
- Quick facts layer update with recent context only
- Prevents data loss during compression

**Why it matters:**
Context compression can drop valuable information. This hook ensures critical memories are preserved before the window shrinks.

## Installation

1. Copy hooks to your Claude hooks directory:

```bash
cp configs/claude/hooks/mempal_*.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/mempal_*.sh
```

2. Update your `~/.claude/settings.json` with the hook configuration above

3. Ensure mempalace is installed:

```bash
pip3 install mempalace
```

## Customization

### Adjust Save Frequency

Edit `mempal_save_hook.sh` and change:

```bash
THRESHOLD=15  # Change to your preferred message count
```

### Add Custom Memory Types

Extend the Python block in either hook to save additional context:

```python
mempalace.save_custom(
    category='my_category',
    content='custom data',
    priority='medium'
)
```

### Silent Operation

Both hooks are designed to fail silently — they won't interrupt your workflow if mempalace isn't available or errors occur.

## Integration with Specialist Agents

Combine with [Specialist Agents](./mempalace-specialist-agents.md) for powerful workflows:

```python
# In save hook - route to appropriate agent
if "security" in discussion_topics:
    mempalace_diary_write("security", "...")
elif "architecture" in discussion_topics:
    mempalace_diary_write("architect", "...")
```

## Environment Variables

The hooks respect these environment variables:

- `CLAUDE_SESSION_ID` — Session identifier (auto-set by Claude Code)
- `COMPACT_REASON` — Reason for pre-compact (auto-set by Claude Code)
- `TMPDIR` — Temporary directory for counter file
- `PWD` — Working directory (auto-set)

## Troubleshooting

### Hooks not firing

1. Check hook paths in settings.json
2. Verify scripts are executable: `chmod +x ~/.claude/hooks/mempal_*.sh`
3. Test manually: `~/.claude/hooks/mempal_save_hook.sh`

### Mempalace not found

- Ensure `pip3 install mempalace` completed successfully
- Verify python3 is in PATH
- Check `python3 -c "import mempalace"` works

### Counter not resetting

- Check `$TMPDIR` is writable
- Delete counter file: `rm /tmp/.mempal_save_counter`
- Check file permissions
