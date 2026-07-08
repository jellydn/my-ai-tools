---
name: "git-context"
description: "Search git history for context — commit messages, blame, related changes, impact analysis"
license: "MIT"
compatibility: "claude, opencode, codex, gemini, cursor, pi"
hint: "Use to understand why code was written a certain way or find related changes"
user-invocable: true
---

# Git Context

## When to Use

Use this skill when:
- Understanding why code was written a certain way
- Finding related changes across the codebase
- Tracing the evolution of a feature or pattern
- Identifying who has expertise in a module
- Finding past bug fixes or regressions in an area

## What It Does

Searches git history to build context about the codebase, using a combination of native git commands and the `sem` MCP tool for deeper analysis. Helps answer "why was this done this way?" and "what changed recently in this area?"

## Available Tools

| Tool | What It Does | Best For |
|------|-------------|----------|
| `git log` | Commit history with messages | Recent changes, who changed what |
| `git log -S` | History-aware content search | Finding when a function/string was introduced |
| `git blame` | Line-by-line attribution | Who last changed each line and why |
| `git diff` | Compare branches/commits | What changed between versions |
| `sem blame` | Entity-level blame (function/class) | Why a specific function changed |
| `sem diff` | Entity-level diff | What changed in a function specifically |
| `sem impact` | Impact analysis for a change | What would be affected by a change |
| `ctx search` | Past agent sessions | Previous discussions about this code |

## How to Execute

### Find Recent Changes to a Module

```bash
# Recent commits touching this area
git log --oneline --all -20 -- path/to/module/

# Who works on this area most
git shortlog -sn -- path/to/module/

# When a specific function was introduced
git log -S "functionName" --oneline -- path/to/module/
```

### Trace a Function's History

```bash
# When was this function introduced?
git log -S "export function calculateTotal" --oneline

# Who has modified it?
git blame path/to/file.ts -L 10,30

# What was the commit message?
git show <commit-hash> --no-patch
```

### Find Related Changes

```bash
# Files changed together in the same commits
git log --all --name-only -- path/to/changed/file.ts | head -20

# Find commits that reference a ticket or pattern
git log --all --grep="fix|bug|hotfix" --oneline -20
```

### Using `sem` for Deeper Analysis

```bash
# Entity-level blame (function level)
sem blame path/to/file.ts --function processOrder

# Impact analysis
sem impact path/to/file.ts --function processOrder

# Compare branches at function level
sem diff main..HEAD -- path/to/file.ts
```

### Cross-Session Context

```bash
# Search past agent sessions about this module
ctx search "this module" path/to/module/

# Find past discussions about related changes
ctx search "bug fix" path/to/module/
```

## Decision Tree

```
┌────────────────────────────┬────────────────────────┐
│ Need this                   │ Use this               │
├────────────────────────────┼────────────────────────┤
│ What changed recently      │ git log -20 -- path/   │
│ Who works on this module   │ git shortlog -sn path/ │
│ Why was this line added    │ git blame path/to/file │
│ When was function added    │ git log -S "funcName"  │
│ What else changed together │ git log --name-only    │
│ Impact of changing X       │ sem impact path/func   │
│ Past agent work on this    │ ctx search "topic"     │
└────────────────────────────┴────────────────────────┘
```

## Common Patterns

### Pre-Implementation Check

Before implementing a change, check:

```bash
# 1. Recent changes to affected modules
git log --oneline --all -10 -- src/feature/

# 2. Who has expertise
git shortlog -sn -- src/feature/ | head -5

# 3. Related commits (ticket/branch references)
git log --all --grep="feature-name" --oneline

# 4. Past bugs in this area
git log --all --grep="bug|fix|error" --oneline -10 -- src/feature/
```

### Post-Change Verification

After implementing, verify:

```bash
# 1. What did I change?
git diff --stat

# 2. Are there unrelated changes?
git diff --cached --name-only

# 3. Did I miss anything?
git diff HEAD --name-only  # Unstaged changes
```

## Tips

- **Commit messages matter**: Write clear messages — they become the primary documentation
- **Use `git log -S` over `grep` for history**: `grep` scans the working tree; `git log -S` scans history
- **Combine with `ctx`**: Past agent sessions often contain context that git history doesn't
- **Be specific with paths**: `git log -- path/` filters to relevant commits, reducing noise
- **Use `--all` for complete picture**: Default `git log` only shows current branch history

## Integration with Other Skills

- Use before `/blindspots` to gather initial context
- Use during `context-discovery` for deep git history analysis
- Log surprising git history findings in `implementation-logger`
