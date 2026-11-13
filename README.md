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

The one-line command and `-y` / `--yes` use these default categories:

- **Default tools:** Amp, Pi, Codex, OpenCode, Claude Code, Grok, qmd, rtk, ctx, open-cursor, ai-switcher, open_code_review, and Plannotator.
- **Shared skills:** bundled local skills, installed for the selected agents.
- **Applicable MCP/plugin configuration:** bundled configuration for the selected agents. The three memory
  MCP choices (qmd, codebase-memory-mcp, agentmemory) remain available; `user-memory` stays opt-in.
- **Optional standalone catalog:** remaining CLIs, formatters, and tools need selection. Interactive runs
  prompt for them; automation can use `--with-tools`.

qmd, ctx, and Plannotator are also logged as integration dependencies of the core agent templates.
ctx installation in `-y` mode does not import history, start its daemon, install upstream skills, or change
persistent Windows PATH. Other MCP commands keep their existing external prerequisites. No unrelated agent's
plugin or skill directory is configured in yes mode.

From a reviewed checkout, select extra tools without enabling integrations:

```bash
./cli.sh --yes --without-integrations --with-tools=fx,cursor --dry-run
./cli.sh --yes --without-integrations --with-tools=fx,cursor
# Default configuration, plugins, shared skills and MCPs (can replace existing config):
./cli.sh --yes --backup
```

Windows equivalents are `-WithoutIntegrations -WithTools 'fx,cursor'` and `-Yes -Backup` on a saved
`install.ps1`. Tool names are comma-separated; `./cli.sh --help` lists the catalog. `--without-integrations`
(`-WithoutIntegrations`) installs standalone CLIs only and leaves existing configuration unchanged.
`--with-integrations` remains accepted but is now the default. Selecting an extra tool does not select
another agent's configuration. Noninteractive/CI runs use the same default categories as `--yes`.

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

Claude is skipped only when `claude --version` succeeds with nonempty output. A broken shim (including a
missing native binary) is repaired even with `--yes`, then checked again. npm installs for Claude and OpenCode
explicitly include optional platform packages and enable lifecycle scripts for that command only; Claude
repair also uses `--force`. When npm supports script approval, Claude installation adds
`--allow-scripts=@anthropic-ai/claude-code` to permit only that package's lifecycle scripts for that invocation.
Older npm versions without this setting omit the flag. These options do not change user/global npm settings
or approve scripts for other packages. Installation still fails if the final `claude --version` check fails.
If OpenCode postinstall reports `ECONNRESET`, its platform download failed; the log alone does not identify
the network cause. Check registry connectivity and your network/proxy policy, then retry
`npm install -g @opencode/cli --include=optional --ignore-scripts=false`, verify `opencode --version`, and rerun
setup. Optional catalog tools, including OpenCode 2, AI Launcher (`ai-switcher`), and Pi, warn and continue
after installation or verification fails. Setup lists failed/skipped optional components at the end and
skips their configurations for that run. Rerun setup to retry them. Claude, Amp, Codex, prerequisite checks,
and required integration dependencies (including qmd, ctx, and Plannotator) still fail setup with a nonzero
exit code. Optional failure does not mean that tool was installed successfully.

AI Launcher reports success only after its installer succeeds and `ai --version` returns nonempty output
successfully. On native Windows, setup downloads the official release directly instead of executing the
upstream installer, which has no download retries and writes directly to the installed binary. The new
release is staged beside the destination, checked against the release's SHA-256 checksum, and run with
`--version` before it replaces `ai.exe`. Failed downloads, checksum checks, or staged health checks preserve
the existing binary. A missing Windows architecture asset is reported, not substituted with another build.

Shared installer downloads make at most three GET attempts for curl connection/partial-transfer/timeout/
empty-response/receive errors (7, 18, 28, 52, 56), with 1-second then 2-second waits. Curl 35 retries only
when that attempt's stderr matches `connection (was )?reset`, ignoring case. Generic TLS handshake errors,
HTTP errors, and TLS certificate failures do not retry. Earlier attempts and stdout cannot enable a retry.
Each attempt has a 15-second connection limit and 120-second transfer limit. Persistent TLS resets stop
after three attempts; retries do not identify the cause or repair certificate, protocol, or proxy problems.
TLS verification remains enabled on every attempt.
Partial files are restarted, not appended; checksum verification still applies. Downloaded scripts
and npm installs are never automatically replayed. This can recover a transient interruption, not repair
a persistent network problem. Unix/WSL AI Launcher installation still uses the upstream installer.

#### Windows recovery: Pi and persistent download resets

npm already retries eligible registry reads (default `fetch-retries=2`, delays of 10 to 60 seconds, and a
5-minute per-request timeout). Local settings can differ. Setup does not add an outer Pi install retry or
change user/global npm settings. Check the configured registry and effective retry count first:

```powershell copy Copy Registry Checks
node --version
npm --version
npm config get registry
npm config get fetch-retries
npm ping
```

`npm ping` tests registry metadata access only, not every package tarball or GitHub release download.
Pi's `EPERM` cleanup warnings do not establish why Windows refused a removal. Save the npm debug log,
close any Pi process you started, and use Resource Monitor or Process Explorer to check the exact failing
path for an open handle. Check that directory's permissions if no handle is found. Do not stop all Node
processes, run blanket deletion/cache cleanup, disable TLS checks, or use administrator mode as a workaround.
After network access and any confirmed file-access problem are resolved, retry once from PowerShell:

```powershell copy Copy Pi Recovery
npm install -g @earendil-works/pi-coding-agent --loglevel=http --timing
pi --version
```

Run the health check even if npm reports success. If failures persist, share the **redacted npm debug log**
with failed URL host/path, HTTP status or socket error, attempt counts, timestamps, and Node/npm versions.
For AI Launcher, include Git Bash's `curl --version` and a redacted verbose trace of the failing release
asset GET, including redirects and response headers. Say whether a proxy/VPN is in use and whether another
approved network reproduces it. Remove tokens, cookies, proxy credentials, and signed URL query strings.
For `EPERM`, include the exact affected path, the confirmed handle/permission findings, and whether the error
also occurs during the isolated Pi retry. These are needed to separate local file access from network resets.

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
| `--yes` / `-y` | `-Yes` | Install the default tool set, shared skills, applicable MCP/plugin config and declared dependencies. |
| `--with-tools=fx,cursor` | `-WithTools 'fx,cursor'` | Add optional standalone catalog CLIs. |
| `--with-integrations` | `-WithIntegrations` | Install bundled config, plugins, skills and MCP dependencies (default). |
| `--without-integrations` | `-WithoutIntegrations` | Install standalone CLIs only; leave configuration unchanged. |
| `--rollback` | `-Rollback` | Restore the most recent backup. |
| `--verbose` / `-v` | `-Verbose` | Show detailed installer output. |
| `--migrate-gemini` | — | Migrate Gemini CLI configuration to Antigravity CLI. |

Non-interactive Bash and PowerShell pipelines automatically add `--yes`. This mode uses the same default
categories above; it is not a configuration-free install. Review
[`cli.sh`](cli.sh) before using it in automation.

## 🤖 Supported tools

The repository currently contains configuration or integration support for:

| Category | Tools |
| --- | --- |
| Primary assistants | Claude Code, OpenCode, Amp, Codex, Cursor, Pi, Oh My Pi, Antigravity, Kilo, Kimi Code, Muse Code |
| Additional CLIs | CommandCode, GitHub Copilot CLI, Gemini CLI, Grok CLI, MiMo-Code, Qoder CLI, DeepSeek Harness, Kiro CLI, Devin CLI, Factory Droid, Cline, Reasonix |
| Workflow and desktop tools | Conductor, Delta, Codiff, Hunk, ctx, herdr, Orca, AI Launcher, CCS, fx, Open Code Review, ghui |

Some installers are platform-specific, and optional tools are skipped when they are not detected. Gemini CLI is
deprecated for Google One and unpaid tiers; use the `--migrate-gemini` option to move its configuration to
Antigravity CLI.

See [`configs/`](configs/) for the source configuration of each tool and [`skills/`](skills/) for shared skills.

For an opt-in VPS terminal accessed from a Mac over Tailscale, see the
[Pi Durable setup](configs/pi/durable/README.md). It uses a pinned experimental
TUI, private persistent storage, and a user service; the general installer does not enable it.

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

### Update shared agent guidelines

Edit [`configs/token-efficiency.md`](configs/token-efficiency.md) or
[`configs/experiment-workspaces.md`](configs/experiment-workspaces.md), then run:

```bash
./scripts/sync-token-efficiency.sh
./scripts/sync-token-efficiency.sh --check
```

The script syncs both sections across the managed profiles. Experiment Workspaces also covers the Claude Code
profile and the root `AGENTS.md` and `GEMINI.md`. Do not edit these generated sections in individual profiles;
the CI check rejects drift from the canonical files. The workspace guideline uses `try` when available, but
the installer does not install it. It requires shell integration; fresh experiments use an interactive selector,
with fallbacks for agent shells without a terminal. `generate.sh` restores the canonical sections after export,
so an older home-directory profile cannot remove them.

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
