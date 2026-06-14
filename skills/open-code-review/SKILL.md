---
name: open-code-review
description: >
  Performs AI-powered code review on Git changes using the `ocr` CLI from
  alibaba/open-code-review. Use when the user asks to review code, review
  a pull request, review staged/unstaged changes, review a commit, or
  compare branches for code quality issues. Produces line-level review
  comments and can automatically apply fixes when requested.
license: Apache-2.0
compatibility: >
  Requires the `ocr` CLI installed (via `npm install -g
  @alibaba-group/open-code-review`). Requires a configured LLM
  (Anthropic or OpenAI-compatible) before first run.
metadata:
  author: alibaba
  homepage: https://github.com/alibaba/open-code-review
  version: "1.0.0"
---

# Open Code Review

A skill for invoking [open-code-review](https://github.com/alibaba/open-code-review) (`ocr`) — an open-source AI code review CLI that reads Git diffs and generates structured, line-level review comments.

## Prerequisites check

Before starting a review, verify the environment:

```bash
# 1. Check the CLI is installed
which ocr || echo "NOT INSTALLED"

# 2. Verify LLM connectivity
ocr llm test
```

If `ocr` is not installed, install it first:

```bash
npm install -g @alibaba-group/open-code-review
```

If `ocr llm test` fails, the user must configure an LLM. Guide them with one of these options:

**Option A — Environment variables (highest priority, recommended for CI):**

```bash
export OCR_LLM_URL=https://api.anthropic.com/v1/messages
export OCR_LLM_TOKEN=***
export OCR_LLM_MODEL=claude-opus-4-6
export OCR_USE_ANTHROPIC=true
```

**Option B — Persistent config:**

```bash
ocr config set llm.url https://api.anthropic.com/v1/messages
ocr config set llm.auth_token your-api-key-here
ocr config set llm.model claude-opus-4-6
ocr config set llm.use_anthropic true
```

Config is stored in `~/.opencodereview/config.json`.

## Usage

### Review workspace changes (staged + unstaged + untracked)

```bash
ocr review --audience agent
```

### Review a specific commit

```bash
ocr review --commit HEAD
```

### Review a branch range

```bash
ocr review --from main --to feature-branch
```

### Review with requirement context

```bash
ocr review --audience agent --background "Ensure all API endpoints validate input"
```

## Workflow

1. Run `ocr review --audience agent [args]` with a 5-minute timeout
2. Filter comments: High (bugs, security), Medium (style, perf), Low (nitpicks — discard)
3. Present remaining comments to the user
4. Autofix adopted suggestions when possible
