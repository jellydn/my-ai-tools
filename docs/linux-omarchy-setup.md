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
  `~/.fx/`, `~/.config/amp/`, `~/.pi/agent/`, etc.
- Install MCP servers (context7, sequential-thinking, qmd,
  codebase-memory-mcp, agentmemory, sem, ctx) into the tools that support them.
- Install shared skills into `~/.agents/skills`.

Managed configs are **backed up** to `~/ai-tools-backup-<timestamp>/`
with `--backup`. These are filtered configuration backups, not full-directory
snapshots. Runtime data such as `node_modules`, caches, and databases is excluded.
The installer keeps the last five backups.

## Why

- `./cli.sh --yes` non-interactive mode is the right fit when you know you
  want the active tool set; it also auto-accepts the backup step without
  prompting.
- `--backup` is especially valuable on a machine that already has configs.
  Check the backup contents before you rely on them. Make a separate full backup
  if you also need runtime data or files excluded by `safe_copy_dir`.
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
export PATH="${BUN_INSTALL:-$HOME/.bun}/bin:$PATH"
bun --version
```

If Node.js and `npx` are already available, you can use them instead of installing Bun.
Free disk space first if your root partition is small — see Troubleshooting.

### 2. Clone and run

```bash
git clone https://github.com/jellydn/my-ai-tools.git
cd my-ai-tools
bash cli.sh --dry-run
```

Inspect the plan before starting the installation:

```bash
bash cli.sh --yes --backup
```

`cli.sh` and `generate.sh` are bash-only; the bundled `lib/require_bash.sh`
re-launches under bash transparently if invoked via `sh`.

### 3. Verify the results

```bash
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/installs/node/latest/bin:$PATH"
if command -v bun >/dev/null 2>&1; then
  export PATH="$(bun pm bin -g):$PATH"
fi

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
  up during the run; the failing copy aborted the last config step. Inspect disk
  usage and remove only disposable files you have checked. Do not delete entire
  cache or temporary directories blindly: other tools can keep active state there.
  ```bash
  du -sh ~/.cache ~/.npm ~/.claude/tmp 2>/dev/null
  df -h /          # confirm headroom
  bash cli.sh --dry-run
  ```
  After freeing space, inspect the plan and confirm that your backup is usable:
  ```bash
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
- **Plugins print `install failed (may already be installed)`** — this can be a
  real failure, not only an existing installation. Check that the target CLI is
  available, inspect its installed plugins, and read the original error before
  retrying.
- **`cli.sh` complains bash is not found** — the guard in `lib/require_bash.sh`
  is executed via `#!/bin/bash`; run the script with `bash cli.sh` explicitly.
