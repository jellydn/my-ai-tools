---
description: Simplify over-engineered code for clarity and maintainability
---

Simplify the code in $ARGUMENTS (or the current file/selection if no argument is given).

## Goals

- Remove unnecessary complexity and over-engineering
- Eliminate redundant abstractions, helpers, or indirection that add no clear value
- Reduce coupling between components where possible
- Keep solutions simple and focused on what is actually needed
- Preserve all existing functionality and behavior

## Process

1. **Identify the target**: Use `$ARGUMENTS` as the file path or scope. If empty, examine recently modified files via `git diff`.
2. **Analyze complexity**: Look for over-abstracted patterns, unnecessary layers, redundant code, and excessive defensive checks not present elsewhere in the codebase.
3. **Simplify surgically**: Apply the smallest possible changes to reduce complexity while keeping the code readable and idiomatic.
4. **Verify**: Confirm the code still builds and tests pass after simplification.

## What to Simplify

- Unnecessary wrapper functions or classes that add no behavior
- Excessive indirection (e.g., calling a function that just calls another function)
- Over-parameterized functions where simpler signatures suffice
- Premature abstractions not yet warranted by the codebase
- Redundant comments describing obvious code
- Dead code paths or unused variables

## What NOT to Change

- Comments that explain non-obvious business logic or architecture decisions
- Abstractions that are used in multiple places and genuinely reduce duplication
- Error handling that matches patterns used elsewhere in the codebase
- Public API boundaries that other code depends on
