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
- [`winget`](https://learn.microsoft.com/windows/package-manager/winget/) (App Installer) for automatic prerequisite setup

The installer handles Git for Windows (including Git Bash), `jq`, and Node.js LTS with npm. You do not need to
install them separately or open Git Bash first. WSL users can use the Linux instructions.

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

Open PowerShell and run the canonical installer:

```powershell
Invoke-RestMethod https://ai-tools.itman.fyi/install.ps1 | Invoke-Expression
```

This downloads and executes a remote script. Review [install.ps1](install.ps1) before trusting it. It installs
missing prerequisites through `winget`, reuses existing tools, refreshes PATH for the current process, and starts
the shared installer in Git Bash. Windows may request administrator approval for Git or Node.js installation.
Package installation uses `--source winget`, not the Microsoft Store. Node and npm are discovered again after
installation and passed to Git Bash in the same process; no separate prerequisite command or terminal restart
is needed after a successful install. The wrapper skips Git Bash login profiles so an older shell PATH cannot
hide these tools. Approve only the package installer's elevation prompt; the wrapper does not relaunch the full
configuration installer as administrator. If approval is denied, setup stops and can be rerun safely.
Native Windows uses Node/npm, not Bun, for package installation; Linux, macOS, and WSL keep Bun-first behavior.

The one-line command and `-y` / `--yes` install only **Amp, Pi, Codex, and OpenCode** by default. They leave
existing configuration unchanged. qmd, Plannotator, ctx, formatters, memory MCPs, plugins, skills, and the rest
of the catalog are optional. Interactive runs prompt for optional tools and the integration bundle.

From a reviewed checkout, select extra tools without enabling integrations:

```bash
./cli.sh --yes --with-tools=qmd,plannotator,ctx --dry-run
./cli.sh --yes --with-tools=qmd,plannotator,ctx
# Opt into bundled configuration, plugins, skills, MCPs and their prerequisites:
./cli.sh --yes --with-integrations --backup
```

Windows equivalents are `-WithTools 'qmd,plannotator,ctx'` and `-WithIntegrations -Backup` on a saved
`install.ps1`. Tool names are comma-separated; `./cli.sh --help` lists the catalog. The integration bundle
is a separate, explicit opt-in and can replace configuration. Selecting an extra tool alone installs its
CLI, not its MCP or plugin. Noninteractive/CI runs use the same four-tool default as `--yes`.

The installer can replace existing configuration. To inspect the script, preview changes, and request a backup,
use the saved-script path instead:

```powershell
Invoke-RestMethod https://ai-tools.itman.fyi/install.ps1 -OutFile install.ps1
Get-Content .\install.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -DryRun
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Backup
```

Execution-policy bypass applies only to that process. `-DryRun` does not install prerequisites; install them first
if the preview reports they are missing. The one-line command is non-interactive and automatically uses `--yes`.

If setup fails, resolve the reported error and rerun the same command. If a newly installed prerequisite still
cannot be found, close all terminal windows and reopen PowerShell. If `winget` is missing, install or update
[App Installer](https://aka.ms/getwinget), or install [Git for Windows](https://git-scm.com/download/win),
[`jq`](https://jqlang.org/download/), and [Node.js LTS with npm](https://nodejs.org/) manually. In Git setup,
select **Git from the command line and also from 3rd-party software**. Do not bypass package lifecycle errors
with `--ignore-scripts`: native binaries can remain uninstalled.

Optional qmd requires Node.js >=22 on native Windows. Its installer prioritizes the real `node.exe` directory
and npm's global prefix in the same Git Bash session, ahead of stale Bun launchers or extensionless Node copies
in `~/.local/bin`. Those old files are not deleted. In npm 11.19.1, unreviewed `allowScripts` entries warn but
still run unless strict policy is enabled. The installer does not change npm script policy. Review actual
build errors and approve only required packages if your policy requires it; do not enable all scripts globally.
On Windows ARM64, qmd keyword indexing/search works, but sqlite-vec currently warns that vector search is unsupported.

Optional Plannotator installs only the official v0.28.23 Windows release binary (x64 or ARM64), with a pinned
SHA-256 hash. It uses `%LOCALAPPDATA%\plannotator` and updates only the current Git Bash PATH. No remote
PowerShell script, policy bypass, persistent PATH change, sidecar, skill, or agent-settings edit is used.
The direct method avoids an upstream PowerShell `$Minimal`/`$minimal` variable collision. Failure output gives
the release URL, expected hash, and destination for manual recovery. In a separate terminal, add that directory
and npm's global prefix to your user PATH, or use full executable paths. Unix/WSL installation paths are unchanged.

If the wrapper says all prerequisites are met but Bash then reports missing Node/npm, check that the downloaded
`install.ps1` includes `Find-Node` and the `OpenJS.NodeJS.LTS` installation step. A stale web deployment can serve
an older wrapper while cloning the latest Bash installer. Maintainers must check the **Dokku Deploy** workflow
for `ai-tools.itman.fyi`; a successful **Deploy GitHub Pages** run does not update that domain. Until the domain
is updated, use a reviewed repository checkout and run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Yes
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
| `--yes` / `-y` | `-Yes` | Install only Amp, Pi, Codex, and OpenCode; leave configuration unchanged. |
| `--with-tools=qmd,plannotator` | `-WithTools 'qmd,plannotator'` | Add optional catalog CLIs without enabling integrations. |
| `--with-integrations` | `-WithIntegrations` | Opt into bundled configs, plugins, skills, MCPs, and their prerequisites. |
| `--rollback` | `-Rollback` | Restore the most recent backup. |
| `--verbose` / `-v` | `-Verbose` | Show detailed installer output. |
| `--migrate-gemini` | — | Migrate Gemini CLI configuration to Antigravity CLI. |

Non-interactive Bash and PowerShell pipelines automatically add `--yes`. This mode installs the four core CLIs
and required runtimes only. All other tools and bundled integrations need explicit opt-in. Review
[`cli.sh`](cli.sh) before using it in automation.

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

For explicit cross-project user preferences, [user-memory MCP](packages/user-memory-mcp/README.md) provides
five preference tools backed by local files. It is **optional**: the installer does not install or configure it.
The existing qmd, codebase-memory-mcp, and agentmemory integrations remain unchanged. Follow the package guide
to build, link, and register user-memory only if you need a separate explicit-preference store.
See [the memory guide](MEMORY.md) for the distinction between preferences, project knowledge, and session handoffs.

ctx's initial history indexing is optional. If provider paths cannot be inspected safely, the installer retains
the verified binary and continues with a warning. Retry with `ctx setup`; see [ctx troubleshooting](TOOL_REFERENCE.md#-ctx-optional)
for exact-path imports without bypassing its safety checks.

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

## 🎨 GitHub Coding Taste Generator

`code-taste` analyzes public GitHub repositories and generates an evidence-backed
coding preference profile. This command requires Bun and an OpenAI-compatible API
key. Tree-sitter extracts TypeScript/TSX declarations; Markdown chunks retain headings
and fenced code. See [setup and model configuration](docs/code-taste-openrouter.md).

```bash
bun install
bun run code-taste analyze jellydn/my-ai-tools
bun run code-taste analyze jellydn --repos 3 --language TypeScript
bun run code-taste export --format markdown
```

Analysis state is stored in ignored `.code-taste/`. `CODING_TASTE.md` is intentionally
not ignored so you can review and commit the resulting guidance. Markdown omits evidence;
review the evidence in `.code-taste/profile.json` or the JSON export before treating
inferred preferences as project rules.

## 📚 Documentation

HTML pages in [`docs/`](docs/index.html) are generated from the Markdown sources. Regenerate them with `bun scripts/render-docs.ts`.

- [Documentation website](https://ai-tools.itman.fyi)
- [Detailed tool and skill reference](TOOL_REFERENCE.md)
- [Fusion orchestration](docs/fusion-orchestration.md)
- [Claude Code agent teams](docs/claude-code-teams.md)
- [30-day applied AI learning sprint](docs/30-day-applied-ai-learnings.md)
- [qmd knowledge management](docs/qmd-knowledge-management.md)
- [My AI Bot](docs/my-ai-bot.md)
- [Public repository knowledge base](docs/rag-architecture.md)
- [Retrieval evaluation](docs/rag-retrieval-quality.md)
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
