# By the Numbers

Codebase statistics for my-ai-tools.

*Data collected on 2026-04-07*

## Size

| Metric | Count |
|--------|-------|
| Total files | ~200 |
| Config files (JSON/YAML/TOML) | ~80 |
| Markdown files | 87 |
| Shell scripts | 9 |
| Config directories | 13 |

## Configuration Breakdown

```mermaid
xychart-beta
    title "Files per Tool Directory"
    x-axis [Claude, OpenCode, Amp, CCS, Gemini, Codex, Kilo, Pi, Copilot, Cursor, Factory]
    y-axis [0, 20, 40, 60, 80, 100] --> [0, 100]
    bar [85, 45, 25, 30, 50, 25, 15, 20, 15, 15, 40]
```

### Per Tool Directory

| Directory | Primary Files | Subdirectories |
|-----------|---------------|----------------|
| claude/ | 4 | commands/, agents/, hooks/, skills/ |
| opencode/ | 3 | agent/, command/, skills/ |
| amp/ | 2 | skills/ |
| ccs/ | 2 | hooks/, cliproxy/ |
| gemini/ | 4 | agents/, commands/, hooks/, skills/ |
| codex/ | 3 | - |
| factory/ | 2 | hooks/, droids/ |
| skills/ | 12 skill directories | - |

## Activity

The repository has seen active development with regular feature additions:

- **Recent focus**: MemPalace AI memory integration across all tools
- **MCP server expansion**: context7, sequential-thinking, qmd, fff, mempalace
- **Tool support growth**: Added 6+ new AI tools in recent months

## Complexity

- **Shell scripts**: ~2,500 lines across main scripts
- **Common library**: ~770 lines in lib/common.sh
- **Configuration files**: JSON, YAML, and TOML formats

## Bot Activity

Recent commits include contributions from:
- factory-droid[bot] - AI-assisted development
- dependabot[bot] - Dependency updates

This indicates active AI-assisted development workflow in the repository.
