# OpenMausBot configs

Managed configuration for [OpenMausBot](https://github.com/milind-soni/OpenMausBot), the open-source
Grok Bot alternative chat app whose bots run local agent CLIs (Claude, Codex, Grok).

OpenMausBot keeps its application state in its data directory (`$OMB_DATA_DIR`, or `~/.openmausbot`
by default). That directory is **live runtime data**: transcripts, attachments, paired devices, the
SQLite message store, and — in non-packaged layouts — plaintext credentials in `config.json`. This
integration deliberately treats it as such.

## What is managed

Only the small, portable roster files appear in this directory, and only after `generate.sh` runs with
the opt-in export enabled:

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

OpenMausBot is off the default `-y` allowlist. An interactive run asks before it installs each optional
tool, so answer yes for OpenMausBot:

```bash
./cli.sh --with-tools=openmausbot
```

For an unattended run, add `-y`. Note that `-y` also installs the default allowlisted tools:

```bash
./cli.sh -y --with-tools=openmausbot
```

The installer installs the headless `openmausbot` CLI when it is not on PATH. The npm package requires
Node.js 24 or newer, so the installer stops with an error on an older Node.js. It prints the download
link for the desktop app and never writes to the app data directory.

## Restore

The exported roster is a reference snapshot: the app does not read it, and the installer does not apply
it. The app reads its live registry only from `bots.json` in the data directory and rewrites that file on
every roster change.

To back up and restore everything (bots, threads, attachments, memory, and routines), use the app:
**Settings → Import & export → Export full backup** writes an encrypted, password-protected
`.ombbackup` file, and **Settings → Import & export → Import backup** restores it. See the
[upstream data and backups guide](https://github.com/milind-soni/OpenMausBot/blob/main/apps/docs/content/docs/self-hosting/data-and-backups.mdx).
