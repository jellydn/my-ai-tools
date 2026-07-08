---
name: pickup
description: "Resume work from previous handoff sessions stored in .planning/handoffs/"
license: MIT
compatibility: claude, opencode, codex, gemini, cursor, pi
hint: Use when resuming work from a previous handoff session
user-invocable: true
metadata:
  audience: all
  workflow: workflow
---

# Pickup Handoff

Resumes work from previous handoff sessions which are stored in `.planning/handoffs/`.

## Usage

`/pickup [HANDOFF_FILE]`

If no handoff file is specified, will show available handoffs and prompt for selection.

## Process

1. Find available handoffs in `.planning/handoffs/`
2. Read the selected handoff file
3. Present the handoff summary to the user
4. Ask the user to confirm they want to continue
5. If confirmed, proceed with the next step described in the handoff

## Available Handoffs

To see available handoffs:

```bash
ls -la .planning/handoffs/
```

Handoffs are named in format: `[YYYY-MM-DD]-[slug].md`
