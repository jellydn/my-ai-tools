---
name: pr-review
description: "Fix PR review comments by implementing requested changes"
license: MIT
compatibility: cline, claude, opencode, amp, codex, gemini, cursor, pi
hint: Use when fixing PR review comments or addressing review feedback. Accepts PR URL, PR number, or auto-detects from current branch
user-invocable: true
metadata:
  audience: all
  workflow: code-quality
---

# Fix PR Review Comments

Fix PR review comments by implementing the requested changes.

## Usage

```bash
/pr-review <PR_URL>      # Review PR by URL (expects full GitHub URL)
/pr-review <PR_NUMBER>   # Review PR by number (expects number, e.g., 123)
/pr-review               # Auto-detect PR from current branch
```

### 📋 Argument Handling

The command accepts the PR identifier from `$ARGUMENTS`:

1. **PR URL**: Full GitHub PR URL (e.g., `https://github.com/owner/repo/pull/123`)
2. **PR Number**: Just the PR number (e.g., `123`)
3. **No Arguments**: Auto-detect the PR associated with the current Git branch

If `$ARGUMENTS` is provided, use it as the PR identifier. Otherwise, auto-detect the current branch's PR using:

```bash
gh pr view --json number,url -q '.number'
```

This extracts the PR number from the current branch's open PR for use in subsequent commands.

If no open PR is found for the current branch, show this error:

```text
Error: No open pull request found for the current branch.

To review a specific PR:
  /pr-review <PR_URL>
  /pr-review <PR_NUMBER>

Or create a PR first:
  gh pr create
```

## Process

1. Parse `$ARGUMENTS` to determine PR identifier (URL, number, or auto-detect)
2. Fetch PR details, review threads, issue comments, and authoritative thread-resolution state using `gh`
3. Classify each comment as actionable, informational, disputed/ambiguous, or resolved; ask before changing disputed or ambiguous requests
4. For each actionable comment, record the comment ID, planned change, and verification command
5. Implement the approved fixes
6. Run focused tests, then the relevant broader checks
7. Recheck the comment-to-change list and confirm every actionable thread is resolved or explicitly deferred
8. Commit the changes

## Available Scripts

### Extract PR Comments

The `extract-pr-comments.js` script processes GitHub PR review comments and issue comments to create actionable TODO lists.

```bash
# Usage
node $SKILL_PATH/scripts/extract-pr-comments.js <review-comments-file> <issue-comments-file> <threads-file> [output-file]

# Example
gh api graphql \
  -f owner=OWNER -f name=REPO -F number=4972 \
  -f query='query($owner:String!, $name:String!, $number:Int!) { repository(owner:$owner, name:$name) { pullRequest(number:$number) { reviewThreads(first:100) { nodes { isResolved comments(first:100) { nodes { databaseId } } } } } } }' \
  > pr-4972-threads.json

node $SKILL_PATH/scripts/extract-pr-comments.js \
  pr-4972-review-comments-raw.json \
  pr-4972-issue-comments-raw.json \
  pr-4972-threads.json \
  pr-4972-comments.ndjson
```

**What it does:**

- Requires a threads file of GitHub review threads and skips a review comment only when its thread has `isResolved: true`
- Does not treat a reply as resolution; an unanswered thread stays actionable
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
# Fix review comments for a PR using URL
/pr-review https://github.com/owner/repo/pull/123

# Fix review comments using PR number
/pr-review 123

# Auto-detect PR from current branch
/pr-review

# After extracting comments with the script, work through the TODO list
# The TODO list is ordered by priority: Critical → High → Medium → Low
```
