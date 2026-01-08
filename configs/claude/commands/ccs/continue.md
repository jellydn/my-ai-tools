---
description: Continue last CCS delegation session [AUTO ENHANCE]
argument-hint: [follow-up instruction]
---

Activate `ccs-delegation` skill. The skill contains all execution logic.

Task: Detect last-used profile from `~/.ccs/delegation-sessions.json`, parse `$ARGUMENTS`, enhance with previous context, execute continuation via CCS CLI.

**Examples:**
```
/ccs:continue "also update the examples section"  # Use last profile
/ccs:continue --glm "add unit tests"              # Switch profiles
/ccs:continue "/commit with message"              # Nested slash command
```
