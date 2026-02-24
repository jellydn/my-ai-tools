# 🤖 Gemini CLI Agent Guidelines

- Follow my software development practice @~/.ai-tools/best-practices.md
- Read @~/.ai-tools/MEMORY.md first - Understand when and how to use qmd for knowledge management
- Keep responses concise and actionable.
- Always propose a plan before edits. Use phases to break down tasks into manageable steps.
- Run typecheck, lint and biome on js/ts file changes after finish
- Prefer to use Bun to run scripts if possible, otherwise use tsx to run ts files.
- Never run destructive commands.
- Use our conventions for file names, tests, and commands.
- Keep your code clean and organized. Do not over-engineer solutions or overcomplicate things unnecessarily.
- Write clear and concise code. Avoid unnecessary complexity and redundancy.
- Use meaningful variable and function names.
- Prefer self-documenting code. Write comments and documentation where necessary.
- Keep your code modular and reusable. Avoid tight coupling and excessive dependencies.

## Git Safety Guidelines

### ✅ Allowed Git Operations
- Read operations: `git status`, `git log`, `git diff`, `git show`
- Safe commits: `git add`, `git commit`
- Branch management: `git branch`, `git checkout -b`, `git switch`
- Safe push: `git push` (standard push without force)

### ⛔ Operations to Avoid
Avoid these dangerous git commands without explicit user approval:
- **Force push**: `git push --force`, `git push -f`
- **History rewriting**: `git rebase -i`, `git filter-branch`
- **Amending pushed commits**: `git commit --amend` (only safe for unpushed commits)
- **Destructive resets**: `git reset --hard`
- **Force operations**: `git checkout --force`, `git clean -f/-d`, `git branch -D`
- **Stash deletion**: `git stash drop`, `git stash clear`

### Best Practices
- Always use `git --no-pager` to prevent interactive pagers in scripts
- Check repository state with `git status` before operations
- Use `git diff` to verify changes before committing
- Use descriptive commit messages following conventional commits format
- Pull before push to avoid conflicts
