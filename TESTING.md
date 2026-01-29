# 🚀 Testing Guide

## 📋 Quickstart

Run tests locally to verify changes:

```bash
bun test
```

## 🔁 CI/Non-Interactive Mode

For automated testing, run with fail-fast to catch issues quickly:

```bash
bun test --fail-fast
```

Expected exit codes:
- `0` - All tests passed
- `1` - Tests failed (CI should fail on this)