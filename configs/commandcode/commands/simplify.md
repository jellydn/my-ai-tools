---
description: Simplify recently modified code without changing behavior
---

Simplify `$ARGUMENTS`, or the files from `git diff --name-only` when no scope is given. Preserve behavior and public APIs.

Review the full scope before editing:

- **Reuse:** remove duplication and use existing canonical helpers.
- **Quality:** improve unclear names, deep nesting, mixed responsibilities, and inconsistent local style.
- **Efficiency:** remove N+1 work, redundant loops, repeated expensive operations, and unused computation.

Apply only clear improvements. Do not change useful business or architecture comments, established shared abstractions, standard error handling, or public API boundaries.

Finish when all actionable findings are applied and the relevant build, tests, and checks pass.
