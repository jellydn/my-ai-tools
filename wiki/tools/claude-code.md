# Claude Code

Anthropic's AI coding assistant with extensive customization.

## Configuration Files

| File | Purpose |
|------|---------|
| `settings.json` | Main Claude Code settings |
| `mcp-servers.json` | MCP server configurations |
| `CLAUDE.md` | Agent guidelines |
| `commands/` | Custom slash commands |
| `agents/` | Custom agent definitions |
| `hooks/` | Hook implementations |
| `skills/` | Skill definitions |

## Key Features

- **MCP Servers**: context7, sequential-thinking, qmd, fff, mempalace
- **Custom Commands**: /ccs, /plannotator-review, /ultrathink
- **Custom Agents**: ai-slop-remover, code-reviewer, test-generator, documentation-writer, feature-team-coordinator
- **Hooks**: PostToolUse auto-format, PreToolUse git guard, auto-save to MemPalace
- **Plugins**: TypeScript LSP, Pyright LSP, context7, frontend-design, and more

## Auto-Format Support

The Claude Code configuration includes PostToolUse hooks for automatic formatting:

| Formatter | File Types |
|-----------|------------|
| biome | .ts, .tsx, .js, .jsx |
| gofmt | .go |
| prettier | .md, .mdx |
| ruff | .py |
| rustfmt | .rs |
| shfmt | .sh |
| stylua | .lua |

## Git Guard Hook

Prevents dangerous git commands:
- Force push (-f, --force)
- Hard reset (--hard)
- Clean with force (-fd)
- Force delete branch (-D)
- Interactive rebase
