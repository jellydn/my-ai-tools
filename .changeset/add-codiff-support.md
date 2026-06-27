---
"my-ai-tools": minor
---

Add Codiff as a first-class supported tool with install/copy/generate scaffolding,
codiff.jsonc config, and README section.

- configs/codiff/codiff.jsonc: settings (agentBackend: pi, theme: system, diffStyle: split)
  and keymap defaults
- cli.sh: copy_codiff_configs() installs codiff.jsonc with .bak safety; backup_configs()
  includes ~/.codiff/
- generate.sh: generate_codiff_configs() reverse-syncs codiff.jsonc
- lib/install.sh: install_codiff() guards already-installed via `command -v codiff`
  before running `brew install --cask nkzw-tech/tap/codiff` (macOS) or providing
  manual install instructions (Linux)
- tests/pr_codiff.bats: ~20 assertions covering install, config, and generate paths
