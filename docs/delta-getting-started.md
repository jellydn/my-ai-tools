# Delta Getting Started

Quick reference for [Delta](https://delta.dev) — Zed's collaborative agent workspace for coding with agents and reviewing what they build.

Official docs: [delta.dev/docs/getting-started](https://delta.dev/docs/getting-started)

## TL;DR

Delta is a **thread-based agent workspace**. You describe what you want, an agent works in an isolated checkout of your repository, and you review and sync the results. By default the agent uses a **separate checkout**, so your working tree stays untouched until you bring changes in.

Delta is in **early development** (private beta). Sign in with your Zed account, accept the Early Access Agreement on the Zed dashboard, then wait for admission.

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| **Zed account** | Sign in through Delta on first launch |
| **Early access** | Accept the agreement at [zed.dev](https://zed.dev) and wait for beta admission |
| **Git repository** | Open a project folder to start a thread |
| **Model provider** | Connect Anthropic, OpenAI, or another supported provider (API key in settings or `~/.config/delta/.env`) |

Supported platforms: **macOS**, **Linux**, and **Windows**. Nightly builds; Delta checks for updates on startup.

## Install

Download the latest release for your OS and processor (`x86_64` for Intel/AMD, `aarch64` for ARM).

### macOS

```bash
# 1. Unzip Delta.app.zip
# 2. Move Delta.app into /Applications
# 3. Clear quarantine (required — otherwise macOS runs from a read-only temp path)
xattr -dr com.apple.quarantine /Applications/Delta.app
```

### Linux

```bash
tar -xzf delta-linux-<architecture>.tar.gz
./Delta/bin/delta

# Optional: install to ~/.local/delta.app and register with the desktop environment
./Delta/install.sh
delta   # requires ~/.local/bin on PATH
```

### Windows

- **Installer:** run `delta-windows-<architecture>-setup.exe` (per-user install, Start menu, `delta://` links).
- **Portable:** extract `delta-windows-<architecture>.zip` and run `.\Delta\delta.exe`.

Windows builds are not signed yet; SmartScreen may warn — choose **More info → Run anyway**.

## Sign in and connect a model

1. Launch Delta — sign-in screen on first run (or **Sign In** from the Delta menu later).
2. Authenticate in the browser; session is stored in the system keychain (once per machine).
3. After sign-in, Delta walks you through connecting a provider and starts a short tutorial thread.

Put API keys in Delta settings or in `~/.config/delta/.env` (Windows: `%USERPROFILE%\.config\delta\.env`):

```bash
ANTHROPIC_API_KEY=your-key
```

See [Models & Providers](https://delta.dev/docs/getting-started#connect-a-model) in the official docs for the full list.

## Start your first thread

1. **Open a project folder** in Delta.
2. **Start a thread** and describe the task (explore the codebase, fix a bug, scaffold a feature).
3. The agent works in a **separate checkout** by default — your project folder is unchanged until you sync.

## Terminal in a thread

At the start of an empty line in the message composer, type **`!`** to open an interactive terminal in the thread's checkout.

Or use **File → Open Terminal**. Terminals can stay running in the background while the agent continues.

## Command palette and Ask Delta

| Shortcut | Platform | Action |
|----------|----------|--------|
| `Cmd+Shift+P` / `Cmd+K` | macOS | Open command palette |
| `Ctrl+Shift+P` / `Ctrl+K` | Linux / Windows | Open command palette |

Search for a thread or action, press **Enter** to run.

Press **Tab** in the palette to switch to **Ask Delta** — describe what you want and Delta suggests relevant commands. Press **Tab** again to return to search.

## Review and sync workflow

Delta keeps **code and conversation connected**:

- Comment on the **conversation**, **diff**, or **any line of code** (agent or human).
- Comments stay anchored as the worktree evolves (via **DeltaDB**).
- Sync agent changes into your repo when ready — normal **commit and push** still apply for teammates who never open Delta.

### Multiplayer

- Invite teammates into a thread; each gets a local copy of the code synced in real time.
- Share a thread link — teammates can open it in the **browser** (`delta.dev`) without installing Delta.
- **Claude Code** syncs live into a Delta thread via ACP — keep working in the terminal, review in Delta.

## How Delta fits my-ai-tools

Delta is **not wired into `./cli.sh` yet** — there is no stable shared config path to install from this repo. Use this guide plus the official docs until Delta exposes install/config hooks.

Pair Delta with tools already in my-ai-tools:

| Tool | Role with Delta |
|------|-----------------|
| **Claude Code / Codex / Cursor** | Terminal agents; Claude Code can sync into Delta via ACP |
| **Hunk** | Terminal diff review for local changes outside a Delta thread |
| **accountable-engineering** skill | Checkpoint-driven workflow before handing work to an agent thread |

## Troubleshooting

| Issue | Fix |
|-------|-----|
| macOS prompts to move Delta every launch | Run `xattr -dr com.apple.quarantine /Applications/Delta.app` |
| Linux `delta: command not found` after install | Add `~/.local/bin` to `PATH` |
| Windows SmartScreen block | **More info → Run anyway** (unsigned build) |
| Model errors | Check provider key in settings or `~/.config/delta/.env` |

## What's next (official docs)

- [Getting Started](https://delta.dev/docs/getting-started) — install, sign-in, first thread
- [Introducing Delta](https://zed.dev/blog/introducing-delta) — product overview and private beta
- Threads, review & sync, and collaboration docs (linked from the official sidebar as they ship)

## Links

- [delta.dev](https://delta.dev) — browser client and docs
- [Zed](https://zed.dev) — editor; DeltaDB will eventually come to Zed
- [Private beta signup](https://zed.dev/blog/introducing-delta) — early access waitlist
