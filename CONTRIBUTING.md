# Contributing to AI Tools Setup Guide

Thank you for your interest in contributing! This guide helps others replicate your AI development environment setup.

## How to Contribute

### 1. Adding New Tools

To add a new AI tool to the setup guide:

1. Create a new directory under `configs/` (e.g., `configs/newtool/`)
2. Add configuration files to that directory
3. Update `README.md` with installation and configuration instructions
4. Update `cli.sh` to support installing and configuring the new tool

### 2. Improving Existing Configs

If you want to improve or add features to existing configurations:

1. Update the relevant config file in `configs/<tool>/`
2. Update `README.md` if the changes affect user workflow
3. Test changes with `./cli.sh --dry-run` first

### 3. Adding Best Practices

This guide includes software development best practices. To contribute:

1. Add markdown content to `configs/best-practices.md`
2. Reference it in OpenCode configurations if applicable

## Submission Guidelines

1. Keep configurations portable and self-contained
2. Use relative paths (avoid absolute paths like `/Users/username/`)
3. Add comments to explain non-obvious settings
4. Test the setup script before submitting changes

## Style Guide

- Follow the zed-101-setup README format pattern
- Use emoji headers for visual hierarchy
- Include copy-paste ready code blocks
- Keep installation commands simple and verified

## Questions?

Open an issue or reach out via the support channels listed in README.md.
