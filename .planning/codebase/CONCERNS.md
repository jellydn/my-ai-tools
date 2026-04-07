# Concerns

**Analysis Date:** 2026-04-07

## Technical Debt

### Python Version Inconsistency (FIXED)

**Issue:** Mixed use of `python` vs `python3` across configs
- Some systems don't have `python` alias (only `python3`)
- This causes MCP server startup failures

**Affected Files (Fixed):**
- ✅ `configs/claude/mcp-servers.json` - Changed `python` → `python3`
- ✅ `configs/amp/settings.json` - Changed `python` → `python3`
- ✅ `configs/opencode/opencode.json` - Already used `python3`
- ✅ All other tool configs - Already consistent

**Resolution:** Standardized on `python3` across all configurations.

## Cross-Platform Compatibility

### Windows PowerShell

**Concern:** Limited testing on Windows
- PowerShell installer (`install.ps1`) exists but may have edge cases
- Some shell functions assume Unix-like paths
- Git Bash dependency for Windows users

**Mitigation:**
- Use `install.ps1` which handles Windows-specific setup
- Git for Windows includes Git Bash
- Fallback to Node.js/Bun when available

### macOS vs Linux Differences

**Minor Issues:**
- `sed` behavior differences between BSD (macOS) and GNU (Linux)
- Temporary file handling (`$TMPDIR`)
- Color output in terminal

**Current Status:** Scripts use POSIX-compliant approaches where possible.

## Security Concerns

### Low Risk

**Empty auth_token in CCS Config:**
- File: `configs/ccs/config.yaml`
- Finding: `auth_token: ""` (empty string)
- Risk: Low - placeholder value, not a leaked secret
- Note: User must populate this with their own token

### MCP Server Security

**Tool Permissions:**
- All 9 AI tools have MCP servers configured
- Tools use `stdio` transport (local execution)
- No network exposure for local MCP servers
- `context7` uses HTTPS to Upstash (external)

**Permission Levels:**
- Some tools have `permissionLevel: "high"` (Pi)
- Pre-approved MCP tools in Claude: 19 mempalace tools
- Read-only tools pre-approved, mutating require explicit approval

## Performance Concerns

### Shell Script Size

**Large Files:**
- `cli.sh`: ~63KB (2,000+ lines)
- `generate.sh`: ~15KB (400+ lines)

**Impact:**
- Slightly slower to parse
- Harder to navigate
- Single responsibility principle violation

**Mitigation:**
- Functions are well-organized
- Common code in `lib/common.sh`
- Could benefit from modularization

### JSON Validation

**Dependency:** Requires `jq` for JSON validation
- Slows down installation if many configs
- Schema validation only at runtime

**Mitigation:**
- Pre-commit hooks catch JSON syntax errors
- Schema validation via jsonschema (optional)

## Schema Validation Issues

### OpenCode Config History

**Previously Fixed:**
- `theme` property not in schema
- `_launch` property not allowed in model config
- `python` instead of `python3` for consistency

**Resolution:** Config now passes validation at `https://opencode.ai/config.json`

### Ongoing Risk

**External Schema Dependencies:**
- Configs validated against remote schemas
- Schemas may change (breaking existing configs)
- No local schema caching

**Affected Tools:**
- OpenCode: `https://opencode.ai/config.json`
- Claude: `https://json.schemastore.org/claude-code-settings.json`

## Error Handling Gaps

### Silent Failures (PARTIALLY ADDRESSED)

**Hook Scripts:**
- MemPalace hooks fail silently (`|| true`)
- This is intentional to not break workflow
- ~~But errors are not logged~~ ✅ **FIXED: Errors now logged to ~/.mempalace/logs/hooks.log**

**Files Updated:**
- ✅ `configs/claude/hooks/mempal_save_hook.sh` - Added error logging
- ✅ `configs/claude/hooks/mempal_precompact_hook.sh` - Added error logging

**Still Needed:**
- Gemini and Factory hooks could also benefit from error logging

### Network Dependencies

**One-Liner Install:**
- `curl -fsSL https://ai-tools.itman.fyi/install.sh | bash`
- Requires internet for initial clone
- No offline installation path

**MCP Server Installation:**
- `fff-mcp` downloads from GitHub
- `mempalace` from PyPI
- `context7` from Upstash

## Maintenance Concerns

### MCP Server Versioning (TODO)

**Issue:** No version pinning for MCP servers - see CONCERNS.md for details
**Files affected:** configs/*/mcp*.json (context7 uses @latest)
**Recommendation:** Pin to specific versions like `@upstash/context7-mcp@1.2.3`

### Tool Detection

**Heuristic-Based:**
- Tool detection uses `command -v` checks
- PATH changes may cause missed detections
- No explicit user override for "force install"

## Documentation Gaps

### New Tool Onboarding

**Process:** Not fully documented for adding new AI tools
- Copy existing config structure
- Add to cli.sh detection logic
- Update README.md
- No automated checklist

### Hook System

**Complexity:** MemPalace hooks have many variations
- Native hooks (Claude, Gemini, Factory)
- Polling mode (Amp, Codex, OpenCode, Pi, Kilo, CCS)
- Different syntax per tool

**Documentation:** Well documented in `docs/mempalace-auto-save-hooks.md`

## Recommendations

### High Priority
1. **Add version pinning option** for MCP servers
2. **Improve error logging** in hooks (while keeping silent failure)
3. **Add offline installation path** (bundle configs without network)

### Medium Priority
1. **Modularize cli.sh** into smaller files
2. **Add schema caching** for validation
3. **Automated tool addition checklist**

### Low Priority
1. **More Windows testing**
2. **Performance benchmarks** for large configs
3. **Integration tests** for MCP server registration

---

*Concerns analysis: 2026-04-07*
