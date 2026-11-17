---
name: visual-pr
description: "Posts a concise visual outline as a GitHub pull request comment. Use only when the user explicitly asks for visual-pr."
license: MIT
compatibility: Requires git, jq, and the GitHub CLI (gh)
user-invocable: true
disable-model-invocation: true
metadata:
  audience: all
  workflow: git
---

# Visual PR

Post a compact visual explanation of a pull request as a comment. Do not replace or append to the pull request
description.

## Workflow

### 1. Find or create the pull request

```bash
gh pr view --json url,number,title,state,baseRefName,headRefName 2>/dev/null
```

- Use the open pull request for the current branch when one exists.
- If no pull request exists, inspect the branch, commit task changes when needed, push it, and create a draft pull
  request according to the repository's conventions. Do not use the visual outline as the pull request body.
- Ask the user to select a pull request only when the current branch has no relevant work and there is no safe pull
  request to create.

### 2. Understand the change

- Read the ticket and relevant task artifacts.
- Read the complete pull request diff and enough surrounding code to understand behavior and ownership.
- Use `gh pr view` to collect metadata and changed files.
- Identify only the contracts, responsibilities, and runtime paths that a reviewer needs to understand.

### 3. Write the visual outline

Read `$SKILL_PATH/references/comment-template.md`, then write the completed comment to a temporary file:

```bash
COMMENT_FILE=$(mktemp "${TMPDIR:-/tmp}/visual-pr-comment.XXXXXX")
```

Keep the outline concise:

- Explain **Why the change** in exactly one sentence.
- Put only reviewer warnings, migrations, compatibility constraints, deliberate omissions, or surprising decisions in
  **Special things to note**. Use `- None.` when there are none.
- Make **Change outline** a structural view, not prose or a file-by-file changelog.
- Use one to three focused views: a data or API shape, pseudocode, a shallow file tree, a component tree, or a call,
  control, or data flow.
- Prefer `diff` blocks for changes to an existing shape. Show the complete target shape when most of it is new.
- Use real names from the diff and omit categories that did not change.

### 4. Publish and verify the comment

```bash
COMMENT_URL=$("$SKILL_PATH/scripts/publish-comment.sh" <number> "$COMMENT_FILE")
test -n "$COMMENT_URL"
printf '%s\n' "$COMMENT_URL"
rm -f "$COMMENT_FILE"
```

The script adds a hidden `visual-pr` marker. It updates the current GitHub user's existing marked comment, or runs
`gh pr comment` when none exists. Thus, one pull request has at most one visual-pr comment from that user. Never use
`gh pr edit` for the visual outline because that replaces the pull request description.

### 5. Report completion

Reply with the pull request URL, the comment URL returned by GitHub, a two-sentence summary, and the verification that
the comment command succeeded.

Write as one person to another. Use simple, concise language and avoid jargon.
