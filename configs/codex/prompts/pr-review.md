# Fix PR Review Comments

Systematically fix all unresolved code review comments from a GitHub pull request.

## Usage

`/fix-review $1`

Where $1 is the PR number.

## Prerequisites

- GitHub CLI (`gh`) must be authenticated and configured
- Must be on the correct branch for the PR

## Process

### 1. Fetch and Extract Comments

```bash
# Fetch both review comments and issue comments
gh api repos/:owner/:repo/pulls/$1/comments --paginate > pr-$1-review-comments-raw.json
gh api repos/:owner/:repo/issues/$1/comments --paginate > pr-$1-issue-comments-raw.json

# Validate files have content
test -s pr-$1-review-comments-raw.json && echo "Review comments found"
test -s pr-$1-issue-comments-raw.json && echo "Issue comments found"
```

### 2. Review Comments Overview

```bash
# Quick analysis
cat pr-$1-comments-summary.md

# Prioritized todo list (sorted by severity)
cat pr-$1-comments-todo.md
```

### 3. Systematic Comment Resolution

For each todo item:

a) Find comment details:
```bash
grep "\"id\":COMMENT_ID" pr-$1-comments.ndjson
```

b) Locate and understand the issue:
- Read the affected file and surrounding context
- Review the diff_hunk to understand the specific concern

c) Apply fixes:
- Use Edit/MultiEdit for safe, targeted changes
- Maintain existing code style and conventions

### 4. Validation

```bash
# Run type checking
npm run typecheck

# Run linting
npm run lint

# Run tests
npm run test
```

## Guidelines

### What to Fix

- Code quality issues: Type errors, linting violations, unused variables
- Best practices: Const vs let, proper error handling, naming conventions
- Documentation: Missing JSDoc, unclear variable names
- Performance: Obvious inefficiencies, unnecessary re-renders
- Security: Potential vulnerabilities, exposed secrets
- Maintainability: Complex logic that needs simplification

### What to Skip

- Major architectural changes that require broader discussion
- Subjective style preferences when existing code is consistent
- Complex design decisions that need product/UX input
- Breaking changes that affect public APIs

## Cleanup

After completion, clean up temporary files:
```bash
rm pr-$1-*comments*.json pr-$1-*.ndjson pr-$1-*todo.md pr-$1-*summary.md
```
