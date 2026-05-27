---
name: commit-atomic
description: Creates atomic commits by logically grouping staged changes with commitizen convention
license: MIT
compatibility: claude, opencode, amp, codex, gemini, cursor, pi
hint: Use when committing staged changes as focused, atomic commits grouped by logical change
user-invocable: true
metadata:
  audience: all
  workflow: git
---

# Atomic Commit with Logical Grouping

Create atomic commits by logically grouping changes following the commitizen/conventional commits convention. Each commit should represent one logical change with a clear, informative message explaining the **what** and **why**.

## Usage

```bash
/commit-atomic
```

## Process

### 1. Inspect the current changes

```bash
git status
git diff --staged
git diff
```

Review all modified, added, and deleted files to understand the full scope of changes.

### 2. Group changes logically

Analyze the changes and group them into **logical, independent units**. Each group should:

- Address a single concern or feature
- Be independently understandable
- Not break the build or tests on its own
- Follow the dependency order (low-level to high-level)

**Grouping strategies:**

- By feature or concern (e.g., authentication, UI, database)
- By type (e.g., refactoring, bug fix, new feature)
- By layer (e.g., model, service, controller)

### 3. Stage each group intentionally

**Never use `git add -A` or `git add --all`.** Instead, stage files explicitly:

```bash
# Stage specific files
git add <file1> <file2>

# Stage specific hunks interactively
git add -p <file>

# Verify what is staged before committing
git diff --staged
```

### 4. Commit each group with a commitizen message

Follow the **commitizen conventional commits** format:

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

**Types:**

| Type       | When to use                                           |
| ---------- | ----------------------------------------------------- |
| `feat`     | A new feature                                         |
| `fix`      | A bug fix                                             |
| `docs`     | Documentation only changes                            |
| `style`    | Formatting, missing semicolons (no code logic change) |
| `refactor` | Code change that is neither a fix nor a feature       |
| `perf`     | A code change that improves performance               |
| `test`     | Adding or fixing tests                                |
| `chore`    | Build process or auxiliary tool changes               |
| `ci`       | CI configuration changes                              |
| `build`    | Changes that affect the build system or dependencies  |
| `revert`   | Reverts a previous commit                             |

**Writing good commit messages:**

- **Subject line**: Imperative mood, max 72 characters, no period at end
- **Body** (optional): Explain the **why**, not just the what; wrap at 72 characters
- **Footer** (optional): Reference issues (`Closes #123`), breaking changes (`BREAKING CHANGE: ...`)

**Examples:**

```
feat(auth): add JWT refresh token support

Refresh tokens allow users to stay logged in without re-authenticating.
This reduces friction for long-running sessions.

Closes #42
```

```
fix(api): handle null response from external service

The external API occasionally returns null for optional fields.
Previously this caused an unhandled TypeError at runtime.
```

```
refactor(utils): extract date formatting into shared helper

Consolidates duplicate date formatting logic spread across three
modules into a single reusable function.
```

### 5. Verify after each commit

```bash
git log --oneline -5
git status
```

Ensure the working tree is clean after all logical groups are committed.

## Rules

- ❌ Never use `git add -A` or `git add --all`
- ❌ Never mix unrelated changes in a single commit
- ✅ Stage files explicitly with `git add <file>` or `git add -p`
- ✅ Verify staged changes with `git diff --staged` before committing
- ✅ Write messages in imperative mood ("add feature" not "added feature")
- ✅ Explain the **why** in the commit body when the change is non-obvious
- ✅ Keep each commit independently buildable and testable
