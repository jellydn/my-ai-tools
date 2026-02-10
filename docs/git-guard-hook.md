# 🛡️ Git Guard Hook

The Git Guard Hook is a safety feature for Claude Code that prevents the execution of dangerous git commands that could result in data loss or repository corruption.

## 📋 Overview

This hook runs as a **PreToolUse** hook for the Bash tool in Claude Code. It intercepts all bash commands before execution and validates git commands to ensure they are safe.

Based on: [This Hook Stops Claude Code Running Dangerous Git Commands](https://www.aihero.dev/this-hook-stops-claude-code-running-dangerous-git-commands)

## 🚫 Blocked Commands

The following dangerous git operations are blocked:

### Force Operations

- `git push --force` / `git push -f` - Force push without lease protection
- `git checkout --force` / `git checkout -f` - Force checkout that discards local changes

### Destructive Operations

- `git reset --hard` - Hard reset that destroys uncommitted changes
- `git clean -f` / `git clean -fd` - Removes untracked files and directories
- `git branch -D` - Force delete branch without merge checks

### History Rewriting

- `git rebase -i` - Interactive rebase that can rewrite commit history
- `git filter-branch` - Rewrites entire branch history
- `git replace` - Creates replacement objects

### Data Removal

- `git stash drop` - Permanently removes a stash entry
- `git stash clear` - Removes all stash entries
- `git reflog expire` - Removes reflog entries (recovery points)
- `git gc --prune=now` - Aggressive garbage collection
- `git update-ref -d` - Deletes references

## ✅ Allowed Commands

All safe git operations are permitted, including:

- `git status` - Check repository status
- `git log` - View commit history
- `git diff` - View changes
- `git add` - Stage changes
- `git commit` - Create commits
- `git push` - Normal push (without force)
- `git pull` - Pull changes
- `git fetch` - Fetch remote changes
- `git checkout` - Switch branches (without force)
- `git merge` - Merge branches
- `git rebase` - Non-interactive rebase
- `git stash` - Create stash (without drop/clear)
- `git tag` - Manage tags
- `git remote` - Manage remotes
- `git config` - Configure git
- `git clone` - Clone repositories
- `git init` - Initialize repositories

## 🔧 Installation

The hook is automatically installed when you run:

```bash
./cli.sh
```

This copies the hook script to `~/.claude/hooks/git-guard.cjs` and configures it in Claude Code's settings.

## 📝 Configuration

The hook is configured in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "node \"~/.claude/hooks/git-guard.cjs\"",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

## 🧪 Testing

You can test the hook manually:

```bash
# Test with a safe command
echo '{"command": "git status"}' | node ~/.claude/hooks/git-guard.cjs
# Exit code: 0 (allowed)

# Test with a dangerous command
echo '{"command": "git push --force"}' | node ~/.claude/hooks/git-guard.cjs
# Exit code: 1 (blocked)
```

## 🎯 How It Works

1. **Interception**: The hook runs before any Bash command is executed
2. **Analysis**: It parses the command to check if it's a git operation
3. **Validation**: Git commands are checked against dangerous patterns
4. **Action**:
   - Safe commands: Exit with code 0 (allow execution)
   - Dangerous commands: Exit with code 1 (block execution) and display error message
   - Non-git commands: Exit with code 0 (allow execution)

## 🔒 Security Benefits

- **Prevents accidental data loss**: Blocks commands that could permanently delete work
- **Protects repository integrity**: Prevents history rewriting that could break collaboration
- **Encourages safe practices**: Users must manually run dangerous commands in terminal
- **Fail-safe design**: If the hook errors, it allows the command (fail-open)

## 🚨 When You Need Blocked Commands

If you legitimately need to run a blocked command:

1. Open your terminal
2. Run the command manually
3. Review the implications carefully before confirming

Example:

```bash
# If you need to force push (use with caution!)
git push --force-with-lease origin main
```

Note: `git push --force-with-lease` is safer than `--force` as it ensures you don't overwrite others' work.

## 🛠️ Customization

To modify which commands are blocked, edit `configs/claude/hooks/git-guard.cjs`:

```javascript
const DANGEROUS_PATTERNS = [
  { pattern: /git\s+push\s+.*--force/i, reason: "force push" },
  // Add or remove patterns as needed
];
```

After modifying, reinstall:

```bash
./cli.sh --no-backup
```

## 📚 Related Files

- `configs/claude/hooks/git-guard.cjs` - Hook implementation
- `configs/claude/settings.json` - Hook configuration
- `cli.sh` - Installation script

## 🤝 Contributing

If you find a dangerous git command that should be blocked or a safe command that's incorrectly blocked, please:

1. Open an issue describing the command and scenario
2. Submit a PR with the pattern update
3. Include test cases demonstrating the behavior

## 📖 References

- [AI Hero: This Hook Stops Claude Code Running Dangerous Git Commands](https://www.aihero.dev/this-hook-stops-claude-code-running-dangerous-git-commands)
- [Claude Code Hooks Documentation](https://docs.claude.ai)
- [Git Documentation](https://git-scm.com/doc)
