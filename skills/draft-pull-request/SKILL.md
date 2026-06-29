---
name: draft-pull-request
description: Creates a draft pull request using gh CLI with a structured what/why/how description
license: MIT
compatibility: cline, claude, opencode, amp, codex, gemini, cursor, pi
hint: Use when creating a draft pull request with a structured description using gh CLI
user-invocable: true
metadata:
  audience: all
  workflow: git
---

# Draft Pull Request

Create a draft pull request using `gh` CLI with a structured **What / Why / How** description that communicates the purpose and approach of your changes clearly.

## Usage

```bash
/draft-pull-request [title]
```

- If a title is provided via `$ARGUMENTS`, use it as the PR title.
- Otherwise, derive a concise title from the branch name and commit history.

## Process

### 1. Gather context

```bash
# Detect the repository's default branch
BASE_BRANCH=$(gh repo view --json defaultBranchRef -q '.defaultBranchRef.name')

# Check current branch
git branch --show-current

# Review commit history since branching from base
git log "$BASE_BRANCH"..HEAD --oneline

# Review the full diff
git diff "$BASE_BRANCH"..HEAD --stat
git diff "$BASE_BRANCH"..HEAD
```

### 2. Compose the PR description

Write a structured description following the **What / Why / How** template:

```markdown
## What

[Concise summary of the changes made. What was added, modified, or removed?]

## Why

[The motivation behind this change. What problem does it solve? What opportunity does it capture?]

## How

[Brief explanation of the approach taken. Key technical decisions, patterns used, or trade-offs made.]

## Checklist

- [ ] Tests added or updated
- [ ] Documentation updated
- [ ] No breaking changes (or breaking changes documented above)
```

### 4. Create the draft PR with gh CLI

```bash
gh pr create \
  --draft \
  --title "<PR title>" \
  --body "<structured what/why/how description>"
```

Use `--draft` to signal the PR is not yet ready for review.

### 4. Output the PR URL

After creation, display the PR URL:

```bash
gh pr view --json url -q '.url'
```

## Guidelines

- **Title**: Short, imperative, max 72 characters (e.g., `feat: add user authentication flow`)
- **What**: Describe the surface area of changes — files, components, APIs affected
- **Why**: Explain the business or technical reason — avoid vague phrases like "to improve things"
- **How**: Highlight non-obvious implementation details or trade-offs, not every line changed
- Keep the description concise but complete — reviewers should understand the PR without reading all the code

## Example

```bash
gh pr create \
  --draft \
  --title "feat(auth): add JWT refresh token support" \
  --body "## What

Add a refresh token endpoint and client-side token renewal logic.

## Why

Users were being logged out after the 1-hour access token expiry,
causing friction for long-running sessions. Refresh tokens allow
seamless re-authentication without user interaction.

## How

- Added POST /auth/refresh endpoint that validates refresh tokens
  stored in HttpOnly cookies and issues new access tokens
- Extended AuthService with refreshToken() and revokeToken() methods
- Updated the API client to automatically retry failed requests with
  a refreshed token before surfacing errors to the UI

## Checklist

- [x] Tests added or updated
- [x] Documentation updated
- [ ] No breaking changes (or breaking changes documented above)"
```
