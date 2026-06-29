---
name: simplify
description: Review recently modified code from three perspectives (Code Reuse, Code Quality, Efficiency) and apply all findings
license: MIT
compatibility: claude, opencode, amp, codex, gemini, cursor, pi, cline
hint: Use when reviewing recent changes across the codebase for cleanup, refactoring, or quality improvements
user-invocable: true
metadata:
  audience: all
  workflow: code-quality
---

# Code Simplify Review

Review recently modified code from three distinct perspectives, then apply all actionable findings.

## Usage

```bash
/simplify [FILES...]    # Review specific files
/simplify               # Review all recently changed files
```

## Three Review Perspectives

### Code Reuse
Look for logic duplicated across two or more places, redundant patterns, or helper functions that already exist but were re-implemented.

### Code Quality
Look for readability problems, confusing names, deeply nested blocks, long functions, and style inconsistencies.

### Efficiency
Look for performance bottlenecks, N+1 queries, redundant loops, and unnecessary computation.

## Process

1. Identify target files from `$ARGUMENTS` or `git diff --name-only`
2. Apply all three lenses before editing
3. Apply fixes surgically, preserving functionality
4. Verify the code still builds
