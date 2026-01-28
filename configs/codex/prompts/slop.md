# Remove AI Code Slop

Check the diff against $1 and remove all AI generated slop introduced in this branch.

## Usage

`/slop [branch-name]`

- If no branch is provided, compare against main: `/slop main`

## What is AI Code Slop?

This includes:
- Extra comments that a human wouldn't add or is inconsistent with the rest of the file
- Extra defensive checks or try/catch blocks that are abnormal for that area of the codebase
- Casts to `any` to get around type issues
- Any other style that is inconsistent with the file

## Process

### 1. Get the diff

```bash
# Compare against main branch
git diff main...HEAD --stat

# Or against specific branch
git diff $1 --stat
```

### 2. Review each changed file

For each changed file:
- Read the current content
- Compare with original (before changes)
- Identify AI-generated slop patterns

### 3. Remove slop

- Remove unnecessary comments
- Simplify overly defensive code
- Remove `any` casts where possible
- Restore natural code style

### 4. Verify

```bash
# Show remaining changes
git diff --stat

# Check tests still pass
npm test
```

## Common Slop Patterns

1. **Over-commenting**: Comments explaining obvious code
2. **Verbose error handling**: Try/catch blocks where not needed
3. **Unnecessary type casts**: `x as any` to bypass TypeScript
4. **Defensive programming**: Checks for already-validated inputs
5. **Redundant validation**: Duplicate null/undefined checks
