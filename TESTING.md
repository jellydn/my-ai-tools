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

Expected exit codes:
- `0` - Syntax is valid
- `1` - Syntax error found (CI should fail on this)