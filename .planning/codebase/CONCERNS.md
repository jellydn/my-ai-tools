# Codebase Concerns

**Analysis Date:** 2026-04-22

## Tech Debt

**Claude Hooks Dependency:**
- Issue: Hooks in `configs/claude/hooks/` require Node.js/Bun runtime and npm dependencies
- Files: `configs/claude/hooks/package.json`, `configs/claude/hooks/index.ts`
- Impact: Installation fails if Node.js not available; hooks can't auto-format without dependencies installed
- Fix approach: Add runtime check before enabling hooks, graceful fallback to no-hooks mode

**Windows Path Handling Complexity:**
- Issue: Significant complexity in `lib/common.sh` for Windows path normalization
- Files: `lib/common.sh` (lines 28-144: `normalize_path()`, `convert_path()`, `get_temp_dir()`, etc.)
- Impact: Code is harder to maintain; edge cases with MSYS/Cygwin/WSL
- Fix approach: Consider using a portable path library or simplifying assumptions

**Large Common.sh Library:**
- Issue: `lib/common.sh` is 768 lines handling many concerns
- Files: `lib/common.sh`
- Impact: Single file doing path handling, logging, temp files, OS detection, backups, transactions
- Fix approach: Split into focused modules: `lib/path.sh`, `lib/log.sh`, `lib/backup.sh`

**MCP Server Installation Retry Logic:**
- Issue: Complex retry mechanism with exponential backoff in `install_mcp_server()`
- Files: `cli.sh` (lines 85-130 approx)
- Impact: Hard to test; may mask real network issues with retries
- Fix approach: Simplify retry logic or make configurable

## Known Issues

**Cross-Device Link Errors:**
- Symptoms: `mv` or `cp` fails with "Invalid cross-device link" error
- Files: `lib/common.sh` - `get_temp_dir()` function (line 44)
- Trigger: When `TMPDIR` is on different filesystem than target
- Workaround: `get_temp_dir()` handles Windows/Unix temp paths; uses `~/.claude/tmp` fallback

**Amp Backlog.md Dependency:**
- Symptoms: Install warning if `backlog.md` not found in Amp config
- Files: `cli.sh` - tracked via `AMP_INSTALLED` flag (lines 15, 574, 784)
- Trigger: Installing Amp without existing backlog.md
- Workaround: Warning shown but installation continues

**JSON Validation Edge Cases:**
- Symptoms: May not catch all invalid JSON if jq not installed
- Files: `copy_configurations()` in `cli.sh`
- Trigger: Malformed JSON in configs when jq unavailable
- Workaround: Preflight check ensures jq is available before installation

## Security Considerations

**Script Execution from curl:**
- Risk: Users running `curl | bash` without reviewing script
- Files: `install.sh`, documented in README.md
- Current mitigation: README has security note with review instructions
- Recommendations: Add signature verification or checksum validation

**Temporary File Cleanup:**
- Risk: Temp files with sensitive data might not be cleaned up on crash
- Files: `lib/common.sh` - `make_temp_file()` (line 203), `make_temp_dir()` (line 213)
- Current mitigation: Manual `rm -f` cleanup after use; no global trap
- Recommendations: Add trap-based cleanup or ensure all temp files deleted after use

**Path Injection:**
- Risk: User-controlled paths could inject commands
- Files: Various functions accepting paths as arguments
- Current mitigation: Proper quoting of variables: `"$variable"` used consistently
- Recommendations: Add path validation/sanitization functions

## Performance Bottlenecks

**MCP Server npx Installation:**
- Problem: Installing MCP servers via npx can be slow (network dependent)
- Files: `cli.sh` - `install_mcp_server()` calls
- Cause: Each npx install downloads packages from npm
- Improvement path: Cache npx packages or use global installs with version pinning

**Large Config Copy Operations:**
- Problem: Copying entire skill directories can be slow
- Files: `copy_directory()` function
- Cause: Recursive copy of many small files
- Improvement path: Use rsync or parallel copy for large directories

**Git Status Checks:**
- Problem: `is_non_interactive()` (line 657) checks CI/pipe status on every call
- Files: `lib/common.sh`
- Cause: Called frequently in `cli.sh` (line 57), checks environment each time
- Improvement path: Cache result in global variable after first check

## Fragile Areas

**OS Detection Logic:**
- Files: `lib/common.sh` - `_detect_os()` function (lines 14-26)
- Why fragile: Relies on `$OSTYPE` and `$MSYSTEM` environment variables which may vary
- Safe modification: Test on Windows (Git Bash, MSYS2, Cygwin, WSL) after any changes
- Test coverage: Limited automated testing for Windows paths

**MCP Server Configuration Format:**
- Files: `configs/claude/mcp-servers.json`, `configs/amp/settings.json`
- Why fragile: Different tools use different MCP config schemas
- Safe modification: Update both locations, validate JSON schema
- Test coverage: JSON validation catches syntax errors but not semantic mismatches

**Hook System Dependencies:**
- Files: `configs/claude/hooks/index.ts`
- Why fragile: Depends on Node.js ecosystem (bun/node, npm, package.json)
- Safe modification: Test hooks independently with `bun run` before committing
- Test coverage: No automated tests for TypeScript hooks

**Bidirectional Sync Edge Cases:**
- Files: `generate.sh` (1948 lines) - export functionality
- Why fragile: May overwrite local changes if not careful
- Safe modification: Always use `--dry-run` first, verify with `git diff`
- Test coverage: Limited - relies on manual testing

## Scaling Limits

**Config Repository Size:**
- Current capacity: 11 AI tools configured
- Limit: Manual maintenance required for each new tool
- Scaling path: Consider automated config generation from templates

**Skill Count:**
- Current: 12 skills
- Limit: No automated discovery - each skill must be manually registered in `cli.sh`
- Scaling path: Auto-discover skills from `skills/` directory

**Test Execution Time:**
- Current: < 1 second for all tests
- Limit: Bats runs tests sequentially
- Scaling path: Tests currently fast; split into parallel batches if needed

## Dependencies at Risk

**Bun vs Node.js:**
- Risk: Bun not as widely adopted as Node.js
- Impact: Some users may not have Bun installed
- Migration plan: Already has Node.js fallback, but Bun is preferred

**jq Dependency:**
- Risk: jq is required but not always pre-installed
- Impact: Installation fails without jq
- Migration plan: Auto-install jq in preflight or provide clearer error messages

**MCP Server Packages:**
- Risk: MCP servers distributed via npm may break or be unpublished
- Impact: MCP functionality unavailable
- Migration plan: Pin to specific versions, document alternatives

## Missing Critical Features

**Automated Windows Testing:**
- Problem: No CI/CD tests for Windows (PowerShell, Git Bash)
- Blocks: Confidence in Windows compatibility
- Priority: High

**Configuration Validation:**
- Problem: No schema validation for AI tool configs
- Blocks: Early detection of invalid settings
- Priority: Medium

**Rollback After Failed Install:**
- Problem: Transaction system exists but rollback not automatically triggered
- Blocks: Clean recovery from partial installations
- Priority: Medium

## Test Coverage Gaps

**Windows-Specific Functions:**
- What's not tested: `normalize_path()`, `convert_path()`, Windows OS detection
- Files: `lib/common.sh` lines 28-144
- Risk: Windows compatibility regressions
- Priority: High

**MCP Server Installation:**
- What's not tested: `install_mcp_server()` retry logic, actual npx calls
- Files: `cli.sh`
- Risk: Network failures not handled gracefully
- Priority: Medium

**Export/Generate Functionality:**
- What's not tested: `generate.sh` functions, bidirectional sync
- Files: `generate.sh`
- Risk: Export may corrupt user configs
- Priority: Medium

**Hook System:**
- What's not tested: TypeScript hooks, PostToolUse formatting
- Files: `configs/claude/hooks/index.ts`
- Risk: Auto-formatting breaks, no early detection
- Priority: Low

---

*Concerns audit: 2026-04-22*
