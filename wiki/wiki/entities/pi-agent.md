---
title: "Pi Agent"
type: entity
tags: [tool, agent, pi]
updated: 2026-07-04
---

# Pi Agent

AI coding agent ([pi.dev](https://pi.dev)) built for agentic coding workflows. Managed as one of the primary tools in the my-ai-tools config repository.

## Configuration

Pi uses `~/.pi/agent/settings.json` for global settings. The repo stores configs under `configs/pi/`:

- `settings.json` — Global settings, package registrations, enabled models
- `models.json` — Provider and model definitions
- `mcp.json` — MCP server declarations
- `AGENTS.md` — Agent-specific instructions

## Default Settings (as of 2026-07-04)

| Setting          | Value               |
| ---------------- | ------------------- |
| Default Provider | `clinepass`         |
| Default Model    | `deepseek-v4-flash` |
| Theme            | `kanagawa`          |
| Permission Level | `high`              |

## Enabled Models (5 providers)

| Provider           | Models                                                                                                                        |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| cursor             | `auto`, `composer-2.5`                                                                                                        |
| openai-codex       | `gpt-5.4`, `gpt-5.4-mini`, `gpt-5.3-codex-spark`, `gpt-5.5`                                                                   |
| clinepass          | `deepseek-v4-pro`, `deepseek-v4-flash`, `kimi-k2.7-code`, `glm-5.2`, `kimi-k2.6`, `minimax-m3`, `qwen3.7-max`, `qwen3.7-plus` |
| google-antigravity | `gemini-3.5-flash`, `gemini-3-pro`, `claude-opus-4-6`                                                                         |
| commandcode        | `deepseek/deepseek-v4-pro`                                                                                                    |

## Packages (19 total)

Pi uses a package-based extension system. Installed packages include: pi-extension, pi-autoresearch, pi-fff, pi-mcp-adapter, pi-simplify, pi-manage-todo-list, pi-btw, pi-code-previews, pi-codex-goal, pi-dynamic-workflows, pi-commandcode-provider, pi-footer, pi-tps-meter, rpiv-advisor, pi-cursor-sdk, pi-web-access, pi-clinepass-provider, rpiv-ask-user-question, pi-antigravity-oauth.

## MCP Servers

context7, sequential-thinking, qmd, fff, react-grab-mcp, agentmemory, sem, ctx

## Related

- [[ctx]] — Agent-history search MCP server configured for Pi
- [[mcp-registry]] — Central MCP registry
- [[my-ai-tools-repo]] — Monorepo structure
