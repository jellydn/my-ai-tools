---
"my-ai-tools": patch
---

Add first-class support for Qoder CLI (https://qoder.com/cli) to close issue #264. Ship `configs/qodercli/AGENTS.md`, add `install_qodercli()` to `lib/install.sh`, register `copy_qodercli_configs()` in `cli.sh`, add `generate_qodercli_configs()` to `generate.sh`, and document in README with the standard install/copy/MCP layout.
