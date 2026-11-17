---
"my-ai-tools": minor
---

Add Reasonix as a first-class supported tool with install/copy/generate scaffolding,
config.toml, AGENTS.md, and README section.

- configs/reasonix/config.toml: user-global config (~/.reasonix/config.toml) with
  default_model, permissions (ask), sandbox, and [[plugins]] MCP entries mirroring
  the shared registry (context7, sequential-thinking, qmd, codebase-memory-mcp, fff,
  react-grab-mcp, logpilot, agentmemory, sem, ctx)
- configs/reasonix/AGENTS.md: agent guidelines with tmux session management, MCP tool
  guidance, Reasonix-specific practices (append-only prefix-cache loop, /plan, /init,
  headless `reasonix run -y`), and the shared Token Efficiency section
- cli.sh: install_reasonix via install_npm_tool; copy_reasonix_configs() installs
  config.toml + AGENTS.md to ~/.reasonix; backup includes ~/.reasonix; registered in
  INSTALL_SEQUENCE and the -y allowlist; banner updated
- generate.sh: generate_reasonix_configs() reverse-syncs config.toml + AGENTS.md
- lib/install.sh: install_reasonix() installs the `reasonix` npm package
- README.md: tool list, features line, MCP table row, and -y allowlist updated
