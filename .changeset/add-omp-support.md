---
"my-ai-tools": patch
---

## Oh My Pi (omp) CLI support & --help flag handling

### What

Add Oh My Pi (`omp`) CLI support alongside `pi`, and add `-h` / `--help` flag handling to `cli.sh` and `generate.sh`.

- Add `omp` to `TOOL_ALLOWLIST_YES` and `INSTALL_SEQUENCE` in `cli.sh`.
- Define `install_omp()` in `lib/install.sh` installing `@oh-my-pi/pi-coding-agent`.
- Define `copy_omp_configs()` in `cli.sh` and `generate_omp_configs()` in `generate.sh`.
- Add `configs/omp/settings.json`, `configs/omp/config.yml`, and `configs/omp/AGENTS.md`.
- Register `omp` in `configs/ai-launcher/config.json`.
- Support `-h` / `--help` in `cli.sh` and `generate.sh` to print usage information cleanly.
- Add test coverage in `tests/pr_omp.bats` and update `tests/cli.bats`.

### Why

Oh My Pi (`omp`) is a batteries-included coding agent forked from Pi. Adding native configuration management, installer, launcher registration, and help flag support ensures `omp` can be deployed and managed seamlessly.
