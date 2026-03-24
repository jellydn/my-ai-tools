---
description: Review recently modified code from three perspectives (Code Reuse, Code Quality, Efficiency) and apply all findings
---

Review the recently modified code ($ARGUMENTS or `git diff --name-only` if no argument is given) from three distinct perspectives, then apply all actionable findings.

## Three Review Perspectives

Work through each perspective independently before making any edits, so findings from all three are considered together:

### 1. Code Reuse

Look for:

- Logic duplicated across two or more places that could share a single implementation
- Redundant patterns that could be consolidated
- Helper functions or utilities that already exist in the codebase but were re-implemented

### 2. Code Quality

Look for:

- Readability problems: confusing variable/function names, deeply nested blocks, long functions
- Structural concerns: responsibilities mixed in a single function or module, missing abstractions
- Style inconsistencies relative to the surrounding codebase

### 3. Efficiency

Look for:

- Performance bottlenecks: N+1 queries, redundant loops, repeated expensive computations
- Unnecessary computation that can be eliminated or cached
- Wasted work: operations whose results are never used

## Process

1. **Identify the target files**: Use `$ARGUMENTS` as the file path or scope. If empty, run `git diff --name-only` to get recently modified files.
2. **Apply all three review lenses**: Analyze the code from each perspective above and collect all findings before editing anything.
3. **Apply fixes**: Work through the combined findings and apply all actionable improvements surgically, preserving functionality.
4. **Verify**: Confirm the code still builds and tests pass after changes.

## What NOT to Change

- Comments that explain non-obvious business logic or architecture decisions
- Abstractions used in multiple places that genuinely reduce duplication
- Error handling that matches patterns used elsewhere in the codebase
- Public API boundaries that other code depends on
