---
name: draft-pull-request
description: "Draft pull requests with structured descriptions using gh CLI"
license: MIT
compatibility: cline, claude, opencode, amp, codex, gemini, cursor, pi
hint: Use when creating or updating a draft pull request with a structured description using gh CLI
user-invocable: true
disable-model-invocation: true
metadata:
  audience: all
  workflow: git
---

# Draft Pull Request

Create a draft pull request, or update the current branch's PR, with a **What / Why / How** description. The
description must let a reviewer understand why the change exists and the shape of the implementation without reading
every line of the diff.

## Usage

```bash
/draft-pull-request [title]
```

- If a title is provided via `$ARGUMENTS`, use it as the PR title.
- Otherwise, derive a concise Conventional Commit title from the branch name and commit history.

## Bundled References

| File                                         | Read when                                                  |
| -------------------------------------------- | ---------------------------------------------------------- |
| `$SKILL_PATH/references/pr-body-template.md` | Always, before you write the PR body                       |
| `$SKILL_PATH/references/change-outline.md`   | The **How** section needs a file tree, call tree, or shape |

## Process

### 1. Preflight: find or prepare the PR

```bash
BASE_BRANCH=$(gh repo view --json defaultBranchRef -q '.defaultBranchRef.name')
git branch --show-current
git status --short --branch

# Reuse an existing PR for this branch instead of opening a duplicate
gh pr view --json number,url,title,state,isDraft,baseRefName,body 2>/dev/null
```

- **Open PR exists** — set `BASE_BRANCH` to its `baseRefName`, which may differ from the default branch, and update
  its body in step 4. Do not create a second PR or change its draft state.
- **On the default branch** — create a feature branch named after the change before you continue. Never open a PR
  from the default branch.
- **Uncommitted task changes** — commit them first (use `commit-atomic` when it is available). Leave unrelated or
  unfamiliar changes uncommitted and mention them in the final report.
- **No commits ahead of the base** — stop and report that there is nothing to open a PR for.

### 2. Gather only the context you need

```bash
git fetch origin "$BASE_BRANCH" --quiet
git log "origin/$BASE_BRANCH"..HEAD --oneline
git diff "origin/$BASE_BRANCH"...HEAD --stat
git diff "origin/$BASE_BRANCH"...HEAD
```

- For an existing PR, prefer GitHub's view: `gh pr diff <number>` and `gh pr view <number> --json commits,files`.
  This stays correct when the branch lives in a fork and `origin` is not the base repository.
- Read the complete diff and enough surrounding code to understand behavior and ownership.
- Read the linked issue, plan, ADR, or handoff when one exists. Collect their links for the body.
- Note the validation you actually ran (tests, lint, typecheck, manual checks) and the results.

### 3. Write the description

1. Read `$SKILL_PATH/references/pr-body-template.md` and follow its rules.
2. If the repository has its own PR template (`.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE/`,
   or `docs/pull_request_template.md`), keep its headings and checklists, and put the What / Why / How content into
   the matching sections.
3. When prose alone does not show the shape of the change, read `$SKILL_PATH/references/change-outline.md` and add
   one to three small views to **How**.
4. Write the body to a temporary file, not to the repository:

```bash
BODY_FILE=$(mktemp "${TMPDIR:-/tmp}/pr-body.XXXXXX")
```

### 4. Publish

```bash
# Never force-push.
git push -u origin HEAD

# New PR
gh pr create --draft --base "$BASE_BRANCH" --title "<PR title>" --body-file "$BODY_FILE"

# Existing PR from step 1
gh pr edit <number> --body-file "$BODY_FILE"
```

Use `--body-file` instead of `--body` so that Markdown, backticks, and code fences survive shell quoting.

`gh pr edit --body-file` replaces the whole body. Before you edit an existing PR, carry over from its current `body`
anything the diff cannot tell you: links, reviewer notes, and checklist items that someone ticked and that still apply.

### 5. Confirm and report

```bash
gh pr view --json url,title,isDraft -q '"\(.url) draft=\(.isDraft) \(.title)"'
rm -f "$BODY_FILE"
```

Reply with:

```markdown
- PR: [#<number> <title>](<url>) (<draft or ready for review, from isDraft>)
- Summary: <2-3 sentences: what the PR does and the key decision>
- Validation: <commands run and their results, or "not run">
- Left out: <uncommitted or unrelated changes, or "none">
```

## Guidelines

- **Title**: Short, imperative, max 72 characters (e.g., `feat(auth): add JWT refresh token support`).
- **Body**: Section rules live in `references/pr-body-template.md`; do not restate them here.
- **Language**: Write as one person to another — plain, concise, no jargon or filler.

## Example

````markdown
Closes #142

## What

Add a refresh-token endpoint and automatic token renewal in the API client.

## Why

Users are logged out when the 1-hour access token expires, which interrupts long sessions.

## How

- `POST /auth/refresh` validates the HttpOnly refresh cookie and issues a new access token.
- The API client retries a `401` response once, after a refresh, before it shows an error.

```diff
 request(url)
   send with access token
+  if status is 401 and not retried
+    refreshToken()
+    retry once
   return response
```

## Reviewer notes

- Refresh tokens rotate on each use; a reused token revokes the whole session.

## Validation

- `bun test src/auth` — 24 passed
- Manual: session stays signed in after the access token expires
````
