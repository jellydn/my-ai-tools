---
description: Simplify and refactor code to reduce complexity and improve readability
argument-hint: [file path or description of what to simplify]
---

Simplify the code identified by $ARGUMENTS (or the current context if no argument is given).

## Goal

Reduce complexity and improve readability while preserving all existing functionality and behavior.

## Process

1. **Identify the target** – Use `$ARGUMENTS` as the file path or description. If empty, work on the file most recently discussed or edited.
2. **Analyze** – Read the target code and identify complexity hotspots:
   - Deep nesting (if/else chains, nested loops)
   - Long functions that do more than one thing
   - Duplicated logic or magic values
   - Ambiguous or inconsistent variable or function names
   - Unnecessary abstraction layers
3. **Simplify** – Apply targeted refactors:
   - Extract well-named helper functions for repeated or complex logic
   - Flatten nesting with early returns / guard clauses
   - Replace magic values with named constants
   - Remove dead code and unused variables
   - Prefer idiomatic language patterns over verbose alternatives
4. **Preserve behavior** – The simplified code must pass existing tests and maintain all original functionality. Run the project's test suite if available.
5. **Report** – Show a brief summary of what changed and why, so the author understands the improvements.

## Constraints

- Do **not** change public APIs, function signatures, or exported names unless explicitly asked.
- Do **not** rewrite working logic just to use a different algorithm; focus on clarity, not cleverness.
- Match the style conventions of the surrounding file.
