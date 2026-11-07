---
"my-ai-tools": patch
---

Ship the self-hosted smolvm orb dispatcher and setup runbook, export the dispatcher from generate.sh, allow cleanup when the host workspace is missing, and recover wedged machines (missing checkpoints, duplicate-controller create races) by discarding and recreating them.
