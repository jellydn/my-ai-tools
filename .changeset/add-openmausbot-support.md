---
"my-ai-tools": minor
---

Add OpenMausBot as an optional supported tool: headless CLI installation, opt-in
portable roster export (bots.json, default-bot.json, per-bot SOUL.md) behind
`OPENMAUSBOT_EXPORT=1`, and config install into `~/.openmausbot` when the app is
detected. Off the default `-y` allowlist. Credentials, transcripts, attachments,
and databases are never installed, exported, or committed; full recovery stays
with the app's encrypted Settings → Backups export.
