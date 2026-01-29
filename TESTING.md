# 🚀 Testing Guide for One-Line Installer Fixes

## 📋 Issues Fixed

1. **TMPDIR cross-device link errors**: Set TMPDIR before running external installers to avoid cross-device link errors when tmp is on different filesystem
2. **Busy binary copies**: Use safe_copy_dir with rsync fallback to handle "Text file busy" errors when copying in-use binaries  
3. **Non-interactive mode**: Auto-detect piped stdin and forward --yes flag to cli.sh for non-interactive installs

## 📋 Testing the Fixes

### 🎨 Test 1: Syntax Validation

Validate syntax for `@cli.sh`, `@install.sh`, and `@lib/common.sh`:

```bash
# Check bash syntax
bash -n cli.sh
bash -n install.sh
bash -n lib/common.sh

# Check shellcheck (if available)
shellcheck cli.sh install.sh lib/common.sh
```

### 🎨 Test 2: One-Line Installer (Non-Interactive)

Test the one-line installer with piped input to verify non-interactive mode:

```bash
# Simulate piped installation (non-interactive)
echo "" | curl -fsSL https://raw.githubusercontent.com/jellydn/my-ai-tools/main/install.sh | bash

# Or with explicit --yes flag
bash install.sh --yes
```

### 🎨 Test 3: Manual Testing with --yes Flag

Test direct execution with --yes flag:

```bash
# Run with --yes flag
./cli.sh --yes

# Run with --dry-run to preview changes
./cli.sh --dry-run --yes

# Run with --dry-run without --yes (should prompt)
./cli.sh --dry-run
```

### 🎨 Test 4: TMPDIR Handling

Test TMPDIR behavior with different configurations:

```bash
# Test with valid TMPDIR
export TMPDIR=/tmp
./cli.sh --dry-run --yes

# Test with invalid TMPDIR (should fallback to $HOME/.claude/tmp)
export TMPDIR=/invalid/path
./cli.sh --dry-run --yes

# Test with unset TMPDIR
unset TMPDIR
./cli.sh --dry-run --yes
```

### 🎨 Test 5: Safe Copy for Busy Files

Test safe_copy_dir function with in-use files:

```bash
# Create a test scenario with a busy file
mkdir -p /tmp/test-copy
echo "test" > /tmp/test-copy/file.txt

# Test safe_copy_dir
source lib/common.sh
safe_copy_dir /tmp/test-copy /tmp/test-dest

# Verify the copy succeeded
ls -la /tmp/test-dest/
```

## 📋 Expected Behavior

### 🎨 Interactive Mode (Normal Terminal)

When running in an interactive terminal:
- Prompts appear for user confirmation
- `--yes` flag bypasses prompts
- `--backup` flag enables automatic backup
- `--dry-run` flag previews changes

### 🎨 Non-Interactive Mode (Piped Input)

When stdin is piped (e.g., `curl ... | bash`):
- Auto-detected by checking if stdin is a terminal
- Automatically enables `--yes` mode
- No interactive prompts
- Suitable for automated deployments

### 🎨 TMPDIR Usage

The installer handles TMPDIR as follows:
- Checks if TMPDIR is set and writable
- Falls back to `$HOME/.claude/tmp` if not
- Creates directory with `mkdir -p` if needed
- Uses `/tmp` as last resort
- All log output goes to stderr to avoid capturing in command substitution

### 🎨 Busy File Handling

The safe_copy_dir function:
- Uses `cp -r` for normal file copies
- Falls back to `rsync -a --ignore-errors` if cp fails (indicating busy files)
- Logs informative messages
- Respects dry-run mode

## 📋 CI/CD Integration

For CI/CD pipelines, use the non-interactive mode:

```bash
# In GitHub Actions or other CI systems
curl -fsSL https://raw.githubusercontent.com/jellydn/my-ai-tools/main/install.sh | bash

# Or explicitly with --yes
./cli.sh --yes --backup
```

## 📋 Debugging

If issues occur, check the following:

1. **TMPDIR errors**: Check if TMPDIR points to valid, writable directory
   ```bash
   ls -la "$TMPDIR"
   ```

2. **Log output**: Logs are sent to stderr, so redirect stderr to see them
   ```bash
   ./cli.sh --dry-run 2>&1
   ```

3. **Dry-run preview**: Always use `--dry-run` to preview changes before executing
   ```bash
   ./cli.sh --dry-run
   ```

4. **Shell script validation**: Use shellcheck to find potential issues
   ```bash
   shellcheck cli.sh lib/common.sh
   ```

Reference files:
- `@cli.sh` - Main installation script
- `@install.sh` - One-line installer wrapper
- `@lib/common.sh` - Shared utility functions
