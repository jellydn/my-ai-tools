# Autoresearch Ideas: Future-Proof cli.sh and generate.sh

## Deferred Optimizations (Promising but deferred)

### 1. Configuration-Driven Tool Installation
Extract the tool installation logic from hardcoded functions into a JSON/YAML config file.
Current: 10+ nearly identical `install_*()` functions
Future: Single `install_tool()` function that reads from config

### 2. Unified Copy/Backup Logic
Both scripts have similar directory copying logic with slight variations.
Current: `safe_copy_dir`, `copy_config_dir`, `copy_config_file` duplicated
Future: Single robust `copy_artifact()` function in common.sh

### 3. Parallel Execution Framework
Plugin installations could be truly parallel with job control.
Current: Basic parallel block with `&` and `wait`
Future: Proper xargs/parallel with controlled concurrency

### 4. Template-Based Config Generation
Generate configs from templates instead of hardcoded paths.
Current: Hardcoded paths like `$HOME/.claude/settings.json`
Future: Template with `${CONFIG_DIR}/settings.json` substitution

## Active Optimizations

### Phase 1: Shellcheck Compliance (In Progress)
- Fix unquoted variables in execute() calls
- Address SC2086 (double quote to prevent globbing)
- Fix SC2129 (multiple echo statements)
- Address SC2002 (useless cat)

### Phase 2: Code Deduplication (In Progress)
- Extract common tool installation pattern
- Unify the `prompt_and_install` wrapper functions
- Consolidate platform detection

### Phase 3: Robustness
- Add trap-based cleanup
- Improve error propagation
- Validate JSON configs before copying

## Risk Areas
- Breaking changes to CLI interface
- Compatibility with different bash versions (3.2+ on macOS)
- Windows Git Bash compatibility
