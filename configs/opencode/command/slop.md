---
description: Remove AI code slop from branch
agent: build
---

Check the diff against $ARGUMENTS, and remove all AI generated slop introduced in this branch.

Usage: /slop [branch-name]
- If no branch is provided, compare against main by using: /slop main

This includes:
- Extra comments that a human wouldn't add or is inconsistent with the rest of the file
- Extra defensive checks or try/catch blocks that are abnormal for that area of the codebase (especially if called by trusted / validated codepaths)
- Casts to any to get around type issues
- Any other style that is inconsistent with the file
