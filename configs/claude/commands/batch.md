---
description: Execute multiple independent tasks in parallel using subagents
argument-hint: [task 1; task 2; task 3 ...]
---

Execute the tasks listed in $ARGUMENTS in parallel using subagents, then consolidate and report the results.

## How to pass tasks

Separate each task with a semicolon (`;`) or a newline. Example:

```
/batch Add JSDoc to auth.ts; Write unit tests for utils.ts; Update README with new API endpoints
```

## Process

1. **Parse tasks** – Split `$ARGUMENTS` on `;` or newlines to get the individual task list. Number them for clear tracking.
2. **Validate** – Confirm the list makes sense. If any tasks are ambiguous, ask all clarifying questions upfront before proceeding.
3. **Execute in parallel** – Spawn one subagent per task. Each subagent:
   - Receives only its own task description
   - Works independently without sharing state with other subagents
   - Reports its outcome (success / failure / changes made)
4. **Consolidate results** – After all subagents finish, display a summary table:

   | # | Task | Status | Notes |
   |---|------|--------|-------|
   | 1 | … | ✅ Done | … |
   | 2 | … | ⚠️ Partial | … |
   | 3 | … | ❌ Failed | … |

5. **Handle failures** – For any failed or partial task, explain what went wrong and suggest next steps.

## Constraints

- Tasks must be **independent** – if task B depends on the output of task A, run them sequentially instead.
- Keep each task description concise and self-contained so subagents have clear scope.
- Maximum recommended batch size: **10 tasks** per invocation to avoid context overflow.
