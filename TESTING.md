# 🚀 Testing Guide

## 📋 Quickstart

Run shell script syntax check to verify changes:

```bash
bash -n cli.sh
```

### Windows installer prerequisites

Run the isolated prerequisite tests with Windows PowerShell 5.1 or PowerShell 7:

```powershell
powershell -NoProfile -File tests/windows_installer.ps1
# PowerShell 7 (also works on Linux):
pwsh -NoProfile -File tests/windows_installer.ps1
```

These tests use temporary executable fixtures and a simulated `winget`; they do not install software or run
`cli.sh`. They cover first installation with stale command lookup, inherited PATH, repeated runs, dry-run,
custom Git locations, existing tools, WSL launcher rejection, missing/failed `winget`, and restart guidance.
Native Windows CI runs them under PowerShell 5.1 before the real `-DryRun -Yes` smoke test. The Bats Windows
suite also runs them when `pwsh` is available. Actual package downloads and administrator approval still need
a clean Windows 11 machine for end-to-end validation.

## 🔁 CI/Non-Interactive Mode

For automated validation, check all scripts with syntax validation:

```bash
bash -n cli.sh generate.sh install.sh lib/*.sh scripts/*.sh && echo "All scripts valid"
```

## 🧹 Code Quality Checks

### Pre-commit Hooks

Run pre-commit hooks to validate code quality:

```bash
# Run all pre-commit hooks on staged files
pre-commit run

# Run all pre-commit hooks on all files
pre-commit run --all-files
```

### Biome Formatting

Format TypeScript/JavaScript and JSON files:

```bash
# Check formatting without modifying files
biome check .

# Format files in-place
biome check --write .
```

## 🧪 Functional Testing with BATS

Functional tests are written using the [BATS (Bash Automated Testing System)](https://github.com/bats-core/bats-core) framework.

### Prerequisites

You must have BATS installed on your system:

```bash
# On macOS (Homebrew)
brew install bats-core

# On Ubuntu/Debian
sudo apt-get install bats
```

### Running Tests

To run all functional tests:

```bash
bats tests/
```

To run a specific test file:

```bash
bats tests/recommend_skills.bats
```

Expected exit codes:

- `0` - Syntax is valid
- `1` - Syntax error found (CI should fail on this)
