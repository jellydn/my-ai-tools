---
"my-ai-tools": minor
---

Add Kiro CLI as a first-class supported tool with install/copy/generate scaffolding,
AGENTS.md, MCP settings.json, and README section.

- configs/kiro/settings.json: 8 standard MCP servers (context7, sequential-thinking,
  qmd, fff, react-grab-mcp, logpilot, agentmemory, sem)
- cli.sh: copy_kiro_configs() installs settings.json with .bak safety; backup_configs()
  includes ~/.kiro/
- generate.sh: generate_kiro_configs() reverse-syncs settings.json (symmetrical with cli.sh)
- lib/install.sh: install_kiro() guards already-installed via command -v kiro check
  before calling the POSIX installer (PowerShell on Windows)
- tests/pr_kiro.bats: 19 assertions covering install, config, and generate paths
