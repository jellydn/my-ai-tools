---
"my-ai-tools": patch
---

## POSIX-compat re-exec guard extraction and test simplification

### What

Extract the duplicated 9-line re-exec guard from `generate.sh` and `cli.sh` into a single canonical POSIX-compatible shim at `lib/require_bash.sh`. Both entry-point scripts now `source` this shim as their first non-shebang line, transparently re-launching under `bash` if invoked via `sh`/`dash` (also detects macOS where `/bin/sh` IS bash in POSIX mode). Collapse the bats test suite from 8 static checks (4 duplicated across two scripts) to 4 (one per assertion, covering both scripts).

### Why

`cli.sh` and `generate.sh` are flagged as `#!/bin/bash` because `lib/common.sh` uses bash-only syntax — process substitution (`<(...)`), arrays (`local -a arr=(...)`), and parameter expansion (`${var//pat/repl}`) — that `sh`/`dash` cannot parse. These features were chosen for clarity and ergonomics:

- **Process substitution** lets `while read ... done < <(find ...)` and `while read ... done < <(jq ...)` feed command output into a loop in the current shell (a pipe would create a subshell and lose variable updates). POSIX alternatives require temp files.
- **Arrays** (`local -a exclude_dirs=(...)`, `local required_tools=(...)`, `local pids=()`, `local summary_lines=()`) are used for accumulation, fixed lists, and queueing parallel-job PIDs. POSIX alternatives are `set --` for fixed lists and temp files for accumulation.
- **Parameter expansion** (`${path//\//}` to replace backslashes, `${arg//\"/\\\"}` to escape quotes) is more readable than the `printf | sed` equivalent. POSIX `printf '%b\n'` and `sed` are the portable substitutes.

### How

1. `lib/require_bash.sh` is intentionally POSIX-compatible so `sh` can source it and trigger the re-exec *before* `lib/common.sh` is reached.
2. Both `generate.sh` and `cli.sh` `source` `lib/require_bash.sh` as their first non-shebang line (before `set -e` and before any `lib/common.sh` source).
3. The shim is single-sourced (no duplication), trivially auditable, and tested with `sh -n` syntax checks plus 6 behavioral tests on `sh generate.sh --dry-run`.

### Trade-offs

- `lib/require_bash.sh` adds a 32-line POSIX shim and a bats test file. This is real machinery, justified by the fact that `sh cli.sh` and `sh generate.sh` transparently work on any Unix-like system.
- The guard is a *symptom* fix, not a *root-cause* fix. The root cause (`lib/common.sh` using bash-only syntax) is also resolved in this branch: process substitution is replaced with temp files, arrays with `set --` and temp files, and parameter expansion with `printf | sed`. After that change, `lib/common.sh` is verified to source cleanly under `dash` at runtime. The guard still remains in place because `cli.sh` has ~10 bash arrays pending the same treatment.
- The shebang on `lib/common.sh` is still `#!/bin/bash` even though the file is now POSIX-compatible. This is intentional: the file is sourced (not executed), so the shebang is cosmetic. Changing it to `#!/bin/sh` would signal the new POSIX-compat intent but is not required for correctness.
