# Concerns

This document outlines technical debt, known issues, security concerns, and fragile areas in the my-ai-tools codebase.

---

## 🔴 High Priority Issues

### 1. Shell Script Security - Pipe to Shell Execution

**Location:** `cli.sh` lines 167, 156, 194

**Issue:** The installer uses `curl | bash` pattern which executes remote code without verification.

```bash
curl -fsSL https://bun.sh/install | bash
```

**Risk:** This is a common security anti-pattern. If the remote server is compromised, arbitrary code executes with user privileges.

**Recommendation:**
- Use the verified installer pattern from `lib/common.sh` (`download_and_verify_script` and `execute_installer`)
- Add SHA256 checksum verification for all downloaded installer scripts
- Document the security trade-off clearly for users

**Current Mitigations:**
- Some scripts use checksum verification via `download_and_verify_script` in `lib/common.sh`
- README includes security note: "Review the script before running"

---

### 2. eval() Usage for Command Execution

**Location:** `lib/common.sh` lines 47-52

**Issue:** The `execute()` function uses `eval "$1"` which can be dangerous if any input contains shell metacharacters.

```bash
execute() {
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] $1"
    else
        eval "$1"
    fi
}
```

**Risk:** Potential for shell injection if variables are not properly quoted throughout the codebase.

**Recommendation:**
- Avoid `eval` where possible; use function calls or arrays
- Ensure all variables passed to execute are properly quoted
- Consider using `$()` instead of `eval` where appropriate

---

### 3. Cross-Platform Path Handling Inconsistencies

**Location:** Multiple locations in `cli.sh` and `generate.sh`

**Issue:** The codebase attempts to handle Windows (msys/win32) vs Unix-like systems, but path handling may be inconsistent:

- `$HOME` expansion works differently on Windows
- File paths with spaces may cause issues in `execute()` calls
- Some paths use backslashes, others use forward slashes

**Example:**
```bash
# IS_WINDOWS detection exists but may not cover all edge cases
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || -n "$MSYSTEM" ]]; then
    IS_WINDOWS=true
fi
```

**Risk:** Configuration may fail silently on Windows systems or in mixed environments.

---

## 🟠 Medium Priority Issues

### 4. Claude-Mem Deprecation

**Location:** `README.md` line 1289

**Issue:** References to deprecated `claude-mem` remain in documentation, though marked as deprecated.

**Impact:** Users may still try to use the old system; no automated migration path exists.

**Status:**
- Documented as deprecated in README
- Redirected to qmd-based knowledge system
- See `docs/qmd-knowledge-management.md` for migration guide

---

### 5. MCP Server Installation Error Handling

**Location:** `cli.sh` lines 82-99

**Issue:** MCP server installation failures are silently logged or only partially reported.

```bash
if grep -qi "already" "$err_file" 2>/dev/null; then
    log_info "${server_name} already installed"
else
    log_warning "${server_name} installation failed - check $err_file for details"
fi
```

**Risk:** Users may not notice failures; no retry mechanism exists.

---

### 6. Backup Cleanup Path Traversal

**Location:** `lib/common.sh` lines 87-102

**Issue:** The backup cleanup uses find with glob patterns that could be affected by symlinks.

```bash
old_backups=$(find "$HOME" -maxdepth 1 -type d -name "${backup_pattern##*/}*" ...)
```

**Risk:** Potential for unexpected behavior if symlinks exist in home directory.

---

### 7. Git Hook Security - Blocked Patterns May Be Incomplete

**Location:** `configs/claude/hooks/git-guard.ts`

**Issue:** The git guard hook blocks known dangerous commands, but may miss edge cases or new patterns.

**Current Coverage:**
- `git push --force` / `-f`
- `git reset --hard`
- `git clean -fd`
- `git branch -D`
- `git rebase -i`
- `git checkout --force` / `-f`
- `git stash drop/clear`

**Risk:** Sophisticated users may bypass with variations; no allowlist mechanism for legitimate use cases.

---

### 8. Plugin Cache Cleanup Missing Error Handling

**Location:** `cli.sh` lines 1299, 1361

**Issue:** Cache cleanup failures are silenced with `|| true`.

```bash
execute "rm -rf '$HOME/.$cli_tool/plugins/cache/$name' 2>/dev/null || true"
```

**Risk:** Disk space may not be properly reclaimed on failure; silent failures hide real issues.

---

## 🟡 Low Priority Issues

### 9. Missing JSON Schema Validation

**Issue:** While all JSON files validate syntactically, they lack schema validation against recognized schemas (e.g., `$schema` fields are present but not validated at install time).

**Affected Files:**
- `configs/claude/settings.json`
- `configs/claude/mcp-servers.json`
- `configs/opencode/opencode.json`
- All other tool configurations

**Risk:** Invalid configurations may be installed and only fail at runtime.

---

### 10. Hooks TypeScript Dependencies Minimal

**Location:** `configs/claude/hooks/package.json`

**Issue:** Only `devDependencies` are defined; no runtime dependencies. This relies on global Bun installation.

```json
{
  "devDependencies": {
    "bun-types": "latest",
    "@types/node": "latest"
  }
}
```

**Risk:** Running hooks may fail if Bun is not in PATH; no error messaging.

---

### 11. Parallel Execution Race Conditions

**Location:** `lib/common.sh` lines 151-185

**Issue:** The `run_parallel()` function uses background processes but may have timing issues.

```bash
(
    eval "$cmd"
) &
```

**Risk:** Commands that depend on shared state (e.g., npm registry rate limits) may fail unpredictably.

---

### 12. Transaction Rollback Incomplete

**Location:** `lib/common.sh` lines 226-251

**Issue:** Transaction rollback uses `eval` without checking for partial failures.

```bash
eval "$restore_cmd" 2>/dev/null || true
```

**Risk:** Complex rollback operations may partially fail, leaving system in inconsistent state.

---

### 13. Non-Interactive Mode Detection

**Location:** `cli.sh` lines 29-32

**Issue:** Auto-detection of non-interactive mode (`[ ! -t 0 ]`) may give false positives when scripts are piped.

```bash
if [ ! -t 0 ]; then
    YES_TO_ALL=true
fi
```

**Risk:** Scripts may run with `--yes` when user expects interactive prompts.

---

### 14. Skill Installation Filtering Complexity

**Location:** `generate.sh` lines 91-106, 148-166

**Issue:** Skills filtering logic uses multiple `case` statements with hardcoded exclusions:

```bash
case "$skill_name" in
prd | ralph | qmd-knowledge)
    # Skip marketplace plugins - managed separately
    ;;
*)
    # ...
    ;;
esac
```

**Risk:** New marketplace skills must be manually added to exclusion lists; easy to miss.

---

## 🔵 Fragile Code Areas

### 15. Configuration Directory Detection

**Location:** Multiple locations in `cli.sh` (lines 836, 849, 874, etc.)

**Issue:** Tools are detected by either directory existence OR command availability, which can lead to inconsistent behavior:

```bash
if [ -d "$HOME/.config/opencode" ] || command -v opencode &>/dev/null; then
```

**Risk:** May install configs for tools that aren't fully configured; command may exist but config directory may be incompatible version.

---

### 16. Template Variable Substitution

**Location:** `generate.sh` and `cli.sh`

**Issue:** Uses shell string expansion for path manipulation, which can fail with unusual characters:

```bash
local settings_source="${filepath##*/}"
```

**Risk:** Files with non-standard naming may fail to copy correctly.

---

### 17. CCS Configuration Validation Gap

**Location:** `configs/ccs/config.yaml`

**Issue:** YAML validation is optional (requires python3 or ruby), and config may be invalid.

**Current Status:** Config file has `DISABLE_BUG_COMMAND: "1"` commented as workaround for proxy limitations.

---

## 📋 Known Limitations

### 18. Platform-Specific Tool Installation

**Issue:** Some tool installation commands are Linux-specific (apt-get, rustup):

```bash
execute "sudo apt-get install -y jq"
execute "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
```

**Limitation:** No macOS/Homebrew equivalents for all tools.

---

### 19. API Key Management

**Issue:** No built-in mechanism for API key rotation or secure storage. Keys are stored in config files.

**Risk:** Config files may be committed accidentally to version control (mitigated by `.gitignore`).

---

### 20. MCP Server Version Pins

**Issue:** MCP servers use `latest` tag, which may cause unexpected behavior:

```bash
"args": ["-y", "@upstash/context7-mcp@latest"]
```

**Risk:** Breaking changes in MCP server updates may break functionality without notice.

---

## 🎯 Recommendations Summary

| Priority | Issue | Recommended Action |
|----------|-------|-------------------|
| High | Pipe to shell | Use checksum verification |
| High | eval usage | Refactor to functions |
| High | Cross-platform paths | Standardize on helper functions |
| Medium | MCP errors | Add retry logic |
| Medium | Git guard | Add allowlist mechanism |
| Low | JSON schemas | Add install-time validation |
| Low | Hook dependencies | Add runtime deps or bundle |
| Low | Transaction rollback | Improve error handling |

---

## 📝 Notes

- All TODOs found in codebase relate to pr-review skill functionality (extracting PR comments to TODO lists), not code issues
- JSON validation: All config files pass `jq .` validation
- Shell scripts pass `bash -n` syntax checking
- No security vulnerabilities identified beyond documented concerns
