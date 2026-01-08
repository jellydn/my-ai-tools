---
description: Delegate task with intelligent profile selection [AUTO ENHANCE]
argument-hint: [task description]
---

Activate `ccs-delegation` skill. The skill contains all execution logic.

Task: Parse `$ARGUMENTS`, select optimal profile from `~/.ccs/config.json`, enhance prompt, execute delegation via CCS CLI.

**Examples:**
```
/ccs "refactor auth.js to use async/await"    # Simple task
/ccs "analyze entire architecture"            # Long-context task
/ccs "think about caching strategy"           # Reasoning task
/ccs --glm "add tests for UserService"        # Force specific profile
/ccs "/cook create landing page"              # Nested slash command
```
