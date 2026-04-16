---
name: gh-stack-pr
description: Create and manage stacked pull requests with gh-stack
license: MIT
compatibility: claude, opencode, amp, codex, gemini, cursor, pi
hint: Use when working with stacked pull requests via gh-stack
user-invocable: true
metadata:
  audience: all
  workflow: git
---

# gh-stack PR Workflow

Use this skill to create and manage stacked pull requests with `gh stack`.

## Usage

`/gh-stack-pr [ACTION]`

## Actions

- **setup** - Install and verify `gh-stack`
- **submit** - Push the current branch and update/create the PR stack
- **sync** - Sync the stack with latest remote changes
- **rebase** - Rebase the stack on top of the latest base branch
- **land** - Merge the stack in order

## Setup

```bash
gh extension install github/gh-stack
gh stack --help
```

## Typical Flow

1. Create a branch for the first PR in the stack.
2. Commit changes.
3. Run `gh stack submit` to create/update the PR.
4. Create the next branch from current HEAD and repeat.
5. Run `gh stack sync` or `gh stack rebase` when base branch changes.
6. Run `gh stack land` when the stack is ready to merge.

## Common Commands

```bash
gh stack submit
gh stack submit --draft
gh stack sync
gh stack rebase
gh stack land
```

## Compatibility

### Universal (.agents/skills) — always included

- Amp
- Antigravity
- Cline
- Codex
- Cursor
- Deep Agents
- Firebender
- Gemini CLI
- GitHub Copilot
- Kimi Code CLI
- OpenCode
- Warp
