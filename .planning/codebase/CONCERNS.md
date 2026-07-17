# Codebase Concerns

**Analysis Date:** 2026-07-14

## Tech Debt

**CI vs local test surface:**
- Issue: GitHub Actions runs only `tests/pr_*.bats`, `tests/generate.bats`, and `tests/sh_reexec.bats` (16 + 2 files), while the repo has 23 BATS files total. Seven suites (`cli.bats`, `cursor_configs.bats`, `install.bats`, `lib_common.bats`, `recommend_skills.bats`, plus any future non-`pr_*` files) never run in CI.
- Files: `.github/workflows/test.yml`, `AGENTS.md`, `tests/cli.bats`, `tests/cursor_configs.bats`, `tests/install.bats`, `tests/lib_common.bats`, `tests/recommend_skills.bats`
- Impact: Regressions in full `cli.sh` install paths, Cursor agent install/export wiring, `lib/common.sh` helpers, and recommend-skills logic can merge green on CI while failing locally.
- Fix approach: Either expand the CI `bats` step to `bats tests/` (or an explicit allowlist that includes the omitted files), or document and enforce that PR authors must run the full suite; align `TESTING.md` with the CI subset.

**Dual formatters (biome vs oxfmt):**
- Issue: Contributors are told to use `biome check --write .` (`CONTRIBUTING.md`, `AGENTS.md`), while pre-commit runs `oxfmt` on TS/JS (with excludes for code-taste paths). CI runs biome only on a narrow code-taste path set, not repo-wide biome or oxfmt.
- Files: `.pre-commit-config.yaml`, `biome.json`, `CONTRIBUTING.md`, `.github/workflows/test.yml`, `.commandcode/taste/taste.md` (notes biome vs oxfmt preference)
- Impact: Inconsistent formatting depending on whether developers use pre-commit vs manual biome; drift between hook output and `biome check .` on the rest of the tree.
- Fix approach: Single source of truth (biome everywhere or oxfmt everywhere), wire the chosen tool into CI, and update CONTRIBUTING/AGENTS to match.

**Config validation is warn-and-continue in CI:**
- Issue: `validate_all_configs()` logs failures but continues when `--yes` or non-interactive (`CI` auto-enables `-y`), so broken JSON in allowed-tool configs can still install.
- Files: `cli.sh` (`validate_all_configs`), `lib/common.sh` (`is_non_interactive`, `validate_config`)
- Impact: Invalid configs land in `$HOME` on automated runs without a hard gate.
- Fix approach: Fail CI on validation errors (dedicated `jq` validation job) or treat validation failure as exit 1 in CI even with `-y`.

**Monolithic entry scripts:**
- Issue: `cli.sh` (~2.5k lines) and `README.md` (~3.3k lines) concentrate install, MCP merge, validation, and documentation; changes are high-touch and grep-heavy.
- Files: `cli.sh`, `generate.sh`, `README.md`
- Impact: Review burden, merge conflicts, and easy-to-miss side effects when adding a tool.
- Fix approach: Continue modularizing into `lib/` (pattern already used for `install.sh`, `common.sh`) and split README into wiki sections with a thin root index.

**YAML validation optional:**
- Issue: `validate_yaml` returns success when no python3/pyyaml, yq, or ruby is available.
- Files: `lib/common.sh`
- Impact: Invalid YAML in configs may pass validation on minimal environments.
- Fix approach: Require `yq` or python in CI validation job; fail closed when validator missing in CI.

## Known Bugs

**macOS BATS / getcwd fragility:**
- Symptoms: Full `bats tests/` may fail on macOS host due to directory/getcwd behavior.
- Files: `AGENTS.md`
- Trigger: Run `bats tests/` on macOS without sandbox.
- Workaround: Run tests inside microsandbox (`msb run ... ubuntu ... bats tests/`).

**`set -u` with sourced `cli.sh`:**
- Symptoms: Sourcing `cli.sh` / copy helpers with `set -u` can error on unset optional vars (e.g. `MSYSTEM`).
- Files: `AGENTS.md`, `lib/common.sh`
- Trigger: BATS-style `export HOME=...; source ./cli.sh` with `set -u` enabled.
- Workaround: Do not enable `set -u` when sourcing install functions (documented in AGENTS).

**Non-TTY `cli.sh` network install noise:**
- Symptoms: Piped or CI shells auto-enable `--yes` and attempt many global CLI installs before config copy; failures/hangs without network.
- Files: `cli.sh`, `lib/install.sh`, `AGENTS.md`
- Trigger: `./cli.sh` without TTY in restricted network.
- Workaround: Use `--dry-run`, or source `cli.sh` and call copy functions with throwaway `HOME` (as in tests).

## Security Considerations

**Placeholder credentials in example configs:**
- Risk: Copy-paste of `providers.json.example` or similar into live paths with placeholder tokens left unchanged; example files look like real provider configs.
- Files: `configs/cline/providers.json.example`, `configs/kimi-code/config.toml` (empty `api_key` fields)
- Current mitigation: `.example` naming and placeholder strings; not installed as live `providers.json` by default.
- Recommendations: Ensure `generate.sh` never exports example files to real provider paths; grep CI for committed real tokens; document “never commit `providers.json`”.

**MCP and env-based secrets:**
- Risk: MCP configs reference env vars (`AGENTMEMORY_SECRET`, OAuth tokens) that users must supply; misconfiguration exposes empty auth or local-only assumptions.
- Files: `configs/opencode/opencode.json`, `configs/copilot/mcp-config.json`, `codex/config.toml`, `configs/mcp-registry.json` (npx pulls `@latest` packages)
- Current mitigation: `${VAR:-}` patterns; registry documents `requires` for binaries.
- Recommendations: Pin MCP package versions where feasible; document secret handling in README; audit `npx -y @latest` supply-chain risk.

**GitHub Pages deploy uploads entire repo:**
- Risk: Accidental publication of any file in the default branch tree (including examples with token-shaped strings) if Pages serves raw paths.
- Files: `.github/workflows/deploy-pages.yml`
- Current mitigation: Typical Pages site uses `index`/static subset depending on site generator—in this workflow `path: "."` uploads the full checkout.
- Recommendations: Deploy only `wiki/` or a built `docs/` artifact; exclude `configs/**` examples from the published artifact.

**Orca agent hooks:**
- Risk: Hooks POST to localhost with `ORCA_AGENT_HOOK_TOKEN`; weak or missing token checks if env unset (scripts exit early when vars missing—good).
- Files: `orca/agent-hooks/*.sh`
- Current mitigation: Early exit when port/token/pane key unset.
- Recommendations: Treat tokens as secrets; do not log hook payloads containing paths or prompts.

## Performance Bottlenecks

**Parallel install and global tooling:**
- Problem: `cli.sh` may install many global CLIs sequentially or in parallel bursts; first-run install is slow and network-heavy.
- Files: `lib/install.sh`, `cli.sh`
- Cause: Optional tool detection installs jq, biome, formatters, and per-tool CLIs.
- Improvement path: Lazy-install per tool; cache presence checks; skip network phase when `--dry-run` or explicit `--skip-tool-install`.

**Large README and wiki duplication:**
- Problem: Loading and searching multi-thousand-line docs is slow for humans and agents.
- Files: `README.md`, `wiki/raw/README.md`
- Cause: Duplicated Windows/install sections between root and wiki.
- Improvement path: Single canonical wiki; README links only.

## Fragile Areas

**Bash re-exec guard ordering:**
- Files: `cli.sh`, `generate.sh`, `lib/require_bash.sh`, `tests/sh_reexec.bats`
- Why fragile: `lib/common.sh` uses bash-only syntax; sourcing order must stay `require_bash.sh` before `common.sh`.
- Safe modification: Run `tests/sh_reexec.bats` and `bash -n` on every shell change.
- Test coverage: Strong for re-exec; not run if CI subset unchanged.

**MCP registry merge logic:**
- Files: `cli.sh` (registry parse, `jq` merge into destination MCP files)
- Why fragile: Requires `jq`; merge failures fall back to warnings or manual steps.
- Safe modification: Add `pr_*` or integration tests for merge scenarios; require `jq` in CI (already installed in workflow).
- Test coverage: Partial via `pr_codebase_memory_mcp.bats` and related PR tests; not all tools’ MCP paths.

**Windows path and MSYSTEM detection:**
- Files: `lib/common.sh`, `install.ps1`, `lib/install.sh`
- Why fragile: Git Bash vs PowerShell vs MSYS path conversion; winget jq path heuristics.
- Safe modification: Test on Windows Git Bash; avoid `set -u` with optional `MSYSTEM`.
- Test coverage: Mostly documentation and manual; no Windows runner in `.github/workflows/test.yml`.

## Scaling Limits

**Tool proliferation in monorepo:**
- Current capacity: 14+ tool config trees under `configs/`, each wired in `cli.sh` / `generate.sh`.
- Limit: Linear growth in install/validate/copy branches; reviewer fatigue.
- Scaling path: Codegen or shared manifest (`mcp-registry.json` pattern) for per-tool install hooks.

**Backup retention:**
- Current capacity: Last 5 backups under `$HOME/ai-tools-backup-*` (per AGENTS).
- Limit: Disk use on frequent installs; no size cap per backup.
- Scaling path: Document pruning; optional max-age/size in `safe_copy_dir` backup helper.

## Dependencies at Risk

**Gemini CLI deprecation:**
- Risk: Google One/unpaid tier cutoff (June 18, 2026) per AGENTS/README.
- Impact: Users following old Gemini docs break; install paths may still reference deprecated CLI.
- Migration plan: Antigravity CLI as documented; audit `configs/gemini` and README CTAs.

**Floating `npx -y ...@latest` MCP servers:**
- Risk: Registry entries pull latest MCP packages on each cold start.
- Impact: Breaking API or malicious publish could affect users.
- Migration plan: Pin versions in `configs/mcp-registry.json` and document upgrade process.

## Missing Critical Features

**No Windows CI job:**
- Problem: Shell logic and `install.ps1` are not exercised on `windows-latest`.
- Blocks: Confident Windows releases without manual QA.

**No repo-wide format/lint gate in CI:**
- Problem: `biome check .` and pre-commit are not enforced on push (only code-taste subset + optional local hooks).
- Blocks: Consistent formatting across contributors who skip hooks.

## Test Coverage Gaps

**Cursor custom agents (install + export):**
- What's not tested: End-to-end copy to throwaway `HOME` for `configs/cursor/agents`; only grep-based presence in `cursor_configs.bats`.
- Files: `tests/cursor_configs.bats`, `cli.sh`, `generate.sh`
- Risk: Path or function rename breaks agent sync without CI failure.
- Priority: Medium

**Full `cli.sh` / `install.bats` / `lib_common.bats`:**
- What's not tested in CI: Behavioral tests in `cli.bats`, `install.bats`, `lib_common.bats`, `recommend_skills.bats`.
- Files: `tests/cli.bats`, `tests/install.bats`, `tests/lib_common.bats`, `tests/recommend_skills.bats`
- Risk: Core install and helper regressions.
- Priority: High

**Agent export parity across tools:**
- What's not tested: Many `pr_*.bats` assert `generate.sh` contains `generate_*_configs` and grep for export paths; fewer tests assert symmetric `cli.sh` install for custom agents/subagents across Copilot, Cline, Codex, Pi, etc.
- Files: `tests/pr_cline.bats`, `tests/pr_copilot.bats`, `tests/pr_grok.bats`, `generate.sh`
- Risk: Export-from-`$HOME` workflow drifts from install-to-`$HOME` for agent markdown trees.
- Priority: Medium

**Pre-commit / biome alignment:**
- What's not tested: CI does not run `pre-commit run --all-files` or full `biome check .`.
- Files: `tests/pr_pre_commit.bats` (structure only), `.pre-commit-config.yaml`
- Risk: Hook config changes break contributors silently.
- Priority: Low–Medium

**Config schema validation:**
- What's not tested: Automated job that fails on invalid JSON/YAML for all files under `configs/`.
- Files: `cli.sh`, `configs/**`
- Risk: Broken configs merge despite local `validate_all_configs` warnings.
- Priority: High

**macOS / microsandbox:**
- What's not tested: CI is `ubuntu-latest` only; microsandbox workaround is undocumented in CI.
- Files: `AGENTS.md`
- Risk: macOS-only failures discovered late.
- Priority: Low (documented workaround exists)

---

*Concerns audit: 2026-07-14*
