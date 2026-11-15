---
"my-ai-tools": minor
---

Add OpenMausBot as an optional supported tool: headless CLI installation (Node.js
24+) and opt-in roster export (`bots.json`, `default-bot.json`) behind
`OPENMAUSBOT_EXPORT=1`. Off the default `-y` allowlist. The exported roster holds
personas, project paths, and account emails, so it is gitignored and never
committed. The installer never writes to the app data directory; full recovery
stays with the app's encrypted Settings → Import & export backup.
