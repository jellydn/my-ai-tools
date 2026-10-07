# Welcome to my-ai-tools 👋

[![Tests](https://github.com/jellydn/my-ai-tools/actions/workflows/test.yml/badge.svg)](https://github.com/jellydn/my-ai-tools/actions/workflows/test.yml)
[![GitHub stars](https://img.shields.io/github/stars/jellydn/my-ai-tools)](https://github.com/jellydn/my-ai-tools/stargazers)
[![GitHub license](https://img.shields.io/github/license/jellydn/my-ai-tools)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

> Portable, source-controlled configuration for AI coding assistants.

`my-ai-tools` installs one consistent set of agent guidelines, skills, commands, hooks, MCP servers, and tool
settings across supported AI coding assistants. It can also export local configuration changes back into this
repository.

📖 [Documentation website](https://ai-tools.itman.fyi) · 🎬 [Setup video](https://www.youtube.com/watch?v=ESudSFAyuuw)

## ✨ Features

- Configures Claude Code, OpenCode, Amp, Codex, Cursor, Pi, Antigravity, and many other assistants.
- Shares reusable skills, agent guidance, commands, hooks, and MCP server definitions.
- Supports macOS, Linux, Windows 11 with PowerShell and Git Bash, and WSL.
- Provides side-effect-free dry runs and optional backups before installation.
- Exports installed configurations back to the repository for bidirectional sync.
- Validates JSON and other supported configuration files before installation.

## 📋 Requirements

### macOS, Linux, and WSL

- Bash 3.0 or later
- Git
- `curl` for the one-line installer
- Bun or Node.js LTS for JavaScript-based tools

### Windows 11

- Windows PowerShell 5.1 or PowerShell 7
- [Git for Windows](https://git-scm.com/download/win), including Git Bash
- [`winget`](https://learn.microsoft.com/windows/package-manager/winget/) to install `jq` automatically, or a
  manual [`jq` installation](https://jqlang.org/download/)
- Bun or Node.js LTS for JavaScript-based tools

During Git for Windows setup, select **Git from the command line and also from 3rd-party software**. The native
Windows installer uses PowerShell for setup and Git Bash to run the shared Bash installer. WSL remains supported
and can use the Linux instructions.

## 🚀 Installation

The installer can replace existing configuration files. Run a dry run first and use `--backup` or `-Backup` when
you want a restorable copy.

### macOS, Linux, and WSL

Review the installer, then run it:

```bash
curl -fsSL https://ai-tools.itman.fyi/install.sh -o install.sh
less install.sh
bash install.sh --dry-run
bash install.sh --backup
```

For a direct one-line installation:

```bash
curl -fsSL https://ai-tools.itman.fyi/install.sh | bash
```

### Windows 11

Open PowerShell and review the installer before execution:

```powershell
Invoke-RestMethod https://ai-tools.itman.fyi/install.ps1 -OutFile install.ps1
Get-Content .\install.ps1
.\install.ps1 -DryRun
.\install.ps1 -Backup
```

If the PowerShell execution policy blocks the saved script, run it for this process only:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -DryRun
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Backup
```

The PowerShell installer detects Git Bash, installs `jq` with `winget` when needed, and forwards options to
`cli.sh`. When run from a repository checkout, it uses that checkout. When downloaded by itself or piped to
PowerShell, it clones the latest repository into a temporary directory.

For a direct one-line installation:

```powershell
Invoke-RestMethod https://ai-tools.itman.fyi/install.ps1 | Invoke-Expression
```

### Repository checkout

```bash
git clone https://github.com/jellydn/my-ai-tools.git
cd my-ai-tools
./cli.sh --dry-run
./cli.sh --backup
```

On Windows PowerShell, use the native wrapper from the checkout:

```powershell
git clone https://github.com/jellydn/my-ai-tools.git
Set-Location my-ai-tools
.\install.ps1 -DryRun
.\install.ps1 -Backup
```

## ⚙️ Installer options

| Bash option | PowerShell option | Purpose |
| --- | --- | --- |
| `--dry-run` | `-DryRun` | Show planned changes without applying them. |
| `--backup` | `-Backup` | Back up existing files before installation. |
| `--no-backup` | `-NoBackup` | Skip the interactive backup prompt. |
| `--yes` / `-y` | `-Yes` | Run non-interactively for the active-tool allowlist. |
| `--rollback` | `-Rollback` | Restore the most recent backup. |
| `--verbose` / `-v` | `-Verbose` | Show detailed installer output. |
| `--migrate-gemini` | — | Migrate Gemini CLI configuration to Antigravity CLI. |

Non-interactive Bash and PowerShell pipelines automatically add `--yes`. This mode installs dependencies and
processes only the active tool allowlist. Review [`cli.sh`](cli.sh) before using it in automation.

## 🤖 Supported tools

The repository currently contains configuration or integration support for:

| Category | Tools |
| --- | --- |
| Primary assistants | Claude Code, OpenCode, Amp, Codex, Cursor, Pi, Oh My Pi, Antigravity, Kilo, Kimi Code, Muse Code |
| Additional CLIs | CommandCode, GitHub Copilot CLI, Gemini CLI, Grok CLI, MiMo-Code, Qoder CLI, DeepSeek Harness, Kiro CLI, Devin CLI, Factory Droid, Cline, Reasonix |
| Workflow and desktop tools | Conductor, Delta, Codiff, Hunk, ctx, herdr, Orca, AI Launcher, CCS, fx, Open Code Review |

Some installers are platform-specific, and optional tools are skipped when they are not detected. Gemini CLI is
deprecated for Google One and unpaid tiers; use the `--migrate-gemini` option to move its configuration to
Antigravity CLI.

See [`configs/`](configs/) for the source configuration of each tool and [`skills/`](skills/) for shared skills.

## 🔌 Shared configuration

The installer manages these common resources where the target tool supports them:

- Agent guidance and software-development practices
- Reusable skills and commands
- Lifecycle and safety hooks
- Tool-specific settings, themes, and provider configuration
- MCP servers from [`configs/mcp-registry.json`](configs/mcp-registry.json)

The MCP registry includes integrations such as Context7, sequential thinking, qmd, codebase memory, agent memory,
fff, React Grab, logpilot, sem, and ctx. Installation depends on each server's runtime and credentials.

Do not commit secrets. Keep API keys in environment variables or the target tool's credential store. Review
`.env.example` for server-side environment variable names used by this repository.

## 🔄 Export local changes

`generate.sh` copies supported configuration from your home directory back into the repository. Preview the
operation first:

```bash
./generate.sh --dry-run
./generate.sh
git diff
```

Review the diff before committing. Generated configuration can contain machine-specific values or credentials that
must not enter version control.

## 🧭 Common workflows

### Restore a backup

```bash
./cli.sh --rollback
```

```powershell
.\install.ps1 -Rollback
```

Backups are stored in `~/ai-tools-backup-<timestamp>`, and the installer keeps the five most recent backups.

### Migrate Gemini CLI to Antigravity CLI

```bash
./cli.sh --migrate-gemini
```

### Validate a contribution

```bash
bash -n cli.sh generate.sh install.sh lib/*.sh scripts/*.sh
./cli.sh --dry-run
./scripts/sync-token-efficiency.sh --check
bats tests/
biome check .
```

See [`TESTING.md`](TESTING.md) for focused test commands and [`CONTRIBUTING.md`](CONTRIBUTING.md) for repository
conventions.

## 📚 Documentation

HTML pages in [`docs/`](docs/index.html) are generated from the Markdown sources. Regenerate them with `bun scripts/render-docs.ts`.

- [Documentation website](https://ai-tools.itman.fyi)
- [Detailed tool and skill reference](TOOL_REFERENCE.md)
- [Fusion orchestration](docs/fusion-orchestration.md)
- [Claude Code agent teams](docs/claude-code-teams.md)
- [30-day applied AI learning sprint](docs/30-day-applied-ai-learnings.md)
- [qmd knowledge management](docs/qmd-knowledge-management.md)
- [My AI Bot](docs/my-ai-bot.md)
- [Applied AI and GenAI cheat sheet](docs/ai-applied-genai-cheat-sheet.md)
- [Testing guide](TESTING.md)

## 🤝 Contributing

Contributions, issues, and feature requests are welcome. Read [`CONTRIBUTING.md`](CONTRIBUTING.md), run the relevant
checks, and open an issue before a large behavior or configuration change.

## 📜 License

This project is available under the [MIT License](LICENSE).

## 👤 Author

**Dung Huynh**

- Website: [productsway.com](https://productsway.com/)
- YouTube: [IT Man Channel](https://www.youtube.com/@it-man)
- X: [@jellydn](https://twitter.com/jellydn)
- GitHub: [@jellydn](https://github.com/jellydn)

## ⭐ Show your support

Give this project a ⭐️ if it helps you.

[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support-ff5e5b?logo=ko-fi&logoColor=white)](https://ko-fi.com/dunghd)
[![PayPal](https://img.shields.io/badge/PayPal-Support-00457C?logo=paypal&logoColor=white)](https://paypal.me/dunghd)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy_Me_a_Coffee-Support-FFDD00?logo=buymeacoffee&logoColor=000000)](https://www.buymeacoffee.com/dunghd)
