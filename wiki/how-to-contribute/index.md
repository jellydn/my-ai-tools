# How to Contribute

Guidelines for contributing to my-ai-tools.

## Adding New Tools

1. Create a new directory under `configs/` (e.g., `configs/newtool/`)
2. Add configuration files to that directory
3. Update `README.md` with installation and configuration instructions
4. Update `cli.sh` to support installing and configuring the new tool

## Improving Existing Configs

1. Update the relevant config file in `configs/<tool>/`
2. Update `README.md` if the changes affect user workflow
3. Test changes with `./cli.sh --dry-run` first

## Testing Changes

Before submitting changes:

1. **Shell syntax check:**
   ```bash
   bash -n cli.sh
   bash -n generate.sh
   ```

2. **Dry-run testing:**
   ```bash
   ./cli.sh --dry-run
   ```

3. **Export testing:**
   ```bash
   ./generate.sh --dry-run
   ```

## Pre-commit Checklist

- [ ] Shell scripts pass `bash -n` syntax check
- [ ] Tested with `--dry-run`
- [ ] No absolute paths in configs
- [ ] Colors and logging functions used consistently
- [ ] Error handling with `set -e` and guard clauses
- [ ] Documentation updated if workflow changed
- [ ] Git operations follow safety guidelines
