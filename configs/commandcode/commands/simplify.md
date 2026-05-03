---
description: Review recently modified code from three perspectives (Code Reuse, Code Quality, Efficiency) and apply all findings
---

Review the recently modified code ($ARGUMENTS or `git diff --name-only` if no argument is given) from three distinct perspectives, then apply all actionable findings.

## Three Review Perspectives

### 1. Code Reuse
Look for logic duplicated across two or more places, redundant patterns, or helper functions that already exist but were re-implemented.

### 2. Code Quality
Look for readability problems, confusing names, deeply nested blocks, long functions, and style inconsistencies.

### 3. Efficiency
Look for performance bottlenecks, N+1 queries, redundant loops, and unnecessary computation.

## Process
1. Identify target files from $ARGUMENTS or `git diff --name-only`
2. Apply all three lenses before editing
3. Apply fixes surgically, preserving functionality
4. Verify the code still builds
