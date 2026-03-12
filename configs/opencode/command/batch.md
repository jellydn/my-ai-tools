---
description: Run multiple tasks in sequence as a batch operation
---

Execute the following tasks as a batch operation: $ARGUMENTS

## How to Use

Provide a newline- or semicolon-separated list of tasks to execute in order:

```
/batch
Fix lint errors in src/auth.ts
Add unit tests for the login function
Update the README with the new auth flow
```

Or pass tasks inline as a semicolon-separated list:

```
/batch Fix lint errors in auth.ts; Add tests for login; Update README
```

## Process

1. **Parse the task list**: Split `$ARGUMENTS` by newlines or semicolons to get individual tasks.
2. **Plan execution order**: Identify dependencies between tasks and reorder if needed so later tasks can rely on earlier ones.
3. **Execute sequentially**: Work through each task one at a time, completing it fully before moving to the next.
4. **Report progress**: After each task, briefly note what was done before proceeding.
5. **Summarize**: At the end, provide a concise summary of all completed tasks and any issues encountered.

## Tips

- Group related changes together to minimize context switching.
- If a task fails or is unclear, note it and continue with the remaining tasks.
- Use specific file paths and function names for precise, reproducible results.
