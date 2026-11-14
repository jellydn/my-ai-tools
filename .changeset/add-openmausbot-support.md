---
"my-ai-tools": minor
---

Add OpenMausBot as an optional supported tool: headless CLI installation, opt-in
roster export (`bots.json`, `default-bot.json`) behind `OPENMAUSBOT_EXPORT=1`, and
config install into `~/.openmausbot/import/` when the app data directory is
detected. Off the default `-y` allowlist. The exported roster holds personas,
project paths, and account emails, so it is gitignored and never committed. The
app's live registry, credentials, transcripts, attachments, and databases are
never installed, exported, or replaced; full recovery stays with the app's
encrypted Settings → Backups export.
