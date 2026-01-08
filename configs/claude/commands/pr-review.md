# Fix PR Review Comments

## Usage

```bash
/fix-review $ARGUMENTS
```

Systematically fix all unresolved code review comments from a GitHub pull request.

## Prerequisites

- GitHub CLI (`gh`) must be authenticated and configured
- Must be on the correct branch for the PR
- Node.js available for running the extraction script

## Process

### 1. Setup - Fetch and Extract Comments

```bash
# Validate extraction script exists
test -f ~/.claude/commands/extract-pr-comments.js || { echo "❌ Extract script not found"; exit 1; }

# Fetch both review comments (inline code comments) and issue comments (general PR discussion)
echo "📡 Fetching PR comments from GitHub API..."
gh api repos/:owner/:repo/pulls/$ARGUMENTS/comments --paginate > pr-$ARGUMENTS-review-comments-raw.json || { echo "❌ Failed to fetch review comments. Check network connection and GitHub CLI auth."; exit 1; }
gh api repos/:owner/:repo/issues/$ARGUMENTS/comments --paginate > pr-$ARGUMENTS-issue-comments-raw.json || { echo "❌ Failed to fetch issue comments. Check network connection and GitHub CLI auth."; exit 1; }

# Validate API calls succeeded and files have content
test -s pr-$ARGUMENTS-review-comments-raw.json && echo "✅ Review comments: $(jq length pr-$ARGUMENTS-review-comments-raw.json 2>/dev/null || echo 'unknown') found" || echo "⚠️ No review comments found"
test -s pr-$ARGUMENTS-issue-comments-raw.json && echo "✅ Issue comments: $(jq length pr-$ARGUMENTS-issue-comments-raw.json 2>/dev/null || echo 'unknown') found" || echo "⚠️ No issue comments found"

# Merge both comment types and extract unresolved comments
echo "🔄 Processing comments and creating todo list..."
node .claude/extract-pr-comments.js pr-$ARGUMENTS-review-comments-raw.json pr-$ARGUMENTS-issue-comments-raw.json pr-$ARGUMENTS-comments.ndjson || { echo "❌ Comment extraction failed. Check that Node.js is available."; exit 1; }
```

**Output files:**

- `pr-$ARGUMENTS-review-comments-raw.json` - Raw inline review comments from GitHub
- `pr-$ARGUMENTS-issue-comments-raw.json` - Raw PR discussion comments from GitHub
- `pr-$ARGUMENTS-comments.ndjson` - Structured comment data with severity/category classification
- `pr-$ARGUMENTS-comments-todo.md` - Prioritized checklist sorted by severity (🔴 Critical → 🟠 High → 🟡 Medium → 🟢 Low)
- `pr-$ARGUMENTS-comments-summary.md` - Analysis breakdown by severity and category

### 2. Verify Environment

```bash
# Confirm you're on the correct branch
git status
git branch --show-current

# Check if files were created successfully
ls -la pr-$ARGUMENTS-*comments*

# Verify comment extraction completed
test -f pr-$ARGUMENTS-comments.ndjson && echo "✅ Comment data ready" || { echo "❌ Comment extraction failed"; exit 1; }
test -f pr-$ARGUMENTS-comments-todo.md && echo "✅ Todo list created" || { echo "❌ Todo list creation failed"; exit 1; }
```

**⚠️ Security Note:** Comment files may contain sensitive information. Clean up temporary files after use.

### 3. Review Comments Overview

```bash
# Quick analysis overview
cat pr-$ARGUMENTS-comments-summary.md

# Prioritized todo list (sorted by severity)
cat pr-$ARGUMENTS-comments-todo.md
```

The summary file shows impact analysis and category breakdown. Todo items are automatically sorted by severity: 🔴 Critical → 🟠 High → 🟡 Medium → 🟢 Low

### 4. Systematic Comment Resolution

**For each todo item:**

a) **Find comment details:**

```bash
grep "\"id\":COMMENT_ID" pr-$ARGUMENTS-comments.ndjson
# Replace COMMENT_ID with the actual ID from the todo list
```

b) **Locate and understand the issue:**

- Read the affected file and surrounding context
- Review the diff_hunk to understand the specific concern
- Consider the reviewer's intent and best practices

c) **Apply fixes:**

- Use Edit/MultiEdit for safe, targeted changes
- Maintain existing code style and conventions
- Make minimal, focused changes that address the specific feedback

d) **Track progress:**

- Mark completed items with `[x]` in the todo file
- Continue systematically through ALL items

### 5. Validation

**Required checks before completion:**

```bash
# Run type checking (use project-specific command)
npm run typecheck

# Run linting (use project-specific command)
npm run lint

# Optionally run tests if changes affect functionality
npm run test
```

## Guidelines

### What to Fix

- **Code quality issues:** Type errors, linting violations, unused variables
- **Best practices:** Const vs let, proper error handling, naming conventions
- **Documentation:** Missing JSDoc, unclear variable names
- **Performance:** Obvious inefficiencies, unnecessary re-renders
- **Security:** Potential vulnerabilities, exposed secrets
- **Maintainability:** Complex logic that needs simplification
- **Accessibility:** Missing ARIA labels, keyboard navigation issues

### What to Skip

- **Major architectural changes** that require broader discussion
- **Subjective style preferences** when existing code is consistent
- **Complex design decisions** that need product/UX input
- **Breaking changes** that affect public APIs

### Best Practices

- Work through ALL todos systematically - don't stop at 5-10 comments
- Update the todo file in real-time: `[ ]` → `[x]`
- Preserve existing code style and patterns
- Make minimal, focused changes that directly address feedback
- Test changes when possible

## Error Handling

**If comment extraction fails:**

```bash
# Check if PR number exists
gh pr view $ARGUMENTS || { echo "PR #$ARGUMENTS not found"; exit 1; }

# Verify API access and rate limits
gh auth status
gh api rate_limit | jq '.rate.remaining' | head -1 || echo "Rate limit check failed"

# Re-run with different output location
node .claude/extract-pr-comments.js pr-$ARGUMENTS-review-comments-raw.json pr-$ARGUMENTS-issue-comments-raw.json ./pr-$ARGUMENTS-comments.ndjson
```

**Performance Considerations:**

- Large PRs may hit GitHub API rate limits (5000 requests/hour)
- Comment processing time scales with PR size - expect 1-2 minutes for PRs with 50+ comments
- Use `--paginate` flag for comprehensive comment retrieval

**If validation fails:**

- Fix any new type/lint errors introduced by changes
- Consider if the original code had pre-existing issues
- Document any intentional deviations from linting rules

## Expected Output

Provide a summary in this format:

```markdown
📋 PR #$ARGUMENTS Review Comments Summary

🎯 **Impact Analysis:**
• Critical: 🔴 2 issues (Security, Breaking changes)  
• High: 🟠 5 issues (Bugs, Type errors)
• Medium: 🟡 8 issues (Performance, Refactoring)  
• Low: 🟢 3 issues (Style, Documentation)

✅ **Fixed by Category (18 total):**

🔒 **Security & Critical (2):**
• "Fix SQL injection risk" → src/api/auth.ts:45
• "Remove hardcoded API key" → src/config/prod.ts:12

🐛 **Bugs & Errors (5):**  
• "Handle null reference" → src/utils/parser.ts:67
• "Fix async race condition" → src/hooks/useData.ts:23
• "Add error boundary" → src/components/App.tsx:89

⚡ **Performance (3):**
• "Memoize expensive calculation" → src/components/Table.tsx:89
• "Add lazy loading" → src/pages/Dashboard.tsx:156
• "Optimize bundle size" → webpack.config.js:34

🎨 **Code Quality (6):**
• "Use const instead of let" → src/utils/format.ts:34
• "Add TypeScript types" → src/models/User.ts:12
• "Remove unused imports" → src/hooks/useAuth.ts:5

📚 **Documentation (2):**
• "Add JSDoc comments" → src/api/client.ts:78
• "Update README examples" → README.md:45

⏭️ **Skipped (4 comments):**

🏗️ **Architectural (2):** Require team discussion
• "Redesign data flow" → src/store/index.ts:12
• "Consider GraphQL migration" → src/api/rest.ts:45

💡 **Subjective (2):** Style preferences  
• "Alternative UI layout" → src/components/Modal.tsx:34
• "Different naming convention" → src/utils/helpers.ts:23

📊 **Validation Results:**
• TypeScript: ✅ 0 errors (18 issues resolved)
• ESLint: ✅ 0 warnings (12 rules passed)
• Tests: ✅ 94% coverage (+3% from fixes)
• Build: ✅ All packages compiled successfully

📈 **Metrics:**
• Files Changed: 15
• Lines Added: +127, Removed: -89
• Time Invested: ~45 minutes  
• Review Completion: 82% (18/22 comments addressed)

🎯 **Next Steps:**
• Commit categorized fixes with detailed messages
• Schedule architectural discussion for skipped items
• Update PR description with summary
• Reply to resolved comments on GitHub

🧹 **IMPORTANT - Cleanup Required:**
• Clean up temporary files: `rm pr-$ARGUMENTS-*comments*.json pr-$ARGUMENTS-*.ndjson pr-$ARGUMENTS-*todo.md pr-$ARGUMENTS-*summary.md`
• These files contain PR data and should not be committed to version control
```
