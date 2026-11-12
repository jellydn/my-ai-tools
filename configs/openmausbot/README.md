# OpenMausBot configs

Managed configuration for [OpenMausBot](https://github.com/milind-soni/OpenMausBot), the open-source
Grok Bot alternative chat app whose bots run local agent CLIs (Claude, Codex, Grok).

OpenMausBot keeps its application state in `~/.openmausbot`. That directory is **live runtime data**:
transcripts, attachments, paired devices, the SQLite message store, and — in non-packaged layouts —
plaintext credentials in `config.json`. This integration deliberately treats it as such.

## What is managed

Only the small, portable, non-secret files the app reads as its roster appear in this directory after
`generate.sh` runs with the opt-in export enabled:

| File                                              | Contents                                                        |
| ------------------------------------------------- | --------------------------------------------------------------- |
| `bots.json`                                       | Bot roster (id, name, description, soul, model selection)       |
| `default-bot.json`                                | Default bot mapping                                             |
| `bots/<bot-id>/SOUL.md`                           | Per-bot persona, one file per bot                               |

Run the export explicitly from a machine that has OpenMausBot:

```bash
OPENMAUSBOT_EXPORT=1 ./generate.sh
```

## What is never exported, installed, or committed

- `config.json` — onboarding state, profile, and plaintext API credentials (Composio, Workers AI, decider keys)
- `providers/` — engine credentials and sign-in state
- `messages.db`, `runtime.db` and their WAL/SHM files — message and runtime stores
- `events/`, `native/`, `attachments/`, `codex-instructions/`, `bots/<id>/history.ndjson`, `bots/<id>/data.duckdb` — transcripts and runtime state

## Install

OpenMausBot is off the default `-y` allowlist. Opt in explicitly:

```bash
./cli.sh --with-tools=openmausbot
```

`cli.sh` installs the headless `openmausbot` CLI when neither the app data directory nor the binary is
present, and copies the managed roster files above into `~/.openmausbot/` only when the app is detected.
Destination state under `~/.openmausbot` (credentials, transcripts, databases) is never modified or removed.

## Full recovery

The app's own backup is the complete recovery path: **Settings → Backups → Export full backup** produces
an encrypted, password-protected `.ombbackup` with bots, threads, attachments, memory, and routines.
Use that for backups you need to restore; the roster files here are a portable snapshot for repo sync,
not a substitute.
