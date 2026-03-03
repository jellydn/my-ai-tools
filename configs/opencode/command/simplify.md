---
description: Simplify and clean up code to reduce complexity and improve readability
argument-hint: [file or code to simplify]
---

## Task

Simplify the code or content specified in `$ARGUMENTS`. If no argument is provided, simplify the most recently discussed or edited code.

## Guidelines

1. **Reduce complexity**: Remove unnecessary abstractions, over-engineering, and indirection.
2. **Eliminate redundancy**: Remove duplicate logic, redundant comments, and boilerplate that adds no value.
3. **Improve readability**: Prefer clear, direct expressions over clever or terse ones.
4. **Preserve behavior**: Ensure all functionality remains identical after simplification.
5. **Maintain style**: Follow the existing code style and conventions of the file.

## What to Simplify

- Overly nested conditionals → flatten with early returns or guard clauses
- Complex chains → break into readable steps
- Unused variables, imports, or dead code → remove
- Verbose expressions → use idiomatic language constructs
- Redundant type annotations or casts → remove where inferred
- Over-abstracted helpers used only once → inline them

## Output

Show the simplified version with a brief explanation of what was changed and why.
