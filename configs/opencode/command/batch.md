---
description: Execute multiple tasks sequentially, running /simplify on each set of changes before committing
---

Execute the following tasks as a batch operation: $ARGUMENTS

After completing each task, apply the `/simplify` three-perspective review (Code Reuse, Code Quality, Efficiency) to the changes before committing, so every step's output is reviewed and cleaned up before moving to the next.

## How to Use

Provide a newline- or semicolon-separated list of tasks:

```
/batch
Refactor auth service to use async/await
Add unit tests for the login function
Update API documentation
```

Or inline with semicolons:

```
/batch Refactor auth service; Add unit tests for login; Update API docs
```

## Process

1. **Parse the task list**: Split `$ARGUMENTS` by newlines or semicolons to get individual tasks.
2. **Plan execution order**: Identify dependencies between tasks and reorder if needed so later tasks can rely on earlier ones.
3. **For each task**:
   a. Implement the task fully.
   b. Apply the `/simplify` review — analyze the changes from the Code Reuse, Code Quality, and Efficiency perspectives and apply all findings.
   c. Commit the result before proceeding to the next task.
4. **Report progress**: After each task is committed, briefly note what was done.
5. **Summarize**: At the end, provide a concise summary of all completed tasks and any issues encountered.

## Tips

- Group related changes together to minimize context switching.
- If a task fails or is unclear, note it and continue with the remaining tasks.
- Use specific file paths and function names for precise, reproducible results.
