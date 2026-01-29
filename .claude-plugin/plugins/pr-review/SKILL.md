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

## Available Scripts

### Extract PR Comments

The `extract-pr-comments.js` script processes GitHub PR review comments and issue comments to create actionable TODO lists.

```bash
# Usage
node $SKILL_PATH/scripts/extract-pr-comments.js <review-comments-file> <issue-comments-file> [output-file]

# Example
node $SKILL_PATH/scripts/extract-pr-comments.js \
  pr-4972-review-comments-raw.json \
  pr-4972-issue-comments-raw.json \
  pr-4972-comments.ndjson
```

**What it does:**
- Filters out comments with replies (likely resolved)
- Classifies comments by severity (critical, high, medium, low)
- Categorizes comments (security, performance, maintainability, etc.)
- Creates 3 output files:
  - `.ndjson` - Structured comment data
  - `-todo.md` - Prioritized TODO list
  - `-summary.md` - Analysis summary with emojis

**Severity classification:**
- 🔴 **Critical**: security, vulnerability, exploit
- 🟠 **High**: bug, error, breaking, crash, fail
- 🟡 **Medium**: performance, improvement, refactor, optimize
- 🟢 **Low**: everything else

**Categories:**
- 🔒 Security
- ⚡ Performance
- 🔧 Maintainability
- ♿ Accessibility
- 🧪 Testing
- 📚 Documentation
- 🏷️ Typing
- 🎨 Style
- ✨ Code Quality

## Examples

```bash
# Fix review comments for a PR
/pr-review https://github.com/owner/repo/pull/123

# After extracting comments with the script, work through the TODO list
# The TODO list is ordered by priority: Critical → High → Medium → Low
```
