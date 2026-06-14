# 🤖 Gemini CLI Agent Guidelines

## AI Tool Guidelines

- Use the fff MCP tools for all file search operations instead of default tools.
- Use the sem MCP tools for semantic version control and git operations.

## General Practices

- Follow my software development practice @~/.ai-tools/best-practices.md
- Read @~/.ai-tools/MEMORY.md first — qmd (durable) vs agentmemory (session); follow the decision rule there
- Read @~/.ai-tools/agent-memory.md — auto-capture learnings, persist bug fixes, keep memories concise.
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
