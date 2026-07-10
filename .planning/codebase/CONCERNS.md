# Technical Concerns

**Analysis Date:** 2026-07-10

---

## File Size & Complexity

| File | Lines | Concern |
|------|-------|---------|
| **`cli.sh`** | 2,574 | Largest file. Single-purpose functions keep it manageable, but the dispatch table (`copy_configurations()`) is a long linear block of function calls. Consider grouping by tool category. |
| **`lib/install.sh`** | 1,102 | 20+ tool installers in one file. Each installer follows a consistent pattern, but the file is approaching the 1k-line structural boundary. Could split into `lib/installers/<tool>.sh`. |
| **`lib/common.sh`** | 866 | Well-organized utilities. Within the 1k-line boundary. |
| **`generate.sh`** | 961 | Close to 1k-line boundary. The `generate_<tool>_configs()` functions follow the same pattern as `cli.sh`'s copy functions — some code duplication between the two scripts. |

---

## Code Duplication

- **cli.sh vs generate.sh**: The `copy_<tool>_configs()` and `generate_<tool>_configs()` functions are mirrored pairs that follow nearly identical patterns (e.g., both detect tool presence, both copy files, both log success). The duplication is intentional (install vs export are different operations) but could benefit from a shared helper pattern.

- **Agent install blocks**: The `cli.sh` agent install blocks for Codex, Pi, and Copilot all follow the same `rm -rf` + `safe_copy_dir` pattern. OpenCode and Cursor already use this pattern. This is consistent duplication across the codebase — not harmful, but worth noting.

---



---

## Missing Test Coverage

- **Agent/Skill export paths in `generate.sh`**: The new agent export functions (Codex, Pi, Kiro, Copilot) don't have corresponding BATS tests. The `generate.bats` and `pr_*.bats` files focus on `cli.sh` install paths.
- **Skill loading**: No tests verify that `SKILL.md` files are valid and properly formatted.
- **Agent JSON validation**: Kiro's new `.json` agent configs aren't tested for schema validity in CI.

---

## Deprecation Debt

- **Gemini CLI**: Deprecated for Google One/unpaid tiers (June 18, 2026 cutoff). The code still maintains full Gemini config and install support. The `generate.sh` warns but doesn't block. Consider a migration timeline to fully remove Gemini support.
- **Legacy MCP fallback**: `cli.sh` maintains fallback paths for the old MCP installation method. Once all tools have migrated to the central `mcp-registry.json`, this fallback can be removed.

---

## Fragile Areas

### Shell Script Portability

- **Bash-only syntax** is used throughout `cli.sh`, `generate.sh`, and `lib/`. The `require_bash.sh` guard prevents execution under `sh`/`dash`, but scripts must always source it first — a missing guard could cause silent failures.
- **Process substitution** (`<(...)`) is used in `detect_tool` and similar helpers. While guarded, it's a frequent source of portability bugs.
- **Windows support** relies on PowerShell wrappers and `MSYSTEM` detection. Not extensively tested — most CI runs on Linux/macOS.

### MCP Installation

- Network-dependent (`npm install`, `cargo install`). Failures are handled with retry logic but can still fail in air-gapped environments.
- Package manager detection (`bun` → `npm` fallback) adds complexity. If neither is available, installation fails with a clear error.

### Config Validation

- JSON configs are validated with `jq` at install time. Validation failures warn but don't block — the user must explicitly refuse at the prompt.
- No schema validation for TOML configs (Codex, Kimi Code, Grok) — only manual inspection.

---

## Resolved Issues

Issues from PR #293 code-review that have been addressed:

1. ~~Amp subagent skills missing~~ — Created 5 SKILL.md files in `configs/amp/skills/`
2. ~~Grok subagent deletions missing~~ — Grok uses plugin marketplace, file-based subagents removed
3. ~~Claude agents~~ — All 5 existing Claude agents have "Available Tools" sections (the claim of 9 was inaccurate)
4. ~~Missing generate.sh export paths~~ — Cline skills export added; Kimi Code and Factory were already handled
5. ~~Config drift~~ — Fixed in commit `53be0b9`: reverted antigravity-cli and pi settings to `main` state

---

## Positive Notes

- **No TODO/FIXME/HACK comments** found in the codebase — clean code discipline
- **Consistent patterns**: All 20+ tool installers follow the same structure (detect → download → verify → install → validate)
- **Comprehensive test suite**: 280+ tests across 23 files
- **Strong guard clauses**: Every function checks preconditions before acting
- **Dry-run support**: All destructive operations are gated behind `DRY_RUN` mode, making development safe

---

_Last updated: 2026-07-10_
