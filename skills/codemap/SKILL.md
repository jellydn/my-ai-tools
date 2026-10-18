---
name: codemap
description: "Create a seven-document architecture map when the user asks to map a codebase."
license: MIT
compatibility: cline, opencode, claude, amp, codex, gemini, cursor, pi
hint: Use when mapping codebase structure, documenting architecture, or onboarding to a project
user-invocable: true
metadata:
  audience: all
  workflow: codebase-mapping
  source: glittercowboy/get-shit-done@bdcaab2c752d9a33a1a1ca9acf3a3c81fb991815
  source_path: get-shit-done/workflows/map-codebase.md
---

# Codemap

## What I do

Analyze your entire codebase and create 7 comprehensive documentation files in `.planning/codebase/`:

- **STACK.md** - Technologies, dependencies, configuration
- **INTEGRATIONS.md** - 3rd party providers, APIs, databases, auth providers
- **ARCHITECTURE.md** - System patterns, layers, data flow
- **STRUCTURE.md** - Directory layout, key locations, naming conventions
- **CONVENTIONS.md** - Code style, patterns, error handling
- **TESTING.md** - Framework, structure, mocking, coverage
- **CONCERNS.md** - Tech debt, bugs, security, performance issues

## When to use me

Use this skill when you need to:

- **Onboard** new developers to understand the codebase quickly
- **Plan** new features with full context of existing patterns
- **Understand** code conventions before making changes
- **Identify** technical debt and areas of concern
- **Document** the current state of the project

## How it works

This skill runs four focus passes. Use parallel file-reading and file-writing workers when the runtime provides them. If suitable workers are unavailable, perform the same passes sequentially in the current context:

1. **Tech** → Analyzes stack and integrations → STACK.md, INTEGRATIONS.md
2. **Architecture** → Analyzes patterns and structure → ARCHITECTURE.md, STRUCTURE.md
3. **Quality** → Analyzes conventions and testing → CONVENTIONS.md, TESTING.md
4. **Concerns** → Identifies tech debt and issues → CONCERNS.md

Each pass:

- Explores the codebase for its focus
- Uses templates from `$SKILL_PATH/templates/`
- Writes documents directly to `.planning/codebase/`
- Returns only confirmation (not document contents)

The orchestrator:

- Creates `.planning/codebase/` directory
- Runs the four passes in parallel only when suitable workers are available
- Otherwise runs those passes sequentially in the current context
- Collects confirmations
- Verifies all documents created
- Commits the codebase map (if configured)

## Process

### Scope and Runtime

Accept an optional `--paths <p1,p2,...>` for an incremental map. Validate repository-relative prefixes before use: reject absolute paths, `..` components, and shell metacharacters (`;`, backticks, `$`, `&`, `|`, `<`, `>`). If no supplied path is valid, stop and ask for a corrected scope; do not silently expand to the whole repository. Pass the same normalized scope to every mapper and every sequential pass. Do not interpolate unchecked input into shell commands.

Use the actual current date for all analysis-date placeholders. For scoped refreshes, retain documented information outside the scope and state which prefixes were rechecked.

Use parallel agents only when the runtime supports file-reading and file-writing workers. Do not assume an `explore` agent can write files or use a browser agent as a code mapper. If suitable workers are unavailable, perform the four focus passes sequentially in the current context, using the same scope and templates. Do not require GSD-specific SDK commands or agent types.

### Step 1: Check Existing Map

If `.planning/codebase/` already exists, prompt:

```
.planning/codebase/ already exists. What's next?
1. Refresh - Delete existing and remap codebase
2. Update - Keep existing, only update specific documents
3. Skip - Use existing codebase map as-is
```

### Step 2: Create Structure

Create the output directory:

```bash
mkdir -p .planning/codebase
```

### Step 3: Run the Four Focus Passes

Run the passes in parallel only when the runtime supports file-reading and file-writing workers. Otherwise perform them sequentially in the current context. Parallel workers are optional, not required. Each pass must receive the validated scope, current date, and the appropriate template paths from `$SKILL_PATH/templates/`. The examples below describe assignments, not mandatory API parameter names. While a parallel worker is active, do not duplicate its exploration or write its documents.

**Tech Agent:**

```
agent_type: explore
description: Map codebase tech stack
prompt: |
	Focus: tech

	Analyze this codebase for technology stack and external integrations.

	Write these documents to .planning/codebase/:
	- STACK.md - Languages, runtime, frameworks, dependencies, configuration
	- INTEGRATIONS.md - External APIs, databases, auth providers, webhooks

	Use the templates from map-codebase skill. Explore thoroughly.
	Write documents directly. Return confirmation only.
```

**Architecture Agent:**

```
agent_type: explore
description: Map codebase architecture
prompt: |
	Focus: arch

	Analyze this codebase architecture and directory structure.

	Write these documents to .planning/codebase/:
	- ARCHITECTURE.md - Pattern, layers, data flow, abstractions, entry points
	- STRUCTURE.md - Directory layout, key locations, naming conventions

	Use the templates from map-codebase skill. Explore thoroughly.
	Write documents directly. Return confirmation only.
```

**Quality Agent:**

```
agent_type: explore
description: Map codebase conventions
prompt: |
	Focus: quality

	Analyze this codebase for coding conventions and testing patterns.

	Write these documents to .planning/codebase/:
	- CONVENTIONS.md - Code style, naming, patterns, error handling
	- TESTING.md - Framework, structure, mocking, coverage

	Use the templates from map-codebase skill. Explore thoroughly.
	Write documents directly. Return confirmation only.
```

**Concerns Agent:**

```
agent_type: explore
description: Map codebase concerns
prompt: |
	Focus: concerns

	Analyze this codebase for technical debt, known issues, and areas of concern.

	Write this document to .planning/codebase/:
	- CONCERNS.md - Tech debt, bugs, security, performance, fragile areas

	Use the templates from map-codebase skill. Explore thoroughly.
	Write document directly. Return confirmation only.
```

### Step 4: Verify Output

Wait for every mapper to finish. Check that all seven expected documents exist and each has more than 20 lines; a filename alone is not success. Report missing, short, or failed outputs and repair them before declaring completion. Check that dates are current and scoped output retains unaffected information.

```bash
ls -la .planning/codebase/
wc -l .planning/codebase/*.md
```

### Step 5: Secret Check and Optional Commit

Before showing or committing documents, scan for accidentally copied credentials. List configuration paths and environment-variable names, not secret values. Do not read `.env` contents or credential files for the map. Use the repository's secret scanner when available. A minimal supplementary check is:

```bash
rg -l '(sk-[A-Za-z0-9]{20,}|gh[pousr]_[A-Za-z0-9]{36,}|AKIA[A-Z0-9]{16}|xox[baprs]-[A-Za-z0-9-]+|-----BEGIN.*PRIVATE KEY)' .planning/codebase/*.md
```

This prints filenames only, not matching secret values. A no-match exit status is normal; a scanner error is not a clean scan. If a match is found, stop, redact the content, and recheck before proceeding. Pattern matching is not proof that all secrets are absent; also review excerpts copied from logs and configuration.

If the checks pass, `.planning/` is not gitignored, and the user wants to commit:

```bash
git add .planning/codebase/*.md
git commit -m "docs: map existing codebase

- STACK.md - Technologies and dependencies
- ARCHITECTURE.md - System design and patterns
- STRUCTURE.md - Directory layout
- CONVENTIONS.md - Code style and patterns
- TESTING.md - Test structure
- INTEGRATIONS.md - External services
- CONCERNS.md - Technical debt and issues"
```

### Step 6: Summary

Present completion summary:

```
Codebase mapping complete.

Created .planning/codebase/:
- STACK.md ([N] lines) - Technologies and dependencies
- ARCHITECTURE.md ([N] lines) - System design and patterns
- STRUCTURE.md ([N] lines) - Directory layout and organization
- CONVENTIONS.md ([N] lines) - Code style and patterns
- TESTING.md ([N] lines) - Test structure and practices
- INTEGRATIONS.md ([N] lines) - External services and APIs
- CONCERNS.md ([N] lines) - Technical debt and issues

Next steps:
- Review documents: cat .planning/codebase/STACK.md
- Use these as reference when planning features
- Update as codebase evolves
```

## Templates

Templates are located in `$SKILL_PATH/templates/`:

- `STACK.md.template` - Technology stack
- `INTEGRATIONS.md.template` - External integrations
- `ARCHITECTURE.md.template` - System architecture
- `STRUCTURE.md.template` - Directory structure
- `CONVENTIONS.md.template` - Coding conventions
- `TESTING.md.template` - Testing patterns
- `CONCERNS.md.template` - Technical concerns

Each agent reads the appropriate template and fills it in based on codebase exploration.

## Agent Guidelines

When spawned as a mapper agent:

### Exploration Commands

**Helper: Use fd if available, fall back to find**

```bash
# Define finder helper (fd if available, otherwise find)
_finder() { command -v fd >/dev/null 2>&1 && fd "$@" || find "$@"; }
_rg() { command -v rg >/dev/null 2>&1 && rg "$@" || grep -r "$@"; }
```

**Tech Focus:**

```bash
# Package manifests
cat package.json pyproject.toml Cargo.toml go.mod 2>/dev/null

# Config files
ls -la *.config.* tsconfig.json 2>/dev/null

# Find SDK/API imports
_rg "import.*stripe|import.*supabase|import.*aws" src/ 2>/dev/null | head -50
```

**Architecture Focus:**

```bash
# Directory structure (fd is faster and ignores node_modules/.git by default)
_finder -t d . | head -50

# Entry points
_finder -t f "index.*" "main.*" "app.*" src/ app/ 2>/dev/null | head -20

# Import patterns
_rg "^import" src/ 2>/dev/null | head -100
```

**Quality Focus:**

```bash
# Linting/formatting config
cat .eslintrc* .prettierrc* biome.json 2>/dev/null

# Test files
_finder -t f "\.test\." "\.spec\." 2>/dev/null | head -30
```

**Concerns Focus:**

```bash
# TODO/FIXME comments
_rg "TODO|FIXME|HACK|XXX" src/ 2>/dev/null | head -50

# Large files (potential complexity)
_finder -t f "\.ts$" -e "\.tsx$" src/ 2>/dev/null | xargs wc -l 2>/dev/null | sort -rn | head -20
```

### Critical Rules

1. **Write documents directly** - Use the Write tool, don't return contents
2. **Always include file paths** - Every finding needs a file path in backticks
3. **Use the templates** - Fill in the template structure exactly
4. **Be thorough** - Read actual files, don't guess
5. **Return only confirmation** - Response should be ~10 lines with file paths and line counts
6. **Skip commits** — orchestrator handles git operations

## Inspiration

This skill is inspired by and adapted from [glittercowboy/get-shit-done](https://github.com/glittercowboy/get-shit-done), specifically their [map-codebase workflow](https://github.com/glittercowboy/get-shit-done/blob/main/get-shit-done/workflows/map-codebase.md) and [gsd-codebase-mapper agent](https://github.com/glittercowboy/get-shit-done/blob/main/agents/gsd-codebase-mapper.md).
