# OpenMausBot configs

Managed configuration for [OpenMausBot](https://github.com/milind-soni/OpenMausBot), the open-source
Grok Bot alternative chat app whose bots run local agent CLIs (Claude, Codex, Grok).

OpenMausBot keeps its application state in its data directory (`$OMB_DATA_DIR`, or `~/.openmausbot`
by default). That directory is **live runtime data**: transcripts, attachments, paired devices, the
SQLite message store, and — in non-packaged layouts — plaintext credentials in `config.json`. This
integration deliberately treats it as such.

## What is managed

Only the small, portable, non-secret files the app reads as its roster appear in this directory after
`generate.sh` runs with the opt-in export enabled:

| File               | Contents                                                 |
| ------------------ | -------------------------------------------------------- |
| `bots.json`        | Bot roster (id, name, description, soul, model selection) |
| `default-bot.json` | Default bot mapping (the account email ledger)           |

`bots/<bot-id>/SOUL.md` is deliberately **not** managed: upstream treats it as a mirror of the
`soul` field in `bots.json` and regenerates it on every save, so a repository copy could only ever
add drift.

Run the export explicitly from a machine that has OpenMausBot:

```bash
OPENMAUSBOT_EXPORT=1 ./generate.sh
```

## The export is local-only

`bots.json` and `default-bot.json` carry personas, absolute project paths, and account email
addresses. This repository is public, so the exported snapshot is **gitignored**
(`configs/openmausbot/*.json` and `configs/openmausbot/bots/`) and must never be committed. Treat it
as a local snapshot for your own machines, not a shared artifact.

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

The installer installs the headless `openmausbot` CLI when it is not on PATH, and copies the managed
roster files into `~/.openmausbot/import/` when the app data directory exists. The two are checked
independently: the CLI on PATH does not mean the app is installed, and the data directory does not
mean the CLI is installed.

`bots.json` and `default-bot.json` are **app-owned** — the server rewrites them on every roster
change. The repository snapshot is therefore written to `~/.openmausbot/import/` (owner-only,
`0600`) and the live registry is never replaced; apply the snapshot from the app when you want it.
Destination state under the data directory (credentials, transcripts, databases) is never modified or
removed.

## Full recovery

The app's own backup is the complete recovery path: **Settings → Backups → Export full backup** produces
an encrypted, password-protected `.ombbackup` with bots, threads, attachments, memory, and routines.
Use that for backups you need to restore; the roster files here are a local snapshot, not a
substitute.
