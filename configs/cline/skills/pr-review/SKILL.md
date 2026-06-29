---
name: pr-review
description: Fix PR review comments by implementing the requested changes
license: MIT
compatibility: claude, opencode, amp, codex, gemini, cursor, pi, cline
hint: Use when fixing PR review comments or addressing review feedback
user-invocable: true
metadata:
  audience: all
  workflow: code-quality
---

# Fix PR Review Comments

Fix PR review comments by implementing the requested changes.

## Usage

```bash
/pr-review <PR_URL>      # Review PR by URL
/pr-review <PR_NUMBER>   # Review PR by number
/pr-review               # Auto-detect PR from current branch
```

### Argument Handling

The command accepts the PR identifier from `$ARGUMENTS`:

1. **PR URL**: Full GitHub PR URL
2. **PR Number**: Just the PR number
3. **No Arguments**: Auto-detect the PR associated with the current Git branch

If no open PR is found for the current branch, show an error message with instructions.

## Process

1. Parse `$ARGUMENTS` to determine PR identifier
2. Fetch PR details and review comments using `gh` CLI
3. Parse review comments to understand what needs to be changed
4. For each comment, implement the fix
5. Run tests to ensure nothing breaks
6. Commit the changes

## Available Scripts

The `$SKILL_PATH/scripts/extract-pr-comments.js` script processes review comments:

```bash
node $SKILL_PATH/scripts/extract-pr-comments.js <review-comments> <issue-comments> [output]
```

**What it does:**
- Filters out comments with replies (likely resolved)
- Classifies by severity (critical, high, medium, low)
- Categorizes (security, performance, maintainability, etc.)
- Creates TODO list and analysis summary

## Examples

```bash
/pr-review https://github.com/owner/repo/pull/123
/pr-review 123
/pr-review
```
