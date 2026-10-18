---
"my-ai-tools": patch
---

Restructure the installer shell libraries so the token-efficiency work stops growing
oversized files, and make the duplicated Token Efficiency guidance generated instead of
hand-copied. No behavior change: installer order, gating, and log output are identical.

- lib/install-deps.sh: new module owning prerequisites (Bun, jq, biome, gofmt, ruff,
  Rust/cargo, rustfmt, shfmt, stylua, backlog) and the standalone MCP binaries (qmd,
  fff-mcp, logpilot, sem); sourced by lib/install.sh, which drops from 1207 to 717 lines
- lib/install.sh: every PATH mutation now goes through the previously unused
  `ensure_dir_on_path()` helper, including the RTK installer; adds `cargo_bin_dir()`
- cli.sh: replaces 27 copies of the `if tool_allowed …; else log_info "Skipping …"` block
  in `main()` with the ordered `INSTALL_SEQUENCE` table and `run_install_sequence()`
  (`always:` marks cross-tool dependencies such as RTK that the -y allowlist never gates)
- configs/token-efficiency.md + scripts/sync-token-efficiency.sh: canonical Token
  Efficiency section for the 22 managed AGENTS.md/GEMINI.md profiles, with `--check` for CI
- configs/opencode/opencode.json: re-removes the eager `instructions` array that a later
  config-import commit reintroduced, and configs/pi tests match the committed OmniRoute
  defaults — both were failing CI on this branch
- tests: new tests/pr_install_deps.bats (syntax, module size, PATH discipline); RTK and
  per-tool installer tests assert the registry table instead of line numbers and log strings
