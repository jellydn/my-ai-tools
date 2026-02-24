# Git Safety Guidelines

## Safe Git Operations
AI agents should follow these principles when working with git:

### ✅ Allowed Operations
- **Read operations**: `git status`, `git log`, `git diff`, `git show`
- **Safe commits**: `git add`, `git commit`
- **Branch management**: `git branch`, `git checkout -b`, `git switch`
- **Safe push**: `git push` (standard push without force)
- **Inspection**: `git blame`, `git ls-files`, `git rev-parse`

### ⛔ Operations to Avoid
Avoid these dangerous git commands without explicit user approval:
- **Force push**: `git push --force`, `git push -f` (not recommended; if absolutely required, `--force-with-lease` is safer)
- **History rewriting**: `git rebase -i`, `git filter-branch`
- **Amending pushed commits**: `git commit --amend` (only safe for local, unpushed commits)
- **Destructive resets**: `git reset --hard`
- **Force operations**: `git checkout --force`, `git clean -f/-d`, `git branch -D`
- **Stash deletion**: `git stash drop`, `git stash clear`
- **Reference manipulation**: `git update-ref -d`, `git reflog expire`

### Best Practices
- Always use `git --no-pager` to prevent interactive pagers in scripts
- Check repository state with `git status` before operations
- Use `git diff` to verify changes before committing
- Prefer `git switch` over `git checkout` for branch switching (Git 2.23+; use `git checkout <branch>` for older versions)
- Use descriptive commit messages following conventional commits format
- Create feature branches instead of working directly on main/master
- Pull before push to avoid conflicts: `git pull origin <branch>` (or `git fetch origin && git merge origin/<branch>` for more control)

### Error Handling
```bash
# Check if git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not a git repository" >&2
    exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "Warning: Uncommitted changes detected" >&2
fi
```

## Pre-commit Checklist
- [ ] Shell scripts pass `bash -n` syntax check
- [ ] Tested with `--dry-run`
- [ ] No absolute paths in configs
- [ ] Colors and logging functions used consistently
- [ ] Error handling with `set -e` and guard clauses
- [ ] Documentation updated if workflow changed
- [ ] Git operations follow safety guidelines
