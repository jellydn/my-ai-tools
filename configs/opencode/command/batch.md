---
description: Execute multiple independent tasks in a single batch operation
argument-hint: [task1 | task2 | task3 ...]
---

## Task

Execute all tasks provided in `$ARGUMENTS` as a batch. Tasks are separated by `|`.

If no arguments are provided, ask the user to list the tasks they want to run in batch.

## Process

1. **Parse tasks**: Split `$ARGUMENTS` by `|` to get individual tasks.
2. **Execute independently**: Treat each task as a self-contained unit. Run all tasks sequentially, clearly labeling each result.
3. **Report results**: After completing all tasks, provide a consolidated summary showing the outcome of each task.

## Examples

```
/batch add error handling to auth.ts | add tests for user.ts | update README with new API docs
/batch refactor login function | fix typo in header.tsx | remove unused imports in utils.ts
```

## Output Format

For each task, display:

```
### Task 1: <task description>
<result>

### Task 2: <task description>
<result>

...

### Summary
<brief summary of all completed tasks>
```
