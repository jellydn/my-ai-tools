---
name: pr-review
description: Fix PR review comments by implementing requested changes
license: MIT
compatibility: claude, opencode, amp, codex
hint: Use when fixing PR review comments or addressing review feedback
metadata:
  audience: all
  workflow: code-quality
---

# Fix PR Review Comments

Fix PR review comments by implementing the requested changes.

## Usage

`/pr-review <PR_URL>`

If no PR URL is provided, will prompt for one.

## Process

1. Fetch PR details and review comments using `gh` CLI
2. Parse review comments to understand what needs to be changed
3. For each comment, implement the fix
4. Run tests to ensure nothing breaks
5. Commit the changes

## Examples

```bash
# Fix review comments for a PR
/pr-review https://github.com/owner/repo/pull/123
```
