---
description: Open interactive annotation UI for a file, folder, or URL
---

Run `plannotator annotate $ARGUMENTS` with Bash, in the foreground, and wait for it to finish.

Relay its stdout to the user. If annotations come back, address them now. If the session closes without feedback (the output is empty, or a JSON object with `"decision": "dismissed"`), acknowledge it in one sentence and stop. Do not begin any work: closing the session is not approval. If the command reports that the arguments could not be resolved to a file, URL, or folder, work out which target the user meant and re-run it with that concrete path.

Do not ask the user to run the command themselves.
