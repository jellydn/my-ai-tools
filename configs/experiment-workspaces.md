## Experiment Workspaces

- When the [`try` CLI](https://github.com/tobi/try) is available, use it to create isolated experiment directories and Git worktrees. my-ai-tools does not install it.
- Prefer `try . <name>` for a worktree from the current repository, `try clone <url> [name]` for an external repository, and `try new <name>` for a fresh experiment.
- `try` creates `$TRY_PATH/YYYY-MM-DD-<name>` (default `TRY_PATH`: `~/src/tries`) and changes directory only in the invoking shell. Use the printed path in later commands.
- `try .` worktrees and `try clone` of a pull request URL start on a detached HEAD. Run `git switch -c <branch>` in the experiment directory before you commit.
- Keep experiments in `try`-managed directories instead of ad hoc `/tmp` folders. Fall back to `git worktree add -b <branch> <path>` only when `try` is unavailable or unsuitable.
