# Testing Guide for One-Line Installer Fixes

This document explains how to test the fixes for the one-line installer issues.

## Issues Fixed

1. **File not found error during installation** - Temp files were created in `/tmp/` which might be on a different filesystem
2. **"Text file busy" error** - Copying running binary files failed  
3. **Non-interactive mode stopping** - Script would hang when piped via curl
4. **Log messages interfering with command substitution** - Log functions output to stdout caused captured output to contain log messages instead of return values

## Testing the Fixes

### Test 1: Syntax Validation
```bash
bash -n cli.sh
bash -n install.sh
bash -n lib/common.sh
```
All files should have valid bash syntax.

### Test 2: One-Line Installer (Non-Interactive)
```bash
# Simulate the curl | bash pattern
curl -fsSL https://ai-tools.itman.fyi/install.sh | bash
```
This should:
- Not prompt for user input
- Auto-accept all installations with --yes flag
- Complete without hanging

### Test 3: Manual Testing with --yes Flag
```bash
# Run with --yes flag
./cli.sh --yes --dry-run

# Should see output like:
# "Auto-accepting backup (--yes flag)"
# "Auto-accepting OpenCode installation (--yes flag)"
# etc.
```

### Test 4: TMPDIR Handling
```bash
# Set custom TMPDIR
export TMPDIR="$HOME/.claude/tmp"
mkdir -p "$TMPDIR"

# Run installer
./cli.sh --dry-run

# Check that temp files are created in TMPDIR, not /tmp
```

### Test 5: Safe Copy for Busy Files
```bash
# Start a process that uses cliproxy binaries (if available)
# Then try to copy configs
./cli.sh --dry-run

# Should not fail with "Text file busy" error
# Should use rsync or fallback method
```

### Test 6: Log Functions Output to stderr
```bash
# Test that log messages don't interfere with command substitution
source lib/common.sh

test_func() {
    log_info "Test message"
    echo "return_value"
}

# This should capture only "return_value", not the log message
result=$(test_func)
echo "Captured: $result"

# Expected: result="return_value"
# Log message should appear on screen but not in $result
```

## Expected Behavior

### Interactive Mode (Normal Terminal)
- Script prompts for each installation
- User can choose y/n for each component

### Non-Interactive Mode (Piped Input)
- Script automatically proceeds with --yes flag
- No prompts, auto-accepts all installations
- Completes fully without user interaction

### TMPDIR Usage
- External installers use `$HOME/.claude/tmp` via `execute_installer`
- Direct downloads fall back to `/tmp/` if TMPDIR not set
- `execute_installer` always sets TMPDIR to avoid cross-device link errors

### Busy File Handling
- Cliproxy binaries copied using `safe_copy_dir`
- Uses rsync if available
- Falls back to per-file copy with error handling
- Skips files that are currently in use

## CI/CD Integration

To test in CI/CD environments:
```bash
# Non-interactive mode should work without stdin
./cli.sh --yes --dry-run < /dev/null
```

## Debugging

If issues occur, check:
1. `$TMPDIR` environment variable value
2. Permissions on `$HOME/.claude/tmp`
3. Whether files in `.ccs/cliproxy/bin` are running
4. stdin availability with `[ -t 0 ]` test
5. Log messages appearing in captured variables (should output to stderr only)
