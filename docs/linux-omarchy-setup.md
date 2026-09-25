# Selective Setup on Omarchy (Linux, Hyprland)

A tested walkthrough for applying these AI-tool configurations to a Linux
desktop that already runs its own set of CLIs — specifically **Omarchy**
(Arch Linux ARM, Hyprland). The installer is desktop-agnostic, but a few
Linux-specific details are worth knowing before you run `cli.sh`.

## What

- Run the installer non-interactively with the active tool set and config
  backups:
  `bash cli.sh --yes --backup`.
- Install and configure the allowlisted tools: `claude`, `codex`, `ctx`,
  `delta`, `fx`, `kilo`, `muse`, `amp`, `opencode`, `open_code_review`, `pi`,
  `omp` (Oh My Pi), `antigravity`, `ai-switcher`, `reasonix`, plus the
  always-run shared infra (`rtk`, `global_tools`, `ccs`).
- Copy managed configs into `~/.claude/`, `~/.config/opencode/`, `~/.codex/`,
  `~/.fx/`, `~/.amp/`, `~/.config/pi/`, etc.
- Install MCP servers (context7, sequential-thinking, qmd,
  codebase-memory-mcp, agentmemory, sem, ctx) into the tools that support them.
- Install shared skills into `~/.agents/skills`.

Existing configs are **backed up** to `~/ai-tools-backup-<timestamp>/`
(`--backup`), never deleted.

## Why

- `./cli.sh --yes` non-interactive mode is the right fit when you know you
  want the active tool set; it also auto-accepts the backup step without
  prompting.
- `--backup` is especially valuable on a machine that already has configs: the
  first run replaced an existing `~/.config/opencode/` (with `opencode.json`,
  `tui.json`, a `node_modules/`, and an `opencode.json.tui-migration.bak`) and
  an existing Claude Code `themes/` directory. Both were preserved intact at
  `~/ai-tools-backup-20260915-104034/` so nothing was lost.
- Tool installers write their CLIs in different places depending on the
  platform; on this Linux box they landed in `~/.local/bin` and under mise
  install dirs (`~/.local/share/mise/installs/<tool>/latest/bin`). Those paths
  must be on `PATH` for the CLIs to resolve.
- Tools not in the allowlist (kimi_code, gemini, commandcode, copilot,
  conductor, herdr) are skipped cleanly in `-y` mode rather than attempted.

## How

### 1. Prerequisites

```bash
# Arch / Omarchy
sudo pacman -S --noconfirm git
# A script runner for the installers (bunx preferred, npx fallback)
curl -fsSL https://bun.sh/install | bash
npm install -g bun  # or use npx; the installer detects it automatically
```

Free disk space first if your root partition is small — see Troubleshooting.

### 2. Clone and run

```bash
git clone https://github.com/jellydn/my-ai-tools.git
cd my-ai-tools
bash cli.sh --yes --backup
```

`cli.sh` and `generate.sh` are bash-only; the bundled `lib/require_bash.sh`
re-launches under bash transparently if invoked via `sh`.

### 3. Verify the results

```bash
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/installs/node/latest/bin:$PATH"

claude --version    # Claude Code
codex --version     # OpenAI Codex
amp --version       # Amp
fx                   # Vercel Labs fx
muse
kilo              # Kilo CLI
ctx               # ctx
agy               # Antigravity CLI
ai                # ai-switcher (binary is `ai`)

# Managed skills (fx, Muse, agents share this directory)
ls ~/.agents/skills
# MCP server report printed at end of install
# backups
ls ~/ai-tools-backup-*/
```

### 4. Restart your shell

Installed CLIs land in `~/.local/bin` and mise install dirs. If the terminal
was already open:

```bash
exec bash        # or: exec zsh / exec fish
hash -r
```

On fish shells the Antigravity CLI installer appends a `set -gx PATH
"$HOME/.local/bin" $PATH` line to `~/.config/fish/config.fish`; a sourced
shell sees the new tools without restart.

## What was skipped on this machine

```text
cursor       -> Cursor not detected (no Cursor install on this machine)
kimi_code    -> not in -y allowlist
gemini       -> not in -y allowlist
commandcode  -> not in -y allowlist
copilot      -> not in -y allowlist
conductor    -> not in -y allowlist
herdr        -> not in -y allowlist
plannotator  -> aarch64: installer has no checksum URL and download failed
```

All other skipped tools simply printed `Skipped: <tool>` without interrupting
the run.

## Verification on this machine

```text
Claude MCP servers:   Installed 7 | Skipped 3 | Failed 0
Shared skills:        33 entries under ~/.agents/skills
Backup dir:           ~/ai-tools-backup-20260915-104034/
                        claude/themes  codex/  opencode/  pi/
```

## Troubleshooting

- **`No space left on device` mid-install** — this 24 GB root partition filled
  up during the run; the failing copy aborted the last config step. Freed by
  clearing caches and re-running:
  ```bash
  npm cache clean --force
  rm -rf ~/.cache/* ~/.npm/_cacache
  rm -rf ~/.claude/tmp/*
  df -h /          # confirm headroom
  bash cli.sh --yes --no-backup   # idempotent re-run finishes the job
  ```
- **`claude` not found after install** — a disk-full write during `-y` install
  left the global npm bin partial. Re-install:
  ```bash
  npm install -g @anthropic-ai/claude-code
  ```
- **CLIs installed but not on `PATH`** — new tools go to `~/.local/bin` and
  mise install dirs. Ensure those are on `PATH`, then `exec bash` (or
  `mise reshim` if using mise shims).
- **Plugins print `install failed (may already be installed)`** — harmless on
  re-runs; the plugin exists from the previous run.
- **`cli.sh` complains bash is not found** — the guard in `lib/require_bash.sh`
  is executed via `#!/bin/bash`; run the script with `bash cli.sh` explicitly.