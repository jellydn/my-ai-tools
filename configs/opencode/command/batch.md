---
description: Decompose a large migration or refactor into parallel worker tasks, each reviewed with /simplify and submitted as an independent PR
---

Decompose the following work into parallel worker tasks and execute them: $ARGUMENTS

## How to Use

Describe the overall goal. `/batch` will plan and parallelize the work:

```
/batch Migrate all lodash usages to native equivalents
```

```
/batch Add type annotations to all untyped function parameters in src/
```

```
/batch Replace deprecated API calls across the codebase with v2 equivalents
```

## Three Phases

### Phase 1 — Research and Plan

Explore the affected files, decompose the work into independent units (typically 5–30 tasks), and determine how to verify each one. Tasks that can be done independently are parallelized; tasks with dependencies are ordered correctly.

### Phase 2 — Spawn Workers

One background agent per task unit, each running in an isolated git worktree. Every agent:

1. Implements its task fully.
2. Runs `/simplify` on its changes (Code Reuse → Code Quality → Efficiency review).
3. Executes tests to verify correctness.
4. Commits and opens a pull request.

Each worker operates independently — if one fails, the others keep going. Every PR is independently mergeable.

### Phase 3 — Track Progress

A status table updates as workers complete, showing which PRs are ready for review.

## When to Use `/batch`

**Good for:**

- Framework migrations (e.g. class components → hooks, lodash → native)
- API contract updates across all callers
- Convention enforcement across a codebase
- Dependency replacements
- Test generation for untested modules

**Not for:**

- Tightly coupled changes that require coordination between units
- Exploratory refactoring where you don't yet know the target shape
- Single-file modifications (use `/simplify` instead)
