# 🚀 Testing Guide

## 📋 Quickstart

Run shell script syntax check to verify changes:

```bash
bash -n cli.sh
```

## 🔁 CI/Non-Interactive Mode

For automated validation, check all scripts with syntax validation:

```bash
bash -n cli.sh generate.sh && echo "All scripts valid"
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
