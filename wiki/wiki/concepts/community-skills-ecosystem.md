---
title: "Community Skills Ecosystem"
type: concept
tags: [skills, community, marketplace, discovery]
created: 2026-07-10
---

# Community Skills Ecosystem

A growing ecosystem of community-maintained skill plugins installable via `npx skills add`. Skills are self-contained instruction sets (SKILL.md files) that teach AI agents how to perform specific tasks.

## Installation

```bash
npx skills find <query>           # Search for skills
npx skills add <owner/repo> --list # Preview a repo's skills
npx skills add <owner/repo> --skill <name> --yes  # Install a skill
```

## Key Repositories

| Repository | Skills | Focus Area |
|-----------|--------|-----------|
| `vercel-labs/agent-skills` | Multiple | Next.js, React, deployment |
| `factory-ai/factory-plugins` | `no-use-effect` | React useEffect replacements |
| `jezweb/claude-skills` | 97 skills | Production-ready Claude skills |
| `mattpocock/skills` | `grill-with-docs`, `improve-codebase-architecture` | Planning + architecture |
| `shadcn/improve` | `improve` | Plan-then-execute for cheap models |
| `expo/skills` | Multiple | React Native development |
| `blader/humanizer` | `humanizer` | Remove AI-generated writing style |
| `openclaw/agent-skills` | `autoreview` | Automated PR review |
| `GoogleChrome/modern-web-guidance` | `modern-web-guidance` | Web dev best practices |
| `openai/codex` | `babysit-pr` | Automated PR monitoring |
| `mvanhorn/last30days-skill` | `last30days` | Recent topic research |
| `av/facts` | `facts` suite | Track project specs with lifecycle |
| `github/gh-stack` | `gh-stack` | Stacked branches and PRs |
| `mitsuhiko/agent-stuff` | Multiple | Tmux, gh, browser, Sentry |
| `warpdotdev/oz-skills` | 14 skills | CI fix, PR creation, web testing |
| `Gentleman-Programming/engram` | `engram-memory` | Persistent agent memory |
| `privatenumber/mac-ocr` | `mac-ocr` | macOS OCR via Vision framework |

## Related Pages

- [[sources/readme]] — Primary documentation source
- [[my-ai-tools-repo]] — Local skill marketplace at `skills/`
