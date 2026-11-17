---
description: Open interactive code review for current changes, a directory, or a PR URL; pass --git or --gitbutler to force that provider, --base <ref> / --diff-type <type> to pin the session's opening diff (session-only, git-only)
---

Run `plannotator review $ARGUMENTS` with Bash, in the foreground, and wait for it to finish.

Relay its stdout to the user. If it returns feedback or annotations, address them now. If it returns an approval, say the review passed and continue. If the session closes without feedback (the output is "Review session closed without feedback." or empty), acknowledge it in one sentence and stop. Do not begin any work: closing the session is not approval.

Do not ask the user to run the command themselves.
