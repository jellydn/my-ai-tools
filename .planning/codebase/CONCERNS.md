# Codebase Concerns

**Analysis Date:** 2026-07-04

## Tech Debt

### Monolithic Script Files

- **Issue:** Core scripts are extremely large and do too many things:
  - `cli.sh` at ~2,283 lines (72+ KB) — argument parsing, preflight checks, backup logic, 23+ per-tool copy/install functions, MCP server setup, skill management, plugin installation
  - `generate.sh` at ~907 lines — 25+ per-tool export/generate functions all in one file
  - `lib/install.sh` at ~1,103 lines — installer functions for 24+ AI tools plus global tooling
  - `lib/common.sh` at ~867 lines — path handling, logging, temp files, OS detection, backups, transactions, JSON/YAML validation, parallel execution, dry-run support
- **Impact:** Hard to navigate, difficult to unit-test individual functions, risk of merge conflicts when multiple people touch different tools
- **Fix approach:** Split into focused modules: `lib/claude.sh`, `lib/opencode.sh`, etc. Move per-tool `copy_*_configs()` into tool-specific files. Split `lib/common.sh` into `lib/path.sh`, `lib/log.sh`, `lib/io.sh`, `lib/validate.sh`.

### Bash-Only Syntax in "POSIX-Capable" Code

- **Issue:** `lib/common.sh` function `safe_copy_dir()` uses `local -a exclude_dirs=(...)` and `local -a rsync_excludes=()` (lines 665, 673) — bash arrays — while the codebase goes to great lengths to be POSIX-compatible (see `lib/require_bash.sh` re-exec guard, temp-file-based PID tracking to avoid arrays elsewhere)
- **Files:** `lib/common.sh` lines 665-678
- **Impact:** Inconsistency in coding standards; the arrays work because `require_bash.sh` guarantees bash, but the surrounding code was refactored to use positional params and temp files specifically to avoid arrays
- **Fix approach:** Either commit to bash-only and remove POSIX workarounds, or rewrite these arrays as newline-delimited strings

### Duplicated Logging Functions

- **Issue:** `install.sh` re-implements `log_info`, `log_success`, `log_warning`, `log_error` inline (lines 12-28), duplicating `lib/common.sh` identically. Uses `echo -e` while `lib/common.sh` uses `printf '%b'`.
- **Files:** `install.sh` lines 12-28 vs `lib/common.sh` lines 231-243
- **Impact:** Bug fixes to logging must be applied in two places; current implementations already diverged in approach (`echo -e` vs `printf '%b'`)
- **Fix approach:** Make `install.sh` source `lib/common.sh` after cloning the repo, or embed a single-source-of-truth logging snippet shared via code generation

### Per-Tool Copy Function Duplication

- **Issue:** `cli.sh` has ~23 nearly-identical `copy_*_configs()` functions (one per tool) that follow the same pattern: detect tool → log → mkdir → copy files → copy directories → log success
- **Files:** `cli.sh` — `copy_claude_configs()`, `copy_opencode_configs()`, `copy_amp_configs()`, ... (23+ functions spanning ~1,200 lines)
- **Impact:** Adding a new tool requires copying ~60 lines of boilerplate; consistency bugs (e.g., some functions use `copy_config_file`, others use raw `execute_quoted cp`)
- **Fix approach:** Define a declarative tool config registry (JSON) with per-tool file mappings, then drive all copy operations from a single function

### Direct `rm -rf` Without `execute_quoted` Guard

- **Issue:** `cli.sh` line 1533: `rm -rf "$HOME/.cline/skills/$skill_name"` — uses raw `rm -rf` instead of `execute_quoted`, bypassing DRY_RUN mode
- **Files:** `cli.sh` L1533
- **Impact:** In DRY_RUN mode, this `rm -rf` will execute destructively instead of being logged and skipped; potential data loss if `$skill_name` is empty or malformed
- **Fix approach:** Wrap in `execute_quoted`, add guard for empty `$skill_name`

### Inconsistent `set -e` Usage

- **Issue:** `cli.sh` and `generate.sh` use `set -e` at the top level. However, `set -e` has well-known pitfalls — it doesn't propagate errors from pipes, conditional expressions (`if`/`while` tests), or command substitutions without additional options (`set -o pipefail`)
- **Files:** `cli.sh` L7, `generate.sh` L7
- **Impact:** Some errors may be silently swallowed; pipeline failures in functions like `generate.sh`'s `copy_single` can produce partial/missing output without failing the script
- **Fix approach:** Add `set -o pipefail` alongside `set -e`, or use explicit error checking after every critical operation

### `prompt_yn` Leaves Stdin Polluted

- **Issue:** `prompt_yn()` reads exactly 1 byte via `dd bs=1 count=1`. If user types "yes\n", only "y" is consumed; "es\n" remains in stdin. The next `read` call (e.g., in `determine_skill_install_source()`) reads the leftover "es" instead of waiting for fresh input.
- **Files:** `lib/common.sh` `prompt_yn()` (L553-567)
- **Impact:** After answering "yes" to a prompt, subsequent `read` calls may get stale input, skipping or corrupting interactive flows
- **Fix approach:** Flush stdin after `dd` read: `read -t 0.01 -r _drain 2>/dev/null || true`

## Known Issues

### Cross-Device Link Errors (TMPDIR on Different Filesystem)

- **Symptoms:** `mv`/`cp` fails with "Invalid cross-device link" when `TMPDIR` points to a different filesystem than `HOME`
- **Files:** `lib/common.sh` `get_temp_dir()` (L59-77), `execute_installer()` (L333-343), `cli.sh` `setup_tmpdir()` (L146-150)
- **Trigger:** macOS with `TMPDIR=/var/folders/...` where `/var` is a separate APFS volume from `/Users`
- **Workaround:** `setup_tmpdir()` creates `~/.claude/tmp` and exports it as `TMPDIR`, but only in `cli.sh`; `generate.sh` and `install.sh` don't call this, so errors can still occur
- **Fix:** Move `setup_tmpdir()` to `lib/common.sh` and call it at the top of every entry-point script before any temp file operations

### Amp `backlog.md` Dependency Not Auto-Resolved When Amp Pre-Installed

- **Symptoms:** `install_backlog_if_needed()` returns early if `AMP_INSTALLED=false`, but this flag is only set to `true` by `install_amp()` when it actually installs Amp. If Amp was already installed before running `cli.sh`, `AMP_INSTALLED` stays `false` and backlog.md is never offered.
- **Files:** `cli.sh` L19 (`AMP_INSTALLED=false`), `lib/install.sh` `install_backlog_if_needed()` (L465), `lib/install.sh` `install_amp()` (L628)
- **Workaround:** Manual installation: `bun install -g backlog.md` or `npm install -g backlog.md`

### JSON Validation Falls Through Silently Without `jq`

- **Issue:** `validate_config()` calls `validate_json()` which returns 0 (success) if `jq` is not installed, effectively skipping all JSON validation
- **Files:** `lib/common.sh` `validate_json()` L182-196
- **Impact:** Invalid JSON configs pass validation silently on systems without `jq`, then cause runtime failures during config copying
- **Fix approach:** Make `jq` a hard prerequisite checked in `preflight_check()` rather than just a warning

### Transaction System Is Implemented But Never Used

- **Issue:** The transaction system (`start_transaction`, `record_action`, `rollback_transaction`, `end_transaction`) exists in `lib/common.sh` but `cli.sh` `main()` never calls `start_transaction()` or `end_transaction()`. The `--rollback` CLI flag is wired to `rollback_transaction()` but since no actions are ever recorded, it always reports "No transaction to rollback."
- **Files:** `lib/common.sh` L579-641, `cli.sh` `main()` L2160-2299
- **Impact:** Partial/failed installations leave inconsistent state; no automatic recovery path exists

### `generate.sh` Resets `SCRIPT_DIR` Globally When Sourced

- **Issue:** When `generate.sh` is sourced (e.g., by `generate.bats`), L8 unconditionally resets `SCRIPT_DIR` to the repo root. Tests must save/restore this variable carefully.
- **Files:** `generate.bats` setup/teardown (L13-22), `generate.sh` L8
- **Recommendation:** Make `SCRIPT_DIR` settable from environment: check if already set before reassigning

## Security Considerations

### Unverified External Installer Scripts

- **Issue:** Multiple external installers are executed without checksum verification:
  - OpenCode: `https://opencode.ai/install` — no checksum
  - Amp: `https://ampcode.com/install.sh` — no checksum
  - Kimi Code: `https://code.kimi.com/kimi-code/install.sh` — no checksum
  - Antigravity CLI: `https://antigravity.google/cli/install.sh` — no checksum
  - AI Launcher: `https://raw.githubusercontent.com/jellydn/ai-launcher/main/install.sh` — no checksum
  - Cursor: `https://cursor.com/install` — no checksum, piped to bash
- **Files:** `lib/install.sh` various lines
- **Impact:** MITM attack or compromised installer could execute arbitrary code; users who curl-to-bash the wrapper `install.sh` also run `cli.sh --yes` which auto-accepts all MCP/plugin installations
- **Current mitigation:** `resolve_installer_checksum()` exists but only has (empty) entries for Bun, Rust, sem, and Plannotator — and those checksums come from env vars that default to empty
- **Recommendation:** Add SHA256 pinning for all external installer URLs, or switch to package-manager-based installation where possible

### PowerShell `ExecutionPolicy Bypass` for External Installers

- **Risk:** `install.ps1` and `lib/install.sh` invoke PowerShell with `-ExecutionPolicy Bypass` to run remote scripts:
  - Kimi Code: `irm https://code.kimi.com/kimi-code/install.ps1 | iex`
  - Antigravity: `irm https://antigravity.google/cli/install.ps1 | iex`
  - herdr: `irm https://herdr.dev/install.ps1 | iex`
  - ctx: `irm https://ctx.rs/install.ps1 | iex`
  - Qoder CLI: `irm https://qoder.com/install.ps1 | iex`
  - Kiro: `irm https://kiro.dev/install.ps1 | iex`
- **Impact:** Bypasses PowerShell's security boundary; any compromise of these domains means instant code execution
- **Recommendation:** Document the risk prominently; add user confirmation prompts even in `--yes` mode for ExecutionPolicy Bypass calls

### `eval()` Usage in Core Execution Paths

- **Issue:** `execute()` uses `eval "$1"` (L256). `run_installer()` uses `eval "$check_cmd"` (L531) and `eval "$install_cmd"` (L538). `rollback_transaction()` uses `eval "$restore_cmd"` (L628).
- **Files:** `lib/common.sh` lines 249-259, 525-545, 628
- **Current mitigation:** Comment at L249 documents the risk; `execute_quoted()` was created as the safer alternative and is now used in most places
- **Risk:** Any caller that constructs a command string from untrusted input and passes it to `execute()` enables command injection
- **Recommendation:** Audit all remaining `execute()` call sites; replace with `execute_quoted()` where possible

### `curl | bash` Pattern Still Active for Cursor

- **Issue:** `lib/install.sh` L912 and L919 pipe `curl` directly to `bash` for Cursor installation
- **Risk:** If `cursor.com` is compromised or MITM'd, attacker gets shell access
- **Recommendation:** Download to temp file, verify checksum if available, then execute

### Sensitive Data in World-Readable Transaction Log

- **Issue:** `TRANSACTION_LOG` (`/tmp/ai-tools-transaction-$$.log`) is created in `/tmp` with default (world-readable) permissions
- **Files:** `lib/common.sh` L581
- **Impact:** Low — log only contains file paths and shell commands, not secrets — but still exposes user directory structure
- **Recommendation:** Use `$HOME/.ai-tools/` with `mkdir -p` instead of `/tmp`

### `cleanup_plugin_cache` Path Traversal Risk

- **Issue:** `cleanup_plugin_cache()` constructs path as `$HOME/.${cli_tool}/plugins/cache/${plugin_name}` and calls `rm -rf` on it. No validation that `$plugin_name` doesn't contain `../` or other path separators.
- **Files:** `lib/common.sh` `cleanup_plugin_cache()` (L729-752)
- **Current mitigation:** Checks if directory exists before removal (but `rm -rf` with path traversal would still be dangerous)
- **Recommendation:** Validate that `$plugin_name` contains only `[a-zA-Z0-9._-]`

## Performance Bottlenecks

### Sequential Tool Installation

- **Issue:** `cli.sh` `main()` calls 20+ `install_*()` functions in strict sequence, each blocking on network I/O for downloads and npm installs
- **Files:** `cli.sh` `main()` (L2160-2299)
- **Impact:** Full installation can take 10+ minutes; network delay in one installer blocks all subsequent ones
- **Improvement:** Run independent installations in parallel using `run_parallel()` which already exists in `lib/common.sh`

### Sequential Config Generation

- **Issue:** `generate.sh` `main()` calls 25+ `generate_*_configs()` functions sequentially, each doing independent file I/O
- **Files:** `generate.sh` `main()` (L808-905)
- **Improvement:** Parallelize independent config generation operations

### Inefficient Duplicate Slash Removal in `normalize_path()`

- **Issue:** `normalize_path()` uses a `while` loop to strip duplicate slashes one pair at a time instead of a single `sed` invocation
- **Files:** `lib/common.sh` L42-44
- **Impact:** Trivial for practical paths but indicative of defensive-inefficient pattern
- **Improvement:** Use `sed` for single-pass replacement (keeping URL/UNC path exclusions)

## Fragile Areas

### OS Detection Logic

- **Files:** `lib/common.sh` `_detect_os()` (L14-26)
- **Why fragile:** Relies on `uname -s` and `$MSYSTEM` to detect Windows environments; does not account for WSL (looks like Linux), new MSYS2 variants, or BusyBox-based environments
- **Safe modification:** Test on all supported platforms before changing (macOS, Ubuntu, Git Bash, MSYS2, Cygwin, WSL1, WSL2)
- **Test coverage:** Partial — `lib_common.bats` tests Windows temp path fallback but doesn't test actual Windows environments

### Bidirectional Sync (cli.sh ↔ generate.sh)

- **Files:** `cli.sh` (exports FROM repo TO home), `generate.sh` (exports FROM home TO repo)
- **Why fragile:** Each script can silently overwrite the other's output. Running `generate.sh` overwrites repo files with home versions; running `cli.sh` rewrites home with `rm -rf` + `safe_copy_dir`
- **Safe modification:** Always `--dry-run` first on both; verify with `git diff`
- **Test coverage:** Limited — `generate.bats` only tests `copy_single()` and `execute_quoted()` helpers; no integration test for full sync roundtrip

### Skill Symlink Management

- **Issue:** `create_tool_skills_symlinks()` removes existing skill directories and replaces them with symlinks to `~/.agents/skills/`. Tool updates may change skills directory format, breaking symlinks.
- **Files:** `cli.sh` `create_tool_skills_symlinks()` (L2071-2112)
- **Safe modification:** Verify symlink targets exist and are directories before each operation

### `local` Variable Declarations Inside Loops

- **Issue:** Multiple functions declare `local` variables inside `for`/`while` loops. In bash, `local` has function scope regardless of where it's declared, so this works — but it's misleading to readers unfamiliar with bash scoping rules.
- **Files:** `cli.sh` L1530 (`local skill_name`), L2100 (`local tool_name`), L2124 (`local existing_name`)
- **Recommendation:** Move `local` declarations to the top of each function for clarity

## Scaling Limits

### Tool Count Scaling

- **Current capacity:** ~24 AI tools with per-tool functions
- **Limit:** Each new tool requires changes in up to 6 places: (1) `copy_*_configs()` in `cli.sh`, (2) `backup_configs()` in `cli.sh`, (3) `generate_*_configs()` in `generate.sh`, (4) `install_*()` in `lib/install.sh`, (5) `main()` banner in `cli.sh`, (6) `main()` in `generate.sh`
- **Scaling path:** Registry-driven approach — single JSON/YAML config per tool describing paths, files, installer, and detection logic

### Skill Count Scaling Without Discovery

- **Current:** 18 skills in `skills/` directory
- **Limit:** Skills are hardcoded in `is_remote_skill()` function (L931-939) and the community plugins list; new skills require code changes in two places
- **Scaling path:** Auto-discover skills from `skills/` directory; use per-skill manifest files instead of hardcoded lists

### Test Suite Sequential Execution

- **Current:** CI runs tests sequentially with `bats tests/pr_*.bats tests/generate.bats tests/sh_reexec.bats`
- **Limit:** Each test sources full scripts, incurring startup overhead
- **Scaling path:** Use `bats --jobs N` for parallel execution of independent test files

## Dependencies at Risk

### `jq` as Soft Dependency

- **Risk:** `jq` is documented as a prerequisite (AGENTS.md) but treated as optional in code — `validate_json()` skips without it, MCP registry parsing falls back to legacy mode, config merging fails
- **Impact:** Without `jq`: JSON validation skipped, MCP registry installation falls back, schema validation unavailable, Kiro/CommandCode config merging fails
- **Mitigation:** `install_jq_if_needed()` attempts auto-install via brew/apt/choco/winget; but only called inside `install_global_tools()`, not in preflight

### External MCP Server Package Availability

- **Risk:** MCP servers in `configs/mcp-registry.json` are installed via `npx -y @package@latest` — if any package is unpublished, renamed, or broken, installation fails
- **Packages at risk:** `@upstash/context7-mcp`, `@modelcontextprotocol/server-sequential-thinking`, `@react-grab/mcp`, `@agentmemory/mcp`
- **Current:** Versions are unpinned; no fallback packages or local caching
- **Recommendation:** Pin specific versions, cache installation artifacts

### Gemini CLI Deprecation (June 18, 2026)

- **Risk:** Google One/unpaid tiers lose Gemini CLI access after June 18, 2026
- **Current:** Deprecation warnings shown; `--migrate-gemini` flag and `install_antigravity()` provide migration path
- **Impact:** Post-deprecation, Gemini CLI config generation code (~120 lines in `cli.sh`, ~80 lines in `generate.sh`) becomes dead weight; users on free tier need migration

### `bun` vs `node` Dual Support

- **Risk:** Codebase strongly prefers `bun`/`bunx` with `node`/`npx` fallback. Bun's package ecosystem is smaller; compatibility issues may arise.
- **Current:** Dual support maintained but Bun path is the primary and better-tested path

## Missing Critical Features

### No Automated Windows CI Testing

- **Issue:** CI runs on `ubuntu-latest` only; no Windows or macOS runners
- **Files:** `.github/workflows/test.yml`
- **Impact:** Windows-specific code has zero automated coverage: PowerShell installer, `_detect_os()`, `get_temp_dir()` Windows path, `install.ps1`
- **Priority:** High

### No `generate.sh` Integration in CI

- **Issue:** CI runs config validation tests but never executes the actual `generate.sh` script to verify export works end-to-end
- **Files:** `.github/workflows/test.yml`
- **Impact:** Regressions in `generate.sh` functions not caught until users run it manually
- **Priority:** Medium

### No Schema-Driven Config Validation in Practice

- **Issue:** `validate_config_with_schema()` exists but depends on external tools (`check-jsonschema`, `ajv-cli`, `python-jsonschema`) that are not installed in CI or preflight
- **Files:** `lib/common.sh` `validate_config_with_schema()` (L773-831)
- **Impact:** Schema validation code exists but never runs; config format bugs only caught at runtime
- **Priority:** Medium

## Test Coverage Gaps

### Missing Integration Tests

- **What's not tested:** Full `cli.sh` execution path, actual MCP server installation, plugin installation, skill symlink creation, backup/restore end-to-end
- **Risk:** Integration bugs not caught until real-world usage
- **Priority:** High

### Untested Tool-Specific Functions

- **What's not tested:** All 23+ `copy_*_configs()` in `cli.sh`, all 25+ `generate_*_configs()` in `generate.sh`, all 24+ `install_*()` in `lib/install.sh`
- **Risk:** Tool-specific bugs (wrong paths, missing files, permission issues) only discovered at runtime
- **Priority:** Medium

### Untested Windows Code Paths

- **What's not tested:** `_detect_os()`, `normalize_path()` backslash edge cases, `get_temp_dir()` Windows $TEMP, `convert_path()` cygpath, all of `install.ps1`
- **Files:** `lib/common.sh` (path functions), `install.ps1`
- **Priority:** High

### Untested Error Handling Paths

- **What's not tested:** MCP server retry/backoff logic, `safe_copy_dir` "Text file busy" skipping, `cleanup_plugin_cache` permission denied, `rollback_transaction` execution
- **Priority:** Low-Medium

---

_Concerns audit: 2026-07-04_
